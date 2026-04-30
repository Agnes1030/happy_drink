from __future__ import annotations

import os
import re
from dataclasses import dataclass
from datetime import datetime
from typing import Any

import httpx

OCR_SPACE_URL = "https://api.ocr.space/parse/image"


@dataclass
class OcrParseResult:
    raw_text: str
    confidence: float
    parsed_fields: dict[str, Any]


class OcrServiceError(RuntimeError):
    pass


def parse_image_bytes(image_bytes: bytes, filename: str) -> OcrParseResult:
    api_key = os.getenv("OCR_SPACE_API_KEY")
    if not api_key:
        raise OcrServiceError("OCR_SPACE_API_KEY is not configured")

    files = {"file": (filename, image_bytes)}
    data = {
        "language": "chs",
        "isOverlayRequired": "false",
        "OCREngine": "2",
        "filetype": _guess_filetype(filename),
        "detectOrientation": "true",
        "scale": "true",
    }
    headers = {"apikey": api_key}

    try:
        response = httpx.post(OCR_SPACE_URL, data=data, files=files, headers=headers, timeout=60)
        response.raise_for_status()
    except httpx.HTTPError as exc:
        raise OcrServiceError(f"OCR service request failed: {exc}") from exc

    payload = response.json()
    if payload.get("IsErroredOnProcessing"):
        errors = payload.get("ErrorMessage") or payload.get("ErrorDetails") or "OCR processing failed"
        if isinstance(errors, list):
            errors = "; ".join(str(e) for e in errors)
        raise OcrServiceError(str(errors))

    parsed_results = payload.get("ParsedResults") or []
    raw_text = "\n".join((item.get("ParsedText") or "").strip() for item in parsed_results).strip()
    if not raw_text:
        raise OcrServiceError("OCR did not return readable text")

    parsed_fields = _extract_fields(raw_text)
    confidence = _estimate_confidence(parsed_fields)
    return OcrParseResult(raw_text=raw_text, confidence=confidence, parsed_fields=parsed_fields)


def _guess_filetype(filename: str) -> str:
    lowered = filename.lower()
    if lowered.endswith(".png"):
        return "PNG"
    if lowered.endswith(".webp"):
        return "WEBP"
    return "JPG"


def _extract_fields(raw_text: str) -> dict[str, Any]:
    lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
    text = "\n".join(lines)
    lowered = text.lower()

    drink_type = _detect_drink_type(text)
    brand = _detect_brand(lines)
    product_name = _detect_product_name(lines)
    sugar_level = _detect_sugar_level(text)
    size_ml = _detect_size_ml(text)
    price = _detect_price(text)
    consumed_at = _detect_datetime(text)

    return {
        "drink_type": drink_type,
        "brand": brand,
        "product_name": product_name,
        "sugar_level": sugar_level,
        "size_ml": size_ml,
        "unit_price": price,
        "total_price": price,
        "cups": 1,
        "consumed_at": consumed_at.isoformat() if consumed_at else None,
        "ocr_text": text,
        "source": "photo_confirmed",
        "image_url": None,
        "parse_confidence": None,
        "keywords": lowered,
    }


def _detect_drink_type(text: str) -> str:
    lowered = text.lower()
    if any(token in text for token in ["奶茶", "珍珠", "波霸", "鲜奶茶", "乌龙奶茶"]):
        return "milk_tea"
    if any(token in lowered for token in ["coffee", "latte", "americano", "espresso", "cappuccino", "mocha"]):
        return "coffee"
    if any(token in text for token in ["咖啡", "拿铁", "美式", "浓缩", "摩卡", "卡布奇诺"]):
        return "coffee"
    return "other"


def _detect_brand(lines: list[str]) -> str | None:
    known_brands = [
        "Starbucks",
        "Manner",
        "Luckin",
        "瑞幸",
        "星巴克",
        "喜茶",
        "奈雪",
        "霸王茶姬",
        "沪上阿姨",
        "Cotti",
        "库迪",
    ]
    for line in lines[:8]:
        for brand in known_brands:
            if brand.lower() in line.lower():
                return brand
    return lines[0][:100] if lines else None


def _detect_product_name(lines: list[str]) -> str | None:
    patterns = ["拿铁", "美式", "摩卡", "奶茶", "咖啡", "乌龙", "红茶", "Americano", "Latte", "Mocha"]
    for line in lines:
        if any(pattern.lower() in line.lower() for pattern in patterns):
            return line[:200]
    return lines[1][:200] if len(lines) > 1 else None


def _detect_sugar_level(text: str) -> str | None:
    if "无糖" in text:
        return "no_sugar"
    if "少糖" in text or "微糖" in text:
        return "less_sugar"
    if "半糖" in text:
        return "half"
    if "全糖" in text:
        return "full"
    return None


def _detect_size_ml(text: str) -> int | None:
    match = re.search(r"(\d{2,4})\s*ml", text, flags=re.IGNORECASE)
    if not match:
        return None
    value = int(match.group(1))
    return value if 100 <= value <= 2000 else None


def _detect_price(text: str) -> float | None:
    matches = re.findall(r"(?:¥|￥)?\s*(\d{1,3}(?:\.\d{1,2})?)", text)
    prices = []
    for match in matches:
        try:
            value = float(match)
        except ValueError:
            continue
        if 3 <= value <= 200:
            prices.append(value)
    return max(prices) if prices else None


def _detect_datetime(text: str) -> datetime | None:
    match = re.search(r"(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?", text)
    if not match:
        return None
    year, month, day, hour, minute = match.groups()
    try:
        return datetime(
            int(year),
            int(month),
            int(day),
            int(hour or 0),
            int(minute or 0),
        )
    except ValueError:
        return None


def _estimate_confidence(parsed_fields: dict[str, Any]) -> float:
    score = 0.2
    for key in ["drink_type", "brand", "product_name", "unit_price", "sugar_level", "size_ml"]:
        if parsed_fields.get(key) not in (None, "", "other"):
            score += 0.12
    return min(round(score, 4), 0.95)
