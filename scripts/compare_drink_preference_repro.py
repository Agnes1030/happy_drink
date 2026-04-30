from __future__ import annotations

import json
import urllib.request


def ask(question: str) -> dict:
    req = urllib.request.Request(
        'http://127.0.0.1:8000/qa/ask',
        data=json.dumps(
            {
                'user_id': '00000000-0000-0000-0000-000000000001',
                'question': question,
            }
        ).encode(),
        headers={'Content-Type': 'application/json'},
    )
    with urllib.request.urlopen(req) as response:
        return json.load(response)


def main() -> None:
    payload = ask('这个月我最爱喝咖啡还是奶茶，为什么？')
    assert payload['parsed_template_id'] == 'compare_drink_preference', payload
    assert '为什么' not in payload['qa_result']['answer'] or '因为' in payload['qa_result']['answer'], payload


if __name__ == '__main__':
    main()
