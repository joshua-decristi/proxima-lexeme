# Proxima Lexeme - Makefile
# Infrastructure-focused commands for Gleam/Wisp application

.PHONY: help dev build start stop clean

help:
	@echo "Proxima Lexeme - Available Commands"
	@echo ""
	@echo "Development:"
	@echo "  make dev            - Start development server (native)"
	@echo ""
	@echo "Production:"
	@echo "  make build          - Build production container"
	@echo "  make start          - Start production server"
	@echo ""
	@echo "Management:"
	@echo "  make stop           - Stop all services"
	@echo "  make clean          - Clean build artifacts & containers"
	@echo ""

dev:
	@cd apps/proxima_lexeme && watchexec --shell=none -r -e gleam,html,css,js -- gleam run

build:
	@echo "Building production server..."
	@podman compose build prod 1>/dev/null 2>&1 || true

start:
	@echo "Starting production server..."
	@podman compose up prod

stop:
	@echo "Stopping all services..."
	@podman compose down --rmi local 2>/dev/null || podman rm -f proxima-lexeme-prod 2>/dev/null || true

clean:
	@echo "Cleaning build artifacts & containers..."
	@rm -rf apps/proxima_lexeme/build/ apps/proxima_lexeme/priv/ 2>/dev/null || true
	@podman compose down -v --remove-orphans 2>/dev/null || true

test:
	@cd apps/proxima_lexeme && gleam test --target erlang
