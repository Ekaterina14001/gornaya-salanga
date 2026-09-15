package service

import "testing"

func TestCalcUDSPurchaseChargeScores(t *testing.T) {
	got := CalcUDSPurchase(1000, 0, 0, 200, 350.5, 5, 50, 100)
	if got.MaxPoints != 350.5 {
		t.Fatalf("maxPoints=%v", got.MaxPoints)
	}
	if got.Points != 200 {
		t.Fatalf("points=%v", got.Points)
	}
	if got.Cash != 800 {
		t.Fatalf("cash=%v", got.Cash)
	}
	if got.CashBack != 40 {
		t.Fatalf("cashBack=%v want 40 (5%% of 800)", got.CashBack)
	}
	if got.DiscountAmount != 0 {
		t.Fatalf("discount should be 0 for CHARGE_SCORES")
	}
}

func TestCalcUDSPurchaseCapsByPercent(t *testing.T) {
	got := CalcUDSPurchase(1000, 0, 0, 900, 2000, 5, 50, 100)
	if got.MaxPoints != 500 {
		t.Fatalf("maxPoints=%v", got.MaxPoints)
	}
	if got.Points != 500 {
		t.Fatalf("capped points=%v", got.Points)
	}
	if got.Cash != 500 {
		t.Fatalf("cash=%v", got.Cash)
	}
}

func TestCalcUDSPurchaseBelowMinReceipt(t *testing.T) {
	got := CalcUDSPurchase(50, 0, 0, 0, 100, 5, 50, 100)
	if got.CashBack != 0 {
		t.Fatalf("cashBack=%v, expected 0 below min receipt", got.CashBack)
	}
}
