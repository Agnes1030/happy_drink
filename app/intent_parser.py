from __future__ import annotations

from dataclasses import dataclass
from typing import Literal


IntentKind = Literal[
    'template',
    'compare_drink_preference',
]


@dataclass(frozen=True)
class ParsedIntent:
    intent_kind: IntentKind
    template_id: str | None
    time_range: Literal['today', 'last_7_days', 'this_month']
    drink_type: Literal['milk_tea', 'coffee', 'other'] | None
    confidence: float
    needs_explanation: bool = False
    comparison_target: Literal['drink_type'] | None = None
