.PHONY: test up up-schema up-migrations down down-volumes logs help

COMPOSE_OVERRIDE := $(shell [ -f compose.override.yaml ] && echo "-f compose.override.yaml")
MODE ?= migrations

# Run docker compose with specified mode (schema or migrations)
up: down-volumes
	docker compose -f compose.yaml -f compose.$(MODE).yaml -f compose.test.yaml $(COMPOSE_OVERRIDE) up -d --build

# Run with DDL scripts
up-schema:
	@$(MAKE) up MODE=schema

# Run with migrations (default)
up-migrations:
	$(MAKE) up MODE=migrations

down:
	docker compose -f compose.yaml $(COMPOSE_OVERRIDE) down --remove-orphans

down-volumes:
	docker compose -f compose.yaml $(COMPOSE_OVERRIDE) down --volumes --remove-orphans

logs:
	docker compose logs -f

help:
	@echo "Available targets:"
	@echo "  up              - Run docker compose (MODE=schema|migrations, default: migrations)"
	@echo "  up-schema       - Run docker compose with DDL scripts"
	@echo "  up-migrations   - Run docker compose with Liquibase migrations"
	@echo "  down            - Stop docker compose"
	@echo "  down-volumes    - Stop docker compose and remove volumes"
	@echo "  logs            - View docker compose logs"
	@echo "  help            - Show this help message"