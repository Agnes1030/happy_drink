from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def http_request(method: str, url: str, body: dict | None = None) -> dict:
    data = None
    headers = {"Content-Type": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
    req = Request(url=url, method=method, headers=headers, data=data)
    with urlopen(req, timeout=15) as resp:
        payload = resp.read().decode("utf-8")
        return json.loads(payload) if payload else {}


def run(base_url: str, user_id: str) -> int:
    print(f"[1/5] health check -> {base_url}/health")
    health = http_request("GET", f"{base_url}/health")
    assert health.get("ok") is True, "health check failed"

    print(f"[2/5] create record -> {base_url}/records")
    create_body = {
        "user_id": user_id,
        "drink_type": "coffee",
        "brand": "SmokeTest",
        "product_name": "Americano",
        "size_ml": 355,
        "sugar_level": "no_sugar",
        "cups": 1,
        "unit_price": 15,
        "total_price": 15,
        "caffeine_mg_est": 150,
        "consumed_at": datetime.now(timezone.utc).isoformat(),
        "note": "smoke_test_seed",
        "source": "manual",
        "is_test": True,
    }
    created = http_request("POST", f"{base_url}/records", create_body)
    record_id = created.get("id")
    assert record_id, "create record did not return id"
    print(f"      created id: {record_id}")

    print(f"[3/5] list records -> {base_url}/records")
    listed = http_request("GET", f"{base_url}/records?user_id={user_id}&limit=5")
    assert listed.get("items") is not None, "list records did not return items"
    assert listed.get("total", 0) >= 1, "list records total invalid"

    print(f"[4/5] qa ask -> {base_url}/qa/ask")
    qa = http_request(
        "POST",
        f"{base_url}/qa/ask",
        {"user_id": user_id, "question": "这个月我喝咖啡花了多少钱？"},
    )
    assert qa.get("qa_result"), "qa ask missing qa_result"
    assert qa["qa_result"].get("answer"), "qa answer missing"
    print(f"      answer: {qa['qa_result']['answer']}")

    print(f"[5/5] stats summary -> {base_url}/stats/summary")
    stats = http_request("GET", f"{base_url}/stats/summary?user_id={user_id}&time_range=last_7_days")
    assert "total_cups" in stats, "stats summary missing total_cups"
    print(f"      last_7_days cups={stats['total_cups']} spending={stats['total_spending']}")

    print("Smoke test passed.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Run API smoke tests for milk tea app")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000", help="API base URL")
    parser.add_argument(
        "--user-id",
        default="00000000-0000-0000-0000-000000000001",
        help="Existing user UUID in DB",
    )
    args = parser.parse_args()

    try:
        return run(args.base_url.rstrip("/"), args.user_id)
    except (AssertionError, HTTPError, URLError, TimeoutError) as exc:
        print(f"Smoke test failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
