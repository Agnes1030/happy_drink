# happy_drink

一个面向奶茶 / 咖啡爱好者的轻量记录与智能分析应用。项目通过 **Flutter 客户端 + FastAPI 后端 + PostgreSQL**，帮助用户完成饮品记录、趋势分析、图片 OCR 识别，以及自然语言问答式洞察。

## 项目简介

`happy_drink` 的目标是把“记录饮品消费”这件事做得更轻、更自然：
- 可以手动新增记录
- 可以通过图片识别辅助录入
- 可以从历史记录中查看趋势、花费和偏好
- 可以像聊天一样提问，获取关于自己饮用习惯的智能洞察

这个项目既适合作为一个完整的产品型作品展示，也适合作为 Flutter + FastAPI 全栈应用的学习与迭代基础。

## 核心功能

- **手动记录饮品**：支持记录饮品类型、品牌、名称、甜度、价格、杯数、备注与心情。
- **图片 OCR 录入**：支持从相册或相机选图，调用 OCR 识别内容后进入确认页再保存。
- **记录列表查看**：支持按品牌、饮品类型筛选历史记录。
- **趋势分析**：支持查看近 7 天 / 近 30 天的饮用杯数、饮品偏好、总花费与均价。
- **AI 对话式洞察**：支持像聊天一样询问“这个月花了多少钱”“最爱喝什么”“更偏爱咖啡还是奶茶，为什么”等问题。
- **真实 / 测试数据隔离**：AI 洞察与趋势分析默认基于真实数据，避免测试记录污染结论。

## 页面说明

### 1. 首页
首页用于展示近期概览与核心入口，包括：
- 总杯数
- 总花费
- 奶茶 / 咖啡杯数概览
- “拍照扫描”入口
- “手动录入”入口

### 2. 记录页
记录页用于查看历史饮品记录，支持：
- 列表浏览
- 按品牌筛选
- 按咖啡 / 奶茶筛选
- 查看每条记录的时间、品牌、价格与类型

### 3. 趋势页
趋势页用于做阶段性饮用分析，当前支持：
- 近 7 天 / 近 30 天切换
- 每日饮用杯数图表
- 奶茶 vs 咖啡偏好占比
- 总花费
- 饮品均价

### 4. AI 洞察页
AI 洞察页已经改为聊天式交互，支持：
- 多轮对话
- 推荐问题快捷提问
- 问答结果展示
- 比较型 / 偏好型问题的结构化回答

### 5. 子流程页面
首页可进入两个子流程页面：
- **手动录入页**：填写饮品记录并保存
- **拍照扫描页**：上传图片 → OCR 识别 → 人工确认 → 保存记录

## 技术栈

### 客户端
- Flutter
- Material 3

### 服务端
- FastAPI
- PostgreSQL
- psycopg

### 智能能力
- OCR.Space：图片文字识别
- 模板化问答查询：确保问答过程不使用自由 SQL
- 混合意图解析方向：规则解析 + 更强的复杂意图扩展空间

## 项目结构

```text
happy_drink/
├── app/                # FastAPI 后端
├── lib/                # Flutter 前端主代码
├── scripts/            # 冒烟测试 / 调试脚本
├── design/             # 页面设计稿与说明
├── schema.sql          # 数据库结构
├── seed.sql            # 示例 / 测试数据
├── docker-compose.yml  # 本地 Docker 编排
└── README.md
```

## 本地运行

### 方式一：Docker 启动（推荐）

```bash
make docker-up
```

查看日志：

```bash
make docker-logs
```

关闭服务：

```bash
make docker-down
```

### 方式二：本地启动后端

安装依赖：

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

初始化数据库：

```bash
psql "postgresql://postgres:postgres@localhost:5432/milk_tea_app" -f schema.sql
```

可选导入示例数据：

```bash
psql "postgresql://postgres:postgres@localhost:5432/milk_tea_app" -f seed.sql
```

启动后端：

```bash
uvicorn app.main:app --reload
```

### Flutter 客户端运行

安装依赖：

```bash
flutter pub get
```

运行客户端：

```bash
flutter run
```

## 开发辅助命令

```bash
make help
make venv
make install
make init-db
make seed
make run
make smoke
make docker-up
make docker-smoke
make docker-logs
make docker-down
```

## 接口与调试

启动成功后可访问：

- Swagger 文档：`http://127.0.0.1:8000/docs`
- 健康检查：`http://127.0.0.1:8000/health`

运行冒烟测试：

```bash
python3 scripts/smoke_test.py
```

更多接口请求示例见：

- `openapi_examples.md`

## 当前项目亮点

- Flutter + FastAPI 全栈联动
- OCR 辅助录入 + 人工确认流程
- 面向真实用户数据的趋势与 AI 洞察
- 多轮聊天式 AI 页面体验
- 逐步演进的意图解析与模板化安全查询机制

## 后续可扩展方向

- 更强的复杂意图解析（比较、解释、复合问题）
- 更完善的 AI 洞察解释能力
- 用户登录与云同步
- 周报提醒 / 健康建议
- 更完整的图表与数据可视化
