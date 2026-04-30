from __future__ import annotations

from app.main import parse_natural_question


def main() -> None:
    parsed = parse_natural_question('这个月我最爱喝什么')
    assert parsed['template_id'] == 'habit_top_drink_type', parsed


if __name__ == '__main__':
    main()
