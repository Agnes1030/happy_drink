from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Literal
from uuid import UUID

from fastapi import FastAPI, File, Form, HTTPException, UploadFile

from app.db import get_conn
from app.intent_parser import ParsedIntent
from app.ocr_service import OcrServiceError, parse_image_bytes
from app.query_templates import TEMPLATES, resolve_time_range, validate_params
from app.schemas import (
    DrinkRecordCreateRequest,
    DrinkRecordOut,
    DrinkRecordUpdateRequest,
    PhotoConfirmRequest,
    PhotoParseResponse,
    ParsedRecordDraft,
    QaAskResponse,
    QaNaturalRequest,
    QaQueryRequest,
    QaQueryResponse,
    RecordListResponse,
    StatsSummaryResponse,
    TimeRangeOut,
)

app = FastAPI(title="Milk Tea Coffee Tracker API", version="0.1.0")
UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "/tmp/milk-tea-uploads"))
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
MOOD_PREFIX = "心情"


def compose_note(mood_tag: str | None, note: str | None) -> str | None:
    parts = []
    if mood_tag:
        parts.append(f"{MOOD_PREFIX}：{mood_tag}")
    if note:
        parts.append(note.strip())
    combined = "\n".join(part for part in parts if part)
    return combined or None


def create_record_in_db(payload: dict) -> dict:
    validate_record_payload(payload)
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into drink_records (
                  user_id, drink_type, brand, product_name, size_ml, sugar_level, ice_level,
                  cups, unit_price, total_price, caffeine_mg_est, consumed_at, note, image_url,
                  source, parse_confidence, is_test
                ) values (
                  %(user_id)s, %(drink_type)s, %(brand)s, %(product_name)s, %(size_ml)s, %(sugar_level)s, %(ice_level)s,
                  %(cups)s, %(unit_price)s, %(total_price)s, %(caffeine_mg_est)s, %(consumed_at)s, %(note)s, %(image_url)s,
                  %(source)s, %(parse_confidence)s, %(is_test)s
                )
                returning *
                """,
                payload,
            )
            row = cur.fetchone()
            conn.commit()
    return row


def migrate_test_records() -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update drink_records
                set is_test = true
                where brand = 'SmokeTest'
                   or note = 'smoke_test_seed'
                   or note = 'demo_seed'
                """
            )
            conn.commit()


migrate_test_records()


def render_answer(template_id: str, result: dict, req: QaQueryRequest) -> str:
    if template_id == "intake_count_total":
        return f"在所选时间内你一共喝了 {result['total_cups']} 杯。"
    if template_id == "intake_count_by_type":
        return f"分类型杯数：{result['breakdown']}。"
    if template_id == "intake_daily_avg":
        return f"在所选时间内你平均每天喝 {result['daily_avg_cups']} 杯。"
    if template_id == "intake_peak_day":
        return f"你喝得最多的一天是 {result['peak_day']}，共 {result['cups']} 杯。"
    if template_id == "spending_total":
        return f"在所选时间内你总花费 {result['total_spending']} 元。"
    if template_id == "spending_total_by_type":
        t = "奶茶" if req.drink_type == "milk_tea" else "咖啡"
        return f"在所选时间内你的{t}总花费是 {result['total_spending']} 元。"
    if template_id == "spending_avg_per_cup":
        return f"在所选时间内你平均每杯 {result['avg_per_cup']} 元。"
    if template_id == "spending_top_brand":
        return f"花费最高的品牌是 {result['brand']}，共 {result['spending']} 元。"
    if template_id == "habit_top_brand":
        return f"你最常买的品牌是 {result['brand']}（{result['freq']} 次）。"
    if template_id == "habit_top_drink_type":
        drink_label = {
            "milk_tea": "奶茶",
            "coffee": "咖啡",
            "other": "其他饮品",
        }.get(result['drink_type'], "其他饮品")
        return f"这个时间范围里你最常喝的是{drink_label}（共 {result['cups']} 杯）。"
    if template_id == "compare_drink_preference":
        preferred = result['preferred']
        if preferred == '平手':
            return f"这个时间范围里你喝咖啡和奶茶的杯数一样，都是 {result['coffee_cups']} 杯。"
        preferred_label = '咖啡' if preferred == 'coffee' else '奶茶'
        return f"这个时间范围里你更偏爱{preferred_label}，因为咖啡共 {result['coffee_cups']} 杯，奶茶共 {result['milk_tea_cups']} 杯。"
    if template_id == "habit_top_hour":
        return f"你最常喝的时间是 {result['hour']} 点（{result['freq']} 次）。"
    if template_id == "habit_sugar_preference":
        return f"甜度偏好分布：{result['breakdown']}。"
    return "已完成统计。"


