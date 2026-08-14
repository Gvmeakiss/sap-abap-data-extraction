# SAP ECC6 取数工具配置集 🗂️

> 按审计口径从 SAP ECC6 提取 FI / MM / SD 模块数据的 ABAP 程序（KAAP）XML 配置模板与操作手册，支持 dry-run 验证。

[![Language](https://img.shields.io/badge/language-XML%20%7C%20ABAP-blue)](https://github.com/Gvmeakiss/sap-abap-data-extraction) [![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/Gvmeakiss/sap-abap-data-extraction/blob/main/LICENSE) [![Domain](https://img.shields.io/badge/domain-Audit%20Analytics-orange)](https://github.com/Gvmeakiss/sap-abap-data-extraction)

## 📌 项目简介

本仓库是 SAP 审计数据提取（ABAP 程序 KAAP）的**配置与手册**集合，不含可独立运行的程序。它提供 FI / MM / SD 三个模块的 XML 取数配置，供审计人员在 SAP ECC6 上按既定审计口径提取数据；配套执行指南与 ABAP 程序操作手册说明如何装载配置、运行与归档结果。MN_2023 配置为 dry-run 验证版本（`dryRun_20230912`），另含一份连通性测试配置 `SAP_ABAP_TEST.xml`。

## ✨ 功能特性

- **三模块取数配置**：`FI_SAP_ECC6.xml`、`MM_SAP_ECC6.xml`、`SD_SAP_ECC6.xml` 覆盖财务会计、物料管理、销售与分销。
- **标准 SAP 表约束与字段清单**：每个配置以 `<Group>/<GrpObj>` 列出待提取表，以 `<ConstraintTable>` 定义关联约束，以 `<Field>` 定义输出字段与哈希总计字段。
- **dry-run 测试配置**：`Extraction_Tool_MN_2023_1-8_dryRun_20230912` 用于上线前验证逻辑；`Testing跑通测试/SAP_ABAP_TEST.xml` 用于系统连通性测试。
- **统一输出约定**：字段分隔符 `#|#`（`P_COLSEP`），按 `P_FILESZ=2000` 分片，支持 ZIP 打包（`P_ZIP=X`）与分目录输出（`P_CLDIR=X`）。
- **配套文档**：执行指南（2020v1）与 ABAP 程序简易操作手册（PDF）。

## 📂 目录结构

```
sap-abap-data-extraction/
├── User Manual/
│   ├── Data_Extraction_Tool_SAP_Execution_Guide(2020v1).pdf   # 执行指南
│   └── SAP_ABAP_Program_操作手册简易版.pdf                    # ABAP 程序操作手册
└── xml File/
    ├── Testing跑通测试/
    │   └── SAP_ABAP_TEST.xml                                  # 连通性测试配置（FY2021, CoCode 1000）
    └── Extraction_Tool_MN_2023_1-8_dryRun_20230912/
        ├── FI_SAP_ECC6.xml                                    # FI 模块取数配置
        ├── MM_SAP_ECC6.xml                                    # MM 模块取数配置
        ├── SD_SAP_ECC6.xml                                    # SD 模块取数配置
        └── SAP_ABAP_Program_操作手册简易版.pdf                # 配套操作手册
```

## 🔧 环境要求

- SAP ECC6 系统 + SAP GUI / ABAP 提取程序 KAAP（本仓库仅提供配置，无 Python 依赖）。
- 提取输出：TXT/CSV，字段分隔符 `#|#`，可选 ZIP 打包。

## 🚀 安装

本仓库为配置与手册，**无需安装依赖**。将对应 XML 载入 KAAP 提取程序即可使用：

```bash
# 1. 将 FI/MM/SD 的 XML 配置导入 KAAP 提取程序
# 2. 先以 dry-run 配置（dryRun_20230912）验证取数逻辑
# 3. 验证通过后，正式执行并在输出目录按「日期_模块_场景」规范归档
```

## 💡 快速开始 / 使用示例

```bash
# 连通性测试：载入 SAP_ABAP_TEST.xml，确认与目标客户端（CoCode 1000, FY2021）连通
# 正式取数前：载入 Extraction_Tool_MN_2023_*_dryRun 配置做 dry-run
# 模块取数：分别载入 FI_SAP_ECC6.xml / MM_SAP_ECC6.xml / SD_SAP_ECC6.xml
```

## 🧠 核心逻辑（方法论）

KAAP 的 XML 配置由以下层级组成，决定“取什么、怎么筛、怎么出”：

- **`<Scope>`**：提取范围——`Year`、`Date`（如 `20200101-20201231`）、`CoCode` 列表（1000/1100/1600/1800/2000/2100/2200/2999/3000/4000/5000/5100/5200/6000/7000/8000/9000）、`Language`（EN/ZH）。
- **`<Setting>`**：运行参数——`P_PATH` 输出路径、`P_COLSEP=#|#` 分隔符、`P_FILESZ` 分片大小、`P_ZIP` 打包开关、`P_PIDS` 并行进程数。
- **`<Report>` / `<Group>`**：报表分组——`FI`、`SD_MM`、`SYS`、`SCREENING_REPORT`；每个 `<Group>` 含 `GrpID`、`GrpLabel` 与 `Extract` 开关。
- **`<GrpObj>` / `<ConstraintTable>` / `<Field>`**：具体表清单、关联约束表与输出字段。

各模块实际配置范围（来自 XML）：

| 模块 | 分组（GrpLabel） | 约束表（ConstraintTable）节选 |
|---|---|---|
| FI | Accounting Documents、FI Master (ANLT/SKA1/SKAT/SKB1)、FI GL Master & Summary、Electronic Bank Statements、Secondary Index (Customer/GL/Vendor)、CO Tables、Payment Program、Project | ANLT、BKPF、BSAD、BSAK、BSAS、BSID、BSIK、BSIS、FAGLFLEXT、FEBEP、FEBKO、GLT0、SKAT、SKB1、T881T |
| MM | Invoice Documents、Material Movement Doc、Purchase Documents、Purchase Service Package | EBAN、EKKO、ESSR、MKPF、RBKP、RBKP_BLOCKED |
| SD | Pricing Conditions、Pricing Conditions KONV、Deliveries、Sales Document Flow、Sales Invoices、Sales Orders | LIKP、VBAK、VBFA、VBRK |

## 📋 输入与输出

- **输入**：SAP ECC6 系统（经 ABAP 提取程序 KAAP 读取）。
- **输出**：按配置导出的 TXT/CSV 文件（字段分隔符 `#|#`），可选 ZIP 打包，文件名前缀可由 `P_PFIX` 设定（连通性测试为 `Testing`）。

## ⚙️ 配置说明

- 提取范围在 `<Scope>` 中设定（年度、日期区间、公司代码、语言）。
- 字段分隔符、分片大小、ZIP 打包等在 `<Setting>` 中设定。
- `P_COLSEP=#|#` 与本系列 Python 工具（sap-fi-2026h1 / sap-sd-three-match）的读取约定一致。

## ⚠️ 注意事项

- 数据脱敏：本仓库不含任何真实客户业务数据，XML 仅为配置模板，示例公司代码/年度为占位口径。
- 口径说明：实际提取字段、筛选条件与表范围以各 XML 配置为准；正式使用前务必以 dry-run 验证。
- 输出结果应按规定命名规范归档，保证可复核、可回溯。

## 🔗 相关仓库

- [sap-fi-2026h1](https://github.com/Gvmeakiss/sap-fi-2026h1) — 2026 H1 FI 凭证/余额处理与勾稽
- [sap-sd-three-match](https://github.com/Gvmeakiss/sap-sd-three-match) — SD 销售三单匹配与差异分析
- [test-tools](https://github.com/Gvmeakiss/test-tools) — 采购三单匹配测试与诊断工具集

## 📄 License

MIT

---

<div align="center">

*Disclaimer: Personal project and personal views. Not affiliated with or endorsed by KPMG or any client.*<br>
*本仓库为个人项目与个人观点，与任何前/现雇主及客户无关。*

</div>
