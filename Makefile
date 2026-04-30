SHELL := /bin/zsh

PYTHON ?= python3
PIP ?= pip3
DB_URL ?= postgresql://postgres:postgres@localhost:5432/milk_tea_app
BASE_URL ?= http://127.0.0.1:8000
USER_ID ?= 00000000-0000-0000-0000-000000000001

.PHONY: help venv install init-db seed run smoke fmt-check docker-up docker-down docker-logs docker-smoke

help:
	@echo "Available targets:"
	@echo "  make venv      - create local virtual environment"
	@echo "  make install   - install Python dependencies"
	@echo "  make init-db   - apply schema.sql to database"
	@echo "  make seed      - load seed.sql test data"
	@echo "  make run       - start FastAPI server"
	@echo "  make smoke     - run smoke test script"
	@echo "  make fmt-check - compile-check app/scripts"
	@echo "  make docker-up   - start API + Postgres via docker compose"
	@echo "  make docker-down - stop docker compose stack"
	@echo "  make docker-logs - tail docker compose logs"
	@echo "  make docker-smoke - run smoke test against docker API"

venv:
	$(PYTHON) -m venv .venv

install:
	@if [ ! -d ".venv" ]; then echo "No .venv found, run 'make venv' first."; exit 1; fi
	source .venv/bin/activate && $(PIP) install -r requirements.txt

init-db:
	psql "$(DB_URL)" -f schema.sql

seed:
	psql "$(DB_URL)" -f seed.sql

run:
	@if [ -f ".env" ]; then export $$(cat .env | xargs); fi; uvicorn app.main:app --reload

smoke:
	$(PYTHON) scripts/smoke_test.py --base-url "$(BASE_URL)" --user-id "$(USER_ID)"

fmt-check:
	$(PYTHON) -m compileall app scripts

docker-up:
	docker compose up -d --build

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f --tail=200

docker-smoke:
	$(PYTHON) scripts/smoke_test.py --base-url "http://127.0.0.1:8000" --user-id "$(USER_ID)"
