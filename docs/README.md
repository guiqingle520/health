# 文档索引

本目录存放健康管理应用的项目文档，按“快速启动、整体架构、详细设计”三个层级组织。

## 快速开始

- [setup.md](./setup.md) — 本地开发环境要求、依赖安装、前后端启动与常用命令

## 架构总览

- [architecture.md](./architecture.md) — 项目概览、Monorepo 结构、当前实现状态、技术选型、系统架构与阶段路线图

## 详细设计

- [design/database.md](./design/database.md) — 数据库表结构设计、聚合策略、与当前后端代码的映射关系
- [design/api.md](./design/api.md) — 后端 REST API 设计，覆盖认证、档案、饮食、运动、汇总与仪表盘接口
- [design/ui-design.md](./design/ui-design.md) — 移动端 UI / UX 设计要点、页面流与后续演进建议

## 建议阅读顺序

1. 先看 [setup.md](./setup.md) 启动项目
2. 再看 [architecture.md](./architecture.md) 理解整体结构与路线图
3. 按需查看 `design/` 下的数据库、API、UI 详细设计