def parse_natural_question(question: str) -> ParsedIntent:
    q = question.lower()
    time_range = "last_7_days"
    confidence = 0.65
    if any(k in question for k in ["今天", "今日"]) or "today" in q:
        time_range = "today"
        confidence += 0.1
    elif any(k in question for k in ["这个月", "本月"]) or "this month" in q:
        time_range = "this_month"
        confidence += 0.1

    drink_type = None
    if "奶茶" in question or "milk tea" in q:
        drink_type = "milk_tea"
        confidence += 0.1
    elif "咖啡" in question or "coffee" in q:
        drink_type = "coffee"
        confidence += 0.1

    if any(k in question for k in ["咖啡还是奶茶", "奶茶还是咖啡"]):
        return ParsedIntent(
            intent_kind="compare_drink_preference",
            template_id="compare_drink_preference",
            time_range=time_range,
            drink_type=None,
            confidence=min(confidence + 0.2, 0.98),
            needs_explanation=("为什么" in question),
            comparison_target="drink_type",
        )

    if any(k in question for k in ["花费", "多少钱", "花了"]) or "spend" in q:
        template_id = "spending_total_by_type" if drink_type else "spending_total"
        confidence += 0.15
    elif any(k in question for k in ["平均", "日均"]) and any(k in question for k in ["杯", "喝"]):
        template_id = "intake_daily_avg"
        confidence += 0.15
    elif any(k in question for k in ["最多", "哪天"]):
        template_id = "intake_peak_day"
        confidence += 0.15
    elif any(k in question for k in ["品牌", "常买"]):
        template_id = "habit_top_brand"
        confidence += 0.15
    elif any(k in question for k in ["最爱喝什么", "最常喝什么", "偏好喝什么", "最常喝的饮品"]):
        template_id = "habit_top_drink_type"
        confidence += 0.18
    elif any(k in question for k in ["几点", "时段", "时间"]):
        template_id = "habit_top_hour"
        confidence += 0.15
    elif any(k in question for k in ["甜度", "全糖", "半糖"]):
        template_id = "habit_sugar_preference"
        confidence += 0.15
    elif any(k in question for k in ["几杯", "多少杯", "杯数"]):
        template_id = "intake_count_total"
        confidence += 0.15
    else:
        template_id = "intake_count_total"

    return ParsedIntent(
        intent_kind="template",
        template_id=template_id,
        time_range=time_range,
        drink_type=drink_type,
        confidence=min(confidence, 0.98),
    )


def get_record_or_404(record_id: str) -> dict:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("select * from drink_records where id = %(id)s", {"id": record_id})
            row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="record not found")
    return row


def validate_record_payload(payload: dict) -> None:
    if "cups" in payload and payload["cups"] is not None and payload["cups"] <= 0:
        raise HTTPException(status_code=400, detail="cups must be > 0")
    if "size_ml" in payload and payload["size_ml"] is not None and payload["size_ml"] <= 0:
        raise HTTPException(status_code=400, detail="size_ml must be > 0")
    if "unit_price" in payload and payload["unit_price"] is not None and payload["unit_price"] < 0:
        raise HTTPException(status_code=400, detail="unit_price must be >= 0")
    if "total_price" in payload and payload["total_price"] is not None and payload["total_price"] < 0:
        raise HTTPException(status_code=400, detail="total_price must be >= 0")
    if "parse_confidence" in payload and payload["parse_confidence"] is not None:
        c = payload["parse_confidence"]
        if c < 0 or c > 1:
            raise HTTPException(status_code=400, detail="parse_confidence must be between 0 and 1")


