# 📦 MM · 采购取数（Purchase Data Extraction）

> 从 SAP ECC6 抽取采购相关数据，支撑**采购三单匹配**（订单 / 收货 / 发票）。

**配置**：`xml File/Extraction_Tool_MN_2023_1-8_dryRun_20230912/MM_SAP_ECC6.xml`
**配套操作手册**：[SAP_ABAP_Program_操作手册简易版.pdf](../User%20Manual/SAP_ABAP_Program_操作手册简易版.pdf)

---

## 📚 参考数据源（SAP 标准表）

下表为 MM 模块抽取所依赖的 SAP 标准底表，附官方/社区参考链接，便于审计人员核对字段口径。

| SAP 标准表 | 标准语义 | 参考 |
|---|---|---|
| `EKKO` | 采购订单抬头（Purchasing Document Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/EKKO.html) |
| `EKPO` | 采购订单行项目（Purchasing Document Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/EKPO.html) |
| `EKET` | 计划协议计划行（Scheduling Agreement Schedule Line） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/EKET.html) |
| `EKBE` | 采购凭证历史（PO History） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/EKBE.html) |
| `EKBZ` | 采购交货成本（Delivery Costs） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/EKBZ.html) |
| `MKPF` | 物料凭证抬头（Material Document Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/MKPF.html) |
| `MSEG` | 物料凭证行项目（Material Document Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/MSEG.html) |
| `RBKP` | 发票凭证抬头（Invoice Document Header） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/RBKP.html) |
| `RSEG` | 发票凭证行项目（Invoice Document Item） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/RSEG.html) |
| `RBMA` | 发票预扣税（Invoice Tax） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/RBMA.html) |
| `RBCO` | 发票科目分配（Invoice Account Assignment） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/RBCO.html) |
| `EBAN` | 采购申请（Purchase Requisition） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/EBAN.html) |
| `ESLL` | 服务行（Service Line） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/ESLL.html) |
| `ESSR` | 服务录入（Service Entry Sheet） | [sapdatasheet](https://www.sapdatasheet.org/abap/tabl/ESSR.html) |

---

## 🔧 抽取字段与三单角色

| SAP 标准表 | 本工具抽取关键字段 | 在三单匹配中的角色 |
|---|---|---|
| `EKKO` | `BUKRS` `LIFNR` `AEDAT` `BSART` | 订单抬头 |
| `EKPO` | `MATNR` `MENGE` `MEINS` `NETWR` `LOEKZ` `WEBRE` | 订单行（数量 / 净额 / 删除标记） |
| `EKET` | 交货计划 | 交货排程 |
| `EKBE` | `VGABE` `BEWTP` `MENGE` `DMBTR` `WRBTR` `SHKZG` `EBELN/EBELP` | **三单枢纽**：按业务类型串接收货与发票 |
| `EKBZ` | 运费 / 关税等 | 影响发票净额比较（扣减交货成本口径） |
| `MKPF` | `BUDAT` | 收货抬头 |
| `MSEG` | `MENGE` `MEINS` `BWART` `KZBEW=B` `EBELN/EBELP` `SHKZG` | 收货行（仅采购相关移动） |
| `RBKP` | `RBSTAT` `IVTYP` `STBLG` `KURSF` `RMWWR` `LIFNR` | 发票抬头（过账状态 / 冲销） |
| `RSEG` | `EBELN/EBELP` `MENGE` `WRBTR` `SHKZG` `EXKBE` `XEKBZ` `LFBNR/LFPOS` | 发票行（费用 / 交货成本标记、参考收货） |
| `EBAN` | — | 下单前环节（追完整采购链） |
| `ESLH` / `ESLL` / `ESSR` | — | 服务类采购 |

---

## 🎯 审计场景支撑：采购三单匹配

本模块覆盖采购三单的完整数据链：

- **订单**：`EKKO` + `EKPO`
- **收货**：`MKPF` + `MSEG`
- **发票**：`RBKP` + `RSEG`

`EKBE` 以 `EBELN + EBELP` 为键，天然串联订单—收货—发票三单，是三单匹配的核心枢纽；`EKBZ` 用于按交货成本口径校正发票净额比较。

---

## ✅ 覆盖度与缺口

- **覆盖**：采购三单（订单 / 收货 / 发票）齐备，`EKBE` 提供串联键。
- **缺口**：价格条件记录 `KONV` / `KONP` 分组（`kon` / `kov`）在 KAAP 配置中为 `Extract` 关闭，不抽取；三单比对的数量 / 净额不受影响，仅"按价格条件拆解差异"的细度受限。

> ⚠️ 本工具仅做**抽取与落地**，不做匹配计算；差异判断、匹配率、Not Test 分类在下游 Python 工具（`purchase-three-match-*`、`test-tools`）。字段分隔符统一 `#|#`，与下游读取约定一致。

---

## 🔗 相关仓库

- [sap-abap-data-extraction 主仓库](../README.md) — 配置集与总览
- [test-tools](https://github.com/Gvmeakiss/test-tools) — 采购三单匹配测试与诊断
- [purchase-three-match-configurable](https://github.com/Gvmeakiss/purchase-three-match-configurable) — 可配置通用匹配工具包
