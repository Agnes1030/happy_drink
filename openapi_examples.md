# API Examples for Frontend Integration

本文档提供前端接入时最常用的请求/响应样例，覆盖记录、问答、统计三个主流程。

Base URL（本地）:

```text
http://127.0.0.1:8000
```

测试用户（seed）:

```text
00000000-0000-0000-0000-000000000001
```

---

## 1) Health Check

### Request

```http
GET /health
```

### Response

```json
{
  "ok": true
}
```

---

## 2) Create Record

### Request

```http
POST /records
Content-Type: application/json
```

```json
{
  "user_id": "00000000-0000-0000-0000-000000000001",
  "drink_type": "coffee",
  "brand": "Starbucks",
  "product_name": "Americano",
  "size_ml": 355,
  "sugar_level": "no_sugar",
  "ice_level": "normal",
  "cups": 1,
  "unit_price": 25,
  "total_price": 25,
  "caffeine_mg_est": 180,
  "consumed_at": "2026-04-26T08:00:00+08:00",
  "note": "before meeting",
  "source": "manual"
}
```

### Response

```json
{
  "id": "f1111111-1111-1111-1111-111111111111",
  "user_id": "00000000-0000-0000-0000-000000000001",
  "drink_type": "coffee",
  "brand": "Starbucks",
  "product_name": "Americano",
  "size_ml": 355,
  "sugar_level": "no_sugar",
  "ice_level": "normal",
  "cups": 1,
  "unit_price": 25,
  "total_price": 25,
  "caffeine_mg_est": 180,
  "consumed_at": "2026-04-26T08:00:00+08:00",
  "note": "before meeting",
  "image_url": null,
  "source": "manual",
  "parse_confidence": null,
  "created_at": "2026-04-26T08:01:20.123456+08:00",
  "updated_at": "2026-04-26T08:01:20.123456+08:00"
}
```

---

## 3) List Records (with pagination/filter)

### Request

```http
GET /records?user_id=00000000-0000-0000-0000-000000000001&drink_type=coffee&brand=Starbucks&offset=0&limit=20
```

### Response

```json
{
  "items": [
    {
      "id": "f1111111-1111-1111-1111-111111111111",
      "user_id": "00000000-0000-0000-0000-000000000001",
      "drink_type": "coffee",
      "brand": "Starbucks",
      "product_name": "Americano",
      "size_ml": 355,
      "sugar_level": "no_sugar",
      "ice_level": "normal",
      "cups": 1,
      "unit_price": 25,
      "total_price": 25,
      "caffeine_mg_est": 180,
      "consumed_at": "2026-04-26T08:00:00+08:00",
      "note": "before meeting",
      "image_url": null,
      "source": "manual",
      "parse_confidence": null,
      "created_at": "2026-04-26T08:01:20.123456+08:00",
      "updated_at": "2026-04-26T08:01:20.123456+08:00"
    }
  ],
  "total": 8,
  "offset": 0,
  "limit": 20
}
```

---

## 4) Get / Update / Delete Record

### Get

```http
GET /records/{record_id}
```

### Update

```http
PUT /records/{record_id}
Content-Type: application/json
```

```json
{
  "brand": "Manner",
  "total_price": 22
}
```

### Delete

```http
DELETE /records/{record_id}
```

```json
{
  "ok": true,
  "deleted_id": "f1111111-1111-1111-1111-111111111111"
}
```

---

## 5) QA Query (template mode)

### Request

```http
POST /qa/query
Content-Type: application/json
```

```json
{
  "user_id": "00000000-0000-0000-0000-000000000001",
  "question": "这个月我喝咖啡花了多少钱？",
  "template_id": "spending_total_by_type",
  "time_range": "this_month",
  "drink_type": "coffee"
}
```

### Response

```json
{
  "question": "这个月我喝咖啡花了多少钱？",
  "intent": "spending",
  "template_id": "spending_total_by_type",
  "time_range": {
    "label": "this_month",
    "start": "2026-04-01T00:00:00+08:00",
    "end": "2026-04-26T15:15:00+08:00"
  },
  "result": {
    "total_spending": 148
  },
  "answer": "在所选时间内你的咖啡总花费是 148 元。"
}
```

---

## 6) QA Ask (natural language mode)

### Request

```http
POST /qa/ask
Content-Type: application/json
```

```json
{
  "user_id": "00000000-0000-0000-0000-000000000001",
  "question": "这个月我喝咖啡花了多少钱？"
}
```

### Response

```json
{
  "parsed_template_id": "spending_total_by_type",
  "parsed_time_range": "this_month",
  "parsed_drink_type": "coffee",
  "parser_confidence": 0.9,
  "suggestions": [
    "这周我喝了几杯？",
    "这个月我喝咖啡花了多少钱？",
    "我最常买的品牌是什么？"
  ],
  "fallback_needed": false,
  "fallback_message": null,
  "fallback_options": [],
  "qa_result": {
    "question": "这个月我喝咖啡花了多少钱？",
    "intent": "spending",
    "template_id": "spending_total_by_type",
    "time_range": {
      "label": "this_month",
      "start": "2026-04-01T00:00:00+08:00",
      "end": "2026-04-26T15:15:00+08:00"
    },
    "result": {
      "total_spending": 148
    },
    "answer": "在所选时间内你的咖啡总花费是 148 元。"
  }
}
```

---

## 7) Stats Summary

### Request

```http
GET /stats/summary?user_id=00000000-0000-0000-0000-000000000001&time_range=last_7_days
```

### Response

```json
{
  "user_id": "00000000-0000-0000-0000-000000000001",
  "time_range": "last_7_days",
  "total_cups": 8,
  "total_spending": 166,
  "milk_tea_cups": 3,
  "coffee_cups": 5
}
```

---

## 8) Common Frontend Handling Notes

- `GET /records` 返回分页对象，不是数组。
- `fallback_needed=true` 时，建议前端先给用户展示 `fallback_options` 再决定是否直接使用 `qa_result`。
- 所有时间字段都是 ISO 8601，建议前端按本地时区渲染。
- `drink_type` 推荐在前端做映射显示：
  - `milk_tea` -> 奶茶
  - `coffee` -> 咖啡
  - `other` -> 其他
