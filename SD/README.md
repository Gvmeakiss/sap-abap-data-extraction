# 🚚 SD · 销售取数（Sales Data Extraction）

> 从 SAP ECC6 抽取销售与分销数据，支撑**销售三单匹配**（订单 / 发货 / 开票）。

**配置**：`xml File/Extraction_Tool_MN_2023_1-8_dryRun_20230912/SD_SAP_ECC6.xml`
**配套操作手册**：[SAP_ABAP_Program_操作手册简易版.pdf](../User%20Manual/SAP_ABAP_Program_操作手册简易版.pdf)

---

## 📚 参考数据源（SAP 标准表）

下表为 SD 模块抽取所依赖的 SAP 标准底表，附参考链接，便于审计人员核对字段口径。

| SAP 标准表 | 标准语义 | 参考 |
|---|---|---|
| `VBAK` | 销售订单抬头（Sales Document Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/VBAK.html) |
| `VBAP` | 销售订单行项目（Sales Document Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/VBAP.html) |
| `LIKP` | 交货单抬头（Delivery Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/LIKP.html) |
| `LIPS` | 交货单行项目（Delivery Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/LIPS.html) |
| `VBRK` | 出具发票抬头（Billing Document Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/VBRK.html) |
| `VBRP` | 出具发票行项目（Billing Document Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/VBRP.html) |
| `VBFA` | 凭证流（Document Flow） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/VBFA.html) |
| `KONV` | 凭证条件（Conditions / Pricing） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/KONV.html) |

---

## 🔧 抽取字段与三单角色

| SAP 标准表 | 本工具抽取关键字段 | 在三单匹配中的角色 |
|---|---|---|
| `VBAK` | `VKORG` `KUNAG` `AUDAT` | 订单抬头 |
| `VBAP` | `MATNR` `KWMENG/VRKME` `NETWR` `WERKS` `VGBEL/VGPOS` | 订单行（数量 / 净额 / 参考交货） |
| `LIKP` | `LFDAT` `WERKS` | 发货抬头 |
| `LIPS` | `LFIMG` `VRKME` `BWART` `VGBEL/VGPOS` | 发货行（参考订单 / 开票） |
| `VBRK` | `FKDAT` `BUKRS` `VKORG` `KUNAG` `NETWR` `FKSTO` | 开票抬头（冲销 `FKSTO`） |
| `VBRP` | `FKIMG` `NETWR` `AUBEL/AUPOS` `VGBEL/VGPOS` `MATNR` | 开票行（**参考订单 / 参考交货**直连三元） |
| `VBFA` | `VBELV/POSNV` `VBELN/POSNN` `VBTYP_N/V` `RFMNG` `RFWRT` | **单据流向枢纽**：串联 订单 → 发货 → 开票 |

---

## 🎯 审计场景支撑：销售三单匹配

本模块覆盖销售三单的完整数据链：

- **订单**：`VBAK` + `VBAP`
- **发货**：`LIKP` + `LIPS`
- **开票**：`VBRK` + `VBRP`

`VBRP.AUBEL/AUPOS`（参考订单）与 `VBRP.VGBEL/VGPOS`（参考交货）可直接锁定「订单行—发货行—开票行」三元关系；`VBFA` 另提供跨单据的完整流向，对应 `sap-sd-three-match` 的 `AUBEL/AUPOS` 键。

---

## ✅ 覆盖度与缺口

- **覆盖**：销售三单（订单 / 发货 / 开票）齐备，且提供直接串联键（`AUBEL/AUPOS`、`VGBEL/VGPOS`）与完整凭证流（`VBFA`）。
- **缺口**：价格条件 `KONV` / `KONP` 分组在 KAAP 配置中为 `Extract` 关闭，不抽取；净额 / 数量比对不受影响，仅"按价格条件拆解差异"的细度受限。

> ⚠️ 本工具仅做**抽取与落地**，不做匹配计算；差异判断、匹配率、Not Test 分类在下游 Python 工具（`sap-sd-three-match`、`sales-three-match-*`）。字段分隔符统一 `#|#`，与下游读取约定一致。

---

## 🔗 相关仓库

- [sap-abap-data-extraction 主仓库](../README.md) — 配置集与总览
- [sap-sd-three-match](https://github.com/Gvmeakiss/sap-sd-three-match) — SD 销售三单匹配与差异分析
- [sales-three-match-configurable](https://github.com/Gvmeakiss/sales-three-match-configurable) — 可配置通用匹配工具包
