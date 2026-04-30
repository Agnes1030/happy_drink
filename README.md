# Milk Tea / Coffee Tracker API (MVP)

一个可直接启动的后端最小版本，包含：
- PostgreSQL 建表脚本（`schema.sql`）
- 问答白名单模板执行（`app/query_templates.py`）
- `POST /qa/query`、`POST /qa/ask`、`POST /records`、`GET /records`、`GET /stats/summary`（`app/main.py`）
- 记录 CRUD：`GET /records/{id}`、`PUT /records/{id}`、`DELETE /records/{id}`

## 1. 安装依赖

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 2. 配置数据库

```bash
cp .env.example .env
```

创建数据库后执行：

```bash
psql "postgresql://postgres:postgres@localhost:5432/milk_tea_app" -f schema.sql
```

可选：导入测试数据

```bash
psql "postgresql://postgres:postgres@localhost:5432/milk_tea_app" -f seed.sql
```

## 3. 启动服务

```bash
export $(cat .env | xargs)
uvicorn app.main:app --reload
```

运行一键冒烟测试（需服务已启动）：

```bash
python3 scripts/smoke_test.py
```

## 3.1 Makefile 一键命令

```bash
make help
make venv
make install
make init-db
make seed
make run
make smoke
```

Docker 一键启动（包含 Postgres + API）：

```bash
make docker-up
make docker-smoke
make docker-logs
make docker-down
```

可选自定义参数：

```bash
make init-db DB_URL="postgresql://postgres:postgres@localhost:5432/milk_tea_app"
make smoke BASE_URL="http://127.0.0.1:8000" USER_ID="00000000-0000-0000-0000-000000000001"
```

打开：
- Swagger: http://127.0.0.1:8000/docs
- Health: http://127.0.0.1:8000/health

## 4. /qa/query 请求示例

```json
{
  "user_id": "00000000-0000-0000-0000-000000000001",
  "question": "这个月我喝咖啡花了多少钱？",
  "template_id": "spending_total_by_type",
  "time_range": "this_month",
  "drink_type": "coffee"
}
```

`/qa/ask`（自然语言）示例：

```json
{
  "user_id": "00000000-0000-0000-0000-000000000001",
  "question": "这个月我喝咖啡花了多少钱？"
}
```

`POST /qa/ask` 返回会包含：
- 解析出的 `parsed_template_id`、`parsed_time_range`、`parsed_drink_type`
- `parser_confidence`（规则解析置信度）
- `suggestions`（推荐追问）
- `qa_result`（最终统计结果）
- 当置信度较低时还会返回：
  - `fallback_needed=true`
  - `fallback_message`
  - `fallback_options`（建议你点击或改写提问）

`/stats/summary` 示例：

```bash
GET /stats/summary?user_id=00000000-0000-0000-0000-000000000001&time_range=last_7_days
```

`GET /records` 已支持筛选和分页：

```bash
GET /records?user_id=00000000-0000-0000-0000-000000000001&drink_type=coffee&brand=Starbucks&offset=0&limit=20
```

记录 CRUD 示例：

```bash
GET /records/{id}
PUT /records/{id}
DELETE /records/{id}
```

`PUT /records/{id}` 目前已做业务校验：
- `cups > 0`
- `size_ml > 0`
- `unit_price >= 0`
- `total_price >= 0`
- `parse_confidence` 在 `[0, 1]`

## 5. 当前已支持模板（11 个）

- `intake_count_total`
- `intake_count_by_type`
- `intake_daily_avg`
- `intake_peak_day`
- `spending_total`
- `spending_total_by_type`
- `spending_avg_per_cup`
- `spending_top_brand`
- `habit_top_brand`
- `habit_top_hour`
- `habit_sugar_preference`

你可以继续在 `app/query_templates.py` 扩展模板，保持“模板 + 参数校验”模式，避免自由 SQL 风险。

## 6. 前端接入样例

详见 `openapi_examples.md`（包含 records / qa / stats 的请求响应示例）。
