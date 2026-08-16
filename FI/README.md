# 📒 FI · 财务取数（Finance Data Extraction）

> 从 SAP ECC6 抽取财务总账与子分类账数据，支撑**序时账 vs 课余表（余额表）核对**。

**配置**：`xml File/Extraction_Tool_MN_2023_1-8_dryRun_20230912/FI_SAP_ECC6.xml`
**配套操作手册**：[SAP_ABAP_Program_操作手册简易版.pdf](../User%20Manual/SAP_ABAP_Program_操作手册简易版.pdf)

---

## 📚 参考数据源（SAP 标准表）

下表为 FI 模块抽取所依赖的 SAP 标准底表，附参考链接，便于审计人员核对字段口径。

| SAP 标准表 | 标准语义 | 参考 |
|---|---|---|
| `BKPF` | 会计凭证抬头（Accounting Document Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BKPF.html) |
| `BSEG` | 会计凭证行项目（Accounting Document Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSEG.html) |
| `BSEG_ADD` | 凭证附加数据（Subledger / CO 附加） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSEG_ADD.html) |
| `FAGLFLEXT` | 新总账余额（GL Totals，按科目/公司/年度/期间） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/FAGLFLEXT.html) |
| `GLT0` | 旧总账余额（GL Totals，旧总账） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/GLT0.html) |
| `BSIS` | 总账未清项（G/L Open Items） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSIS.html) |
| `BSAS` | 总账已清项（G/L Cleared Items） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSAS.html) |
| `BSID` | 应收未清项（AR Open Items） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSID.html) |
| `BSAD` | 应收已清项（AR Cleared Items） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSAD.html) |
| `BSIK` | 应付未清项（AP Open Items） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSIK.html) |
| `BSAK` | 应付已清项（AP Cleared Items） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/BSAK.html) |
| `SKA1` | 科目表（Chart of Accounts） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/SKA1.html) |
| `SKAT` | 科目文本（GL Account Text） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/SKAT.html) |
| `SKB1` | 科目公司代码级属性（Company Code Data） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/SKB1.html) |
| `FEBKO` | 电子银行对账单抬头（Bank Statement Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/FEBKO.html) |
| `FEBEP` | 电子银行对账单行项目（Bank Statement Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/FEBEP.html) |

---

## 🔧 抽取字段与角色

| SAP 标准表 | 类别 | 本工具抽取关键字段 | 角色 |
|---|---|---|---|
| `BKPF` / `BSEG` / `BSEG_ADD` | 序时账（凭证抬头 / 行项目） | `BELNR` `BUKRS` `BUDAT` `HKONT/SAKNR` `SHKZG` `DMBTR` `WRBTR` `MENGE/MEINS` `EBELN/EBELP` `KOART` `BSCHL` | 凭证明细（科目 / 金额 / 借贷 / 数量 / 采购参考） |
| `FAGLFLEXT` / `GLT0` | 课余表（余额） | `RACCT` `RBUKRS` `RYEAR` `RLDNR` `HSL01–HSL16` `RBUSA` `PRCTR` `SEGMENT` `DRCRK` | 按科目 / 公司 / 年度的期间余额（新总账 / 旧总账） |
| `BSIS` / `BSAS` | 总账次要索引 | 未清 / 已清项（含 `HKONT` `DMBTR` `SHKZG`） | 总账勾稽中间层 |
| `BSID` / `BSAD` | 应收（AR）次要索引 | 未清 / 已清项 | 应收子分类账 |
| `BSIK` / `BSAK` | 应付（AP）次要索引 | 未清 / 已清项 | 应付子分类账 |
| `SKA1` / `SKAT` / `SKB1` | 科目主数据 | 科目表 / 文本 / 公司代码级属性 | 校验 `HKONT` 合法性 |
| `FEBKO` / `FEBEP` | 电子银行对账单 | 抬头 / 行项目 | 银行对账（可顺带支撑银行函证 / 未达账） |

---

## 🎯 审计场景支撑：序时账 vs 课余表核对

- **序时账**：`BKPF` + `BSEG`（凭证明细）。
- **课余表 / 余额表**：`FAGLFLEXT` / `GLT0`（期间余额），辅以 `BSIS/BSAS`、`BSID/BSAD`、`BSIK/BSAK` 次要索引与 `SKA1/SKAT/SKB1` 主数据。

**核对方法**：以 `(HKONT/SAKNR, BUKRS, GJAHR, MONAT)` 对 `BSEG` 按 `SHKZG` 计净额，应等于 `FAGLFLEXT` / `GLT0` 对应 `(RACCT, RBUKRS, RYEAR, HSLxx)` 期间额；`BSIS/BSAS` 提供总账未清 / 已清项独立复算口径。每表均带 `HashtotalField`（如 `BKPF=TXKRS`、`FAGLFLEXT/GLT0=HSL16`、`BSEG=DMBTR`），落地后先核对哈希总计再分析。

---

## ✅ 覆盖度与缺口

- **覆盖**：序时账（BKPF+BSEG）+ 课余表（FAGLFLEXT/GLT0）+ 次要索引 + 主数据，哈希完整性校验内建。
- **缺口**：`CO Tables` 分组在 KAAP 配置中为 `Extract` 关闭，不抽取；若需将 CO 过账并入总账核对须另补抽。标准 FI 总账核对不受影响。

> ⚠️ 本工具仅做**抽取与落地**，不做匹配计算；勾稽与差异判定在下游 Python 工具（`sap-fi-2026h1`）。字段分隔符统一 `#|#`，与下游读取约定一致。

---

## 🔗 相关仓库

- [sap-abap-data-extraction 主仓库](../README.md) — 配置集与总览
- [sap-fi-2026h1](https://github.com/Gvmeakiss/sap-fi-2026h1) — 2026 H1 FI 凭证/余额处理与勾稽
