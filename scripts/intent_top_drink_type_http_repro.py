from __future__ import annotations

import json
import urllib.request


def main() -> None:
    req = urllib.request.Request(
        'http://127.0.0.1:8000/qa/ask',
        data=json.dumps(
            {
                'user_id': '00000000-0000-0000-0000-000000000001',
                'question': '这个月我最爱喝什么',
            }
        ).encode(),
        headers={'Content-Type': 'application/json'},
    )
    with urllib.request.urlopen(req) as response:
        payload = json.load(response)
    assert payload['parsed_template_id'] == 'habit_top_drink_type', payload


if __name__ == '__main__':
    main()
