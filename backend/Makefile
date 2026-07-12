.PHONY: run migrate-up migrate-down build test

run:
	go run ./cmd/api

build:
	go build -o bin/api ./cmd/api

migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1

test:
	go test ./...

tidy:
	go mod tidy