def log_qa(
    user_id: str,
    question: str,
    intent: str,
    time_range: str,
    template_id: str,
    params: dict,
    answer: str,
) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into qa_logs (
                  user_id, question, intent, time_range, query_template, query_params, answer_text
                ) values (
                  %(user_id)s, %(question)s, %(intent)s, %(time_range)s, %(query_template)s, %(query_params)s::jsonb, %(answer_text)s
                )
                """,
                {
                    "user_id": user_id,
                    "question": question,
                    "intent": intent,
                    "time_range": time_range,
                    "query_template": template_id,
                    "query_params": json.dumps(params, default=str),
                    "answer_text": answer,
                },
            )
            conn.commit()


@app.get("/health")
def health() -> dict:
    return {"ok": True}


@app.post("/records", response_model=DrinkRecordOut)
def create_record(req: DrinkRecordCreateRequest) -> DrinkRecordOut:
    row = create_record_in_db(req.model_dump())
    return DrinkRecordOut(**row)


@app.post("/records/photo-parse", response_model=PhotoParseResponse)
async def parse_record_photo(
    user_id: str = Form(...),
    file: UploadFile = File(...),
) -> PhotoParseResponse:
    try:
        UUID(user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID") from exc

    if not file.filename:
        raise HTTPException(status_code=400, detail="Image filename is required")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image file is empty")

    safe_name = f"{datetime.now().timestamp():.0f}-{Path(file.filename).name}"
    image_path = UPLOAD_DIR / safe_name
    image_path.write_bytes(image_bytes)

    try:
        ocr_result = parse_image_bytes(image_bytes, file.filename)
    except OcrServiceError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    draft_payload = {
        "drink_type": ocr_result.parsed_fields.get("drink_type", "other"),
        "brand": ocr_result.parsed_fields.get("brand"),
        "product_name": ocr_result.parsed_fields.get("product_name"),
        "size_ml": ocr_result.parsed_fields.get("size_ml"),
        "sugar_level": ocr_result.parsed_fields.get("sugar_level"),
        "cups": ocr_result.parsed_fields.get("cups", 1),
        "unit_price": ocr_result.parsed_fields.get("unit_price"),
        "total_price": ocr_result.parsed_fields.get("total_price"),
        "consumed_at": ocr_result.parsed_fields.get("consumed_at"),
        "note": None,
        "mood_tag": None,
        "image_url": str(image_path),
        "parse_confidence": ocr_result.confidence,
    }

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into parse_jobs (user_id, image_url, status, ocr_text, parsed_json, confidence)
                values (%(user_id)s, %(image_url)s, %(status)s, %(ocr_text)s, %(parsed_json)s::jsonb, %(confidence)s)
                returning id
                """,
                {
                    "user_id": user_id,
                    "image_url": str(image_path),
                    "status": "needs_confirm",
                    "ocr_text": ocr_result.raw_text,
                    "parsed_json": json.dumps(draft_payload),
                    "confidence": ocr_result.confidence,
                },
            )
            job = cur.fetchone() or {}
            conn.commit()

    return PhotoParseResponse(
        parse_job_id=job["id"],
        status="needs_confirm",
        raw_text=ocr_result.raw_text,
        confidence=ocr_result.confidence,
        image_url=str(image_path),
        draft=ParsedRecordDraft(**draft_payload),
    )


