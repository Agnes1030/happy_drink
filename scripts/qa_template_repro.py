from __future__ import annotations

from datetime import datetime

from app.query_templates import TEMPLATES, validate_params


def main() -> None:
    template = TEMPLATES['intake_count_total']
    params = validate_params(
        {
            'user_id': '00000000-0000-0000-0000-000000000001',
            'start': datetime(2026, 4, 22),
            'end': datetime(2026, 4, 28),
            'drink_type': None,
        }
    )
    assert '(%(drink_type)s is null or drink_type = %(drink_type)s)' in template.sql


if __name__ == '__main__':
    main()
