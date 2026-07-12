package repository

import (
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNormalizeScanValueUUID(t *testing.T) {
	id := uuid.MustParse("550e8400-e29b-41d4-a716-446655440000")
	var raw [16]byte
	copy(raw[:], id[:])

	got := normalizeScanValue(raw)
	if got != id.String() {
		t.Fatalf("expected %q, got %v", id.String(), got)
	}

	pg := pgtype.UUID{Bytes: raw, Valid: true}
	got = normalizeScanValue(pg)
	if got != id.String() {
		t.Fatalf("pgtype uuid: expected %q, got %v", id.String(), got)
	}
}

func TestNormalizeScanValueNumeric(t *testing.T) {
	var n pgtype.Numeric
	if err := n.Scan("1500.50"); err != nil {
		t.Fatal(err)
	}
	got := normalizeScanValue(n)
	if got != 1500.5 {
		t.Fatalf("expected 1500.5, got %v", got)
	}
}
