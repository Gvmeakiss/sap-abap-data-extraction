# SAP ABAP 取数工具

> SAP ECC6 数据提取工具的 XML 配置模板与操作手册，按审计口径提取 FI / MM / SD 模块数据，支持 dry-run 验证。

<p align="center">
  <img src="https://img.shields.io/badge/SAP-ECC6-1F6FB2" alt="SAP ECC6">
  <img src="https://img.shields.io/badge/Modules-FI%2FMM%2FSD-0E8A16" alt="Modules">
  <img src="https://img.shields.io/badge/Format-XML%20%7C%20PDF-FF6F00" alt="Format">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/github/last-commit/Gvmeakiss/sap-abap-data-extraction?label=updated" alt="Updated">
</p>

## 📋 目录

- [Overview · 概述](#overview--概述)
- [Directory Structure · 目录结构](#directory-structure--目录结构)
- [Contents · 内容说明](#contents--内容说明)
- [Usage Notes · 使用说明](#usage-notes--使用说明)

SAP ABAP 数据提取工具配置与操作手册 · SAP ABAP data extraction tool configuration and user manuals

## Overview · 概述

SAP ECC6 数据提取工具的 XML 配置模板与操作手册，用于从 SAP ECC6 系统按审计口径提取数据（FI / MM / SD 模块），支持 dry-run 测试模式验证提取配置。

This repository contains XML configuration templates and user manuals for a SAP ECC6 data extraction tool, covering FI / MM / SD module extractions with dry-run testing support.

## Directory Structure · 目录结构

```
.
├── User Manual/
│   ├── Data_Extraction_Tool_SAP_Execution_Guide(2020v1).pdf   # 执行指南 Execution Guide
│   └── SAP_ABAP_Program_操作手册简易版.pdf                    # ABAP 程序操作手册
└── xml File/
    ├── Testing跑通测试/
    │   └── SAP_ABAP_TEST.xml                                  # 连通性测试配置
    └── Extraction_Tool_MN_2023_1-8_dryRun_20230912/
        ├── FI_SAP_ECC6.xml                                    # FI 模块取数配置
        ├── MM_SAP_ECC6.xml                                    # MM 模块取数配置
        ├── SD_SAP_ECC6.xml                                    # SD 模块取数配置
        └── SAP_ABAP_Program_操作手册简易版.pdf                # 配套操作手册
```

## Contents · 内容说明

| 文件 | 说明 |
|---|---|
| XML 配置文件 | SAP ECC6 取数参数模板（FI/MM/SD），含选择条件、输出字段与校验规则 |
| 执行指南 (2020v1) | 工具安装、配置与执行的完整流程说明 |
| 操作手册 | ABAP 程序的运行参数与常见问题处理 |

## Usage Notes · 使用说明

- 配置以 dry-run 模式运行，验证取数逻辑后再正式执行
- 各模块配置独立，可按审计项目需要启用对应 XML
- 输出结果建议按「日期_模块_场景」规范归档，保证可复核性

---

<div align="center">

**James Li · 审计数据分析工具集**

📫 本工具用于内部审计与数据核对，辅助分析但不替代专业判断，不作为对外签字版本。

</div>
