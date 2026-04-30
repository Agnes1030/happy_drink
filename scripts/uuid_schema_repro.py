from datetime import datetime
from uuid import uuid4

from app.schemas import DrinkRecordOut


def main() -> None:
    DrinkRecordOut(
        id=uuid4(),
        user_id=uuid4(),
        drink_type="coffee",
        brand="x",
        product_name="y",
        size_ml=1,
        sugar_level="no_sugar",
        ice_level=None,
        cups=1,
        unit_price=1,
        total_price=1,
        caffeine_mg_est=1,
        consumed_at=datetime.now(),
        note=None,
        image_url=None,
        source="manual",
        parse_confidence=None,
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )


if __name__ == "__main__":
    main()
