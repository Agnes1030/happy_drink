from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any


ALLOWED_DRINK_TYPES = {"milk_tea", "coffee", "other"}


@dataclass(frozen=True)
class Template:
    template_id: str
    intent: str
    sql: str
    response_key: str


TEMPLATES: dict[str, Template] = {
    "intake_count_total": Template(
        template_id="intake_count_total",
        intent="intake",
        sql="""
            select coalesce(sum(cups), 0) as total_cups
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
        """,
        response_key="total_cups",
    ),
    "intake_count_by_type": Template(
        template_id="intake_count_by_type",
        intent="intake",
        sql="""
            select drink_type, coalesce(sum(cups), 0) as cups
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by drink_type
            order by cups desc
        """,
        response_key="rows",
    ),
    "intake_daily_avg": Template(
        template_id="intake_daily_avg",
        intent="intake",
        sql="""
            select round(coalesce(sum(cups), 0)::numeric / greatest(count(distinct date(consumed_at)), 1), 2) as daily_avg_cups
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
        """,
        response_key="daily_avg_cups",
    ),
    "intake_peak_day": Template(
        template_id="intake_peak_day",
        intent="intake",
        sql="""
            select date(consumed_at) as peak_day, coalesce(sum(cups), 0) as cups
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by date(consumed_at)
            order by cups desc, peak_day desc
            limit 1
        """,
        response_key="row",
    ),
    "spending_total": Template(
        template_id="spending_total",
        intent="spending",
        sql="""
            select coalesce(sum(coalesce(total_price, unit_price * cups, 0)), 0) as total_spending
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
        """,
        response_key="total_spending",
    ),
    "spending_total_by_type": Template(
        template_id="spending_total_by_type",
        intent="spending",
        sql="""
            select coalesce(sum(coalesce(total_price, unit_price * cups, 0)), 0) as total_spending
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
              and drink_type = %(drink_type)s
        """,
        response_key="total_spending",
    ),
    "spending_avg_per_cup": Template(
        template_id="spending_avg_per_cup",
        intent="spending",
        sql="""
            select round(
                coalesce(sum(coalesce(total_price, unit_price * cups, 0)), 0)::numeric
                / greatest(coalesce(sum(cups), 0), 1),
                2
            ) as avg_per_cup
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
        """,
        response_key="avg_per_cup",
    ),
    "spending_top_brand": Template(
        template_id="spending_top_brand",
        intent="spending",
        sql="""
            select coalesce(brand, 'unknown') as brand,
                   coalesce(sum(coalesce(total_price, unit_price * cups, 0)), 0) as spending
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by brand
            order by spending desc
            limit 1
        """,
        response_key="row",
    ),
    "habit_top_brand": Template(
        template_id="habit_top_brand",
        intent="habit",
        sql="""
            select coalesce(brand, 'unknown') as brand, count(*) as freq
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by brand
            order by freq desc
            limit 1
        """,
        response_key="top_brand",
    ),
    "habit_top_drink_type": Template(
        template_id="habit_top_drink_type",
        intent="habit",
        sql="""
            select drink_type, coalesce(sum(cups), 0) as cups
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by drink_type
            order by cups desc, drink_type asc
            limit 1
        """,
        response_key="row",
    ),
    "compare_drink_preference": Template(
        template_id="compare_drink_preference",
        intent="habit",
        sql="""
            select drink_type, coalesce(sum(cups), 0) as cups
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
              and drink_type in ('milk_tea', 'coffee')
            group by drink_type
            order by drink_type asc
        """,
        response_key="rows",
    ),
    "habit_top_hour": Template(
        template_id="habit_top_hour",
        intent="habit",
        sql="""
            select extract(hour from consumed_at)::int as hour, count(*) as freq
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by hour
            order by freq desc, hour asc
            limit 1
        """,
        response_key="row",
    ),
    "habit_sugar_preference": Template(
        template_id="habit_sugar_preference",
        intent="habit",
        sql="""
            select coalesce(sugar_level, 'unknown') as sugar_level, count(*) as freq
            from drink_records
            where user_id = %(user_id)s
              and is_test = false
              and consumed_at between %(start)s and %(end)s
            group by sugar_level
            order by freq desc
        """,
        response_key="rows",
    ),
}


def resolve_time_range(label: str, now: datetime) -> tuple[datetime, datetime]:
    if label == "today":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        return start, now
    if label == "last_7_days":
        start = (now - timedelta(days=6)).replace(hour=0, minute=0, second=0, microsecond=0)
        return start, now
    if label == "this_month":
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        return start, now
    raise ValueError("Unsupported time range")


def validate_params(params: dict[str, Any]) -> dict[str, Any]:
    drink_type = params.get("drink_type")
    if drink_type is not None and drink_type not in ALLOWED_DRINK_TYPES:
        raise ValueError("Invalid drink_type")
    return params