@app.post("/records/photo-confirm", response_model=DrinkRecordOut)
def confirm_photo_record(req: PhotoConfirmRequest) -> DrinkRecordOut:
    try:
        UUID(req.user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID") from exc

    payload = {
        "user_id": req.user_id,
        "drink_type": req.drink_type,
        "brand": req.brand,
        "product_name": req.product_name,
        "size_ml": req.size_ml,
        "sugar_level": req.sugar_level,
        "ice_level": None,
        "cups": req.cups,
        "unit_price": req.unit_price,
        "total_price": req.total_price,
        "caffeine_mg_est": None,
        "consumed_at": req.consumed_at,
        "note": compose_note(req.mood_tag, req.note),
        "image_url": req.image_url,
        "source": "photo_confirmed",
        "parse_confidence": req.parse_confidence,
        "is_test": False,
    }
    row = create_record_in_db(payload)

    if req.parse_job_id is not None:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    update parse_jobs
                    set status = 'done',
                        parsed_json = %(parsed_json)s::jsonb,
                        confidence = %(confidence)s,
                        error_message = null
                    where id = %(id)s
                    """,
                    {
                        "id": req.parse_job_id,
                        "parsed_json": json.dumps(payload, default=str),
                        "confidence": req.parse_confidence,
                    },
                )
                conn.commit()

    return DrinkRecordOut(**row)


@app.get("/records/{record_id}", response_model=DrinkRecordOut)
def get_record(record_id: str) -> DrinkRecordOut:
    try:
        UUID(record_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid record_id UUID") from exc
    row = get_record_or_404(record_id)
    return DrinkRecordOut(**row)


@app.put("/records/{record_id}", response_model=DrinkRecordOut)
def update_record(record_id: str, req: DrinkRecordUpdateRequest) -> DrinkRecordOut:
    try:
        UUID(record_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid record_id UUID") from exc

    payload = req.model_dump(exclude_unset=True)
    if not payload:
        row = get_record_or_404(record_id)
        return DrinkRecordOut(**row)
    validate_record_payload(payload)

    set_clauses = []
    params: dict = {"id": record_id}
    for key, value in payload.items():
        set_clauses.append(f"{key} = %({key})s")
        params[key] = value
    set_sql = ", ".join(set_clauses)
    sql = f"update drink_records set {set_sql} where id = %(id)s returning *"

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="record not found")
            conn.commit()
    return DrinkRecordOut(**row)


@app.delete("/records/{record_id}")
def delete_record(record_id: str) -> dict:
    try:
        UUID(record_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid record_id UUID") from exc

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("delete from drink_records where id = %(id)s returning id", {"id": record_id})
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="record not found")
            conn.commit()
    return {"ok": True, "deleted_id": record_id}


@app.get("/records", response_model=RecordListResponse)
def list_records(
    user_id: str,
    start: datetime | None = None,
    end: datetime | None = None,
    drink_type: Literal["milk_tea", "coffee", "other"] | None = None,
    brand: str | None = None,
    offset: int = 0,
    limit: int = 20,
) -> RecordListResponse:
    if offset < 0:
        raise HTTPException(status_code=400, detail="offset must be >= 0")
    if limit < 1 or limit > 200:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 200")

    filters = {"user_id": user_id, "is_test": False}
    where_clauses = ["user_id = %(user_id)s", "is_test = %(is_test)s"]

    if start is not None:
        filters["start"] = start
        where_clauses.append("consumed_at >= %(start)s")
    if end is not None:
        filters["end"] = end
        where_clauses.append("consumed_at <= %(end)s")
    if drink_type is not None:
        filters["drink_type"] = drink_type
        where_clauses.append("drink_type = %(drink_type)s")
    if brand is not None:
        filters["brand"] = brand
        where_clauses.append("brand = %(brand)s")

    filters["offset"] = offset
    filters["limit"] = limit
    where_sql = " and ".join(where_clauses)
    list_sql = f"""
        select *
        from drink_records
        where {where_sql}
        order by consumed_at desc
        offset %(offset)s
        limit %(limit)s
    """
    count_sql = f"""
        select count(*) as total
        from drink_records
        where {where_sql}
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(list_sql, filters)
            rows = cur.fetchall()
            cur.execute(count_sql, filters)
            total_row = cur.fetchone() or {"total": 0}
    return RecordListResponse(
        items=[DrinkRecordOut(**row) for row in rows],
        total=int(total_row["total"]),
        offset=offset,
        limit=limit,
    )


@app.get("/stats/summary", response_model=StatsSummaryResponse)
def stats_summary(
    user_id: str,
    time_range: Literal["today", "last_7_days", "this_month"] = "last_7_days",
) -> StatsSummaryResponse:
    try:
        UUID(user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID") from exc

    now = datetime.now()
    start, end = resolve_time_range(time_range, now)
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select
                  coalesce(sum(cups), 0) as total_cups,
                  coalesce(sum(coalesce(total_price, unit_price * cups, 0)), 0) as total_spending,
                  coalesce(sum(case when drink_type = 'milk_tea' then cups else 0 end), 0) as milk_tea_cups,
                  coalesce(sum(case when drink_type = 'coffee' then cups else 0 end), 0) as coffee_cups
                from drink_records
                where user_id = %(user_id)s
                  and is_test = false
                  and consumed_at between %(start)s and %(end)s
                """,
                {"user_id": user_id, "start": start, "end": end},
            )
            row = cur.fetchone() or {}

    return StatsSummaryResponse(
        user_id=user_id,
        time_range=time_range,
        total_cups=int(row.get("total_cups", 0)),
        total_spending=float(row.get("total_spending", 0)),
        milk_tea_cups=int(row.get("milk_tea_cups", 0)),
        coffee_cups=int(row.get("coffee_cups", 0)),
    )


@app.post("/qa/query", response_model=QaQueryResponse)
def qa_query(req: QaQueryRequest) -> QaQueryResponse:
    try:
        UUID(req.user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID") from exc

    template = TEMPLATES.get(req.template_id)
    if not template:
        raise HTTPException(status_code=400, detail="Unsupported template_id")

    now = datetime.now()
    start, end = resolve_time_range(req.time_range, now)
    params = validate_params(
        {
            "user_id": req.user_id,
            "start": start,
            "end": end,
            "drink_type": req.drink_type,
        }
    )

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(template.sql, params)
            if template.response_key == "rows":
                rows = cur.fetchall()
                row = {}
            else:
                row = cur.fetchone() or {}
                rows = []

    if req.template_id == "habit_top_brand":
        result = {"brand": row.get("brand", "unknown"), "freq": row.get("freq", 0)}
    elif req.template_id == "habit_top_hour":
        result = {"hour": row.get("hour", 0), "freq": row.get("freq", 0)}
    elif req.template_id == "spending_top_brand":
        result = {"brand": row.get("brand", "unknown"), "spending": row.get("spending", 0)}
    elif req.template_id == "intake_peak_day":
        peak_day = row.get("peak_day")
        peak_day = peak_day.isoformat() if peak_day else "N/A"
        result = {"peak_day": peak_day, "cups": row.get("cups", 0)}
    elif req.template_id == "habit_top_drink_type":
        result = {"drink_type": row.get("drink_type", "other"), "cups": row.get("cups", 0)}
    elif req.template_id == "compare_drink_preference":
        rows_by_type = {r.get("drink_type"): int(r.get("cups", 0)) for r in rows}
        coffee_cups = rows_by_type.get("coffee", 0)
        milk_tea_cups = rows_by_type.get("milk_tea", 0)
        if coffee_cups == milk_tea_cups:
            preferred = "平手"
        elif coffee_cups > milk_tea_cups:
            preferred = "coffee"
        else:
            preferred = "milk_tea"
        result = {
            "preferred": preferred,
            "coffee_cups": coffee_cups,
            "milk_tea_cups": milk_tea_cups,
        }
    elif req.template_id == "intake_count_by_type":
        breakdown = ", ".join(f"{r.get('drink_type')}: {r.get('cups')}" for r in rows) if rows else "无数据"
        result = {"breakdown": breakdown}
    elif req.template_id == "habit_sugar_preference":
        breakdown = ", ".join(f"{r.get('sugar_level')}: {r.get('freq')}" for r in rows) if rows else "无数据"
        result = {"breakdown": breakdown}
    else:
        result = {template.response_key: row.get(template.response_key, 0)}

    answer = render_answer(req.template_id, result, req)
    log_qa(
        user_id=req.user_id,
        question=req.question,
        intent=template.intent,
        time_range=req.time_range,
        template_id=req.template_id,
        params=params,
        answer=answer,
    )
    return QaQueryResponse(
        question=req.question,
        intent=template.intent,
        template_id=req.template_id,
        time_range=TimeRangeOut(label=req.time_range, start=start, end=end),
        result=result,
        answer=answer,
    )


@app.post("/qa/ask", response_model=QaAskResponse)
def qa_ask(req: QaNaturalRequest) -> QaAskResponse:
    parsed = parse_natural_question(req.question)
    suggestions = [
        "这周我喝了几杯？",
        "这个月我喝咖啡花了多少钱？",
        "我最常买的品牌是什么？",
    ]

    if parsed.intent_kind == "compare_drink_preference":
        query_req = QaQueryRequest(
            user_id=req.user_id,
            question=req.question,
            template_id="compare_drink_preference",
            time_range=parsed.time_range,
            drink_type=None,
        )
        qa_result = qa_query(query_req)
        fallback_needed = parsed.confidence < 0.8
        return QaAskResponse(
            parsed_template_id="compare_drink_preference",
            parsed_time_range=parsed.time_range,
            parsed_drink_type=None,
            parser_confidence=float(parsed.confidence),
            suggestions=suggestions,
            fallback_needed=fallback_needed,
            fallback_message="我对你的问题理解不够确定，下面是我猜你可能想问的内容：" if fallback_needed else None,
            fallback_options=suggestions if fallback_needed else [],
            qa_result=qa_result,
        )

    query_req = QaQueryRequest(
        user_id=req.user_id,
        question=req.question,
        template_id=parsed.template_id,
        time_range=parsed.time_range,
        drink_type=parsed.drink_type,
    )
    qa_result = qa_query(query_req)
    fallback_needed = float(parsed.confidence) < 0.8
    fallback_message = None
    fallback_options: list[str] = []
    if fallback_needed:
        fallback_message = "我对你的问题理解不够确定，下面是我猜你可能想问的内容："
        fallback_options = list(suggestions)
    return QaAskResponse(
        parsed_template_id=parsed.template_id,
        parsed_time_range=parsed.time_range,
        parsed_drink_type=parsed.drink_type,
        parser_confidence=float(parsed.confidence),
        suggestions=list(suggestions),
        fallback_needed=fallback_needed,
        fallback_message=fallback_message,
        fallback_options=fallback_options,
        qa_result=qa_result,
    )
