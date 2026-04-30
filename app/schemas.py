from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


TemplateId = Literal[
    "intake_count_total",
    "intake_count_by_type",
    "intake_daily_avg",
    "intake_peak_day",
    "spending_total",
    "spending_total_by_type",
    "spending_avg_per_cup",
    "spending_top_brand",
    "habit_top_brand",
    "habit_top_drink_type",
    "compare_drink_preference",
    "habit_top_hour",
    "habit_sugar_preference",
]


class QaQueryRequest(BaseModel):
    user_id: str = Field(description="Users.id UUID string")
    question: str
    template_id: TemplateId
    time_range: Literal["today", "last_7_days", "this_month"]
    drink_type: Literal["milk_tea", "coffee", "other"] | None = None


class TimeRangeOut(BaseModel):
    label: str
    start: datetime
    end: datetime


class QaQueryResponse(BaseModel):
    question: str
    intent: str
    template_id: str
    time_range: TimeRangeOut
    result: dict
    answer: str


class QaNaturalRequest(BaseModel):
    user_id: str = Field(description="Users.id UUID string")
    question: str


class QaAskResponse(BaseModel):
    parsed_template_id: TemplateId
    parsed_time_range: Literal["today", "last_7_days", "this_month"]
    parsed_drink_type: Literal["milk_tea", "coffee", "other"] | None = None
    parser_confidence: float
    suggestions: list[str]
    fallback_needed: bool
    fallback_message: str | None = None
    fallback_options: list[str] = []
    qa_result: QaQueryResponse


class DrinkRecordCreateRequest(BaseModel):
    user_id: str
    drink_type: Literal["milk_tea", "coffee", "other"]
    brand: str | None = None
    product_name: str | None = None
    size_ml: int | None = None
    sugar_level: Literal["no_sugar", "less_sugar", "half", "full"] | None = None
    ice_level: str | None = None
    cups: int = 1
    unit_price: float | None = None
    total_price: float | None = None
    caffeine_mg_est: int | None = None
    consumed_at: datetime
    note: str | None = None
    image_url: str | None = None
    source: Literal["manual", "photo_auto", "photo_confirmed"] = "manual"
    parse_confidence: float | None = None
    is_test: bool = False


class ParsedRecordDraft(BaseModel):
    drink_type: Literal["milk_tea", "coffee", "other"] = "other"
    brand: str | None = None
    product_name: str | None = None
    size_ml: int | None = None
    sugar_level: Literal["no_sugar", "less_sugar", "half", "full"] | None = None
    cups: int = 1
    unit_price: float | None = None
    total_price: float | None = None
    consumed_at: datetime | None = None
    note: str | None = None
    mood_tag: str | None = None
    image_url: str | None = None
    parse_confidence: float | None = None


class PhotoParseResponse(BaseModel):
    parse_job_id: UUID
    status: Literal["done", "needs_confirm"]
    raw_text: str
    confidence: float
    image_url: str | None = None
    draft: ParsedRecordDraft


class PhotoConfirmRequest(BaseModel):
    user_id: str
    drink_type: Literal["milk_tea", "coffee", "other"]
    brand: str | None = None
    product_name: str | None = None
    size_ml: int | None = None
    sugar_level: Literal["no_sugar", "less_sugar", "half", "full"] | None = None
    cups: int = 1
    unit_price: float | None = None
    total_price: float | None = None
    consumed_at: datetime
    note: str | None = None
    mood_tag: str | None = None
    image_url: str | None = None
    parse_confidence: float | None = None
    parse_job_id: UUID | None = None
    is_test: bool = False


class DrinkRecordOut(BaseModel):
    id: UUID
    user_id: UUID
    drink_type: str
    brand: str | None = None
    product_name: str | None = None
    size_ml: int | None = None
    sugar_level: str | None = None
    ice_level: str | None = None
    cups: int
    unit_price: float | None = None
    total_price: float | None = None
    caffeine_mg_est: int | None = None
    consumed_at: datetime
    note: str | None = None
    image_url: str | None = None
    source: str
    parse_confidence: float | None = None
    is_test: bool
    created_at: datetime
    updated_at: datetime


class DrinkRecordUpdateRequest(BaseModel):
    drink_type: Literal["milk_tea", "coffee", "other"] | None = None
    brand: str | None = None
    product_name: str | None = None
    size_ml: int | None = None
    sugar_level: Literal["no_sugar", "less_sugar", "half", "full"] | None = None
    ice_level: str | None = None
    cups: int | None = None
    unit_price: float | None = None
    total_price: float | None = None
    caffeine_mg_est: int | None = None
    consumed_at: datetime | None = None
    note: str | None = None
    image_url: str | None = None
    source: Literal["manual", "photo_auto", "photo_confirmed"] | None = None
    parse_confidence: float | None = None
    is_test: bool | None = None


class StatsSummaryResponse(BaseModel):
    user_id: str
    time_range: Literal["today", "last_7_days", "this_month"]
    total_cups: int
    total_spending: float
    milk_tea_cups: int
    coffee_cups: int


class RecordListResponse(BaseModel):
    items: list[DrinkRecordOut]
    total: int
    offset: int
    limit: int
