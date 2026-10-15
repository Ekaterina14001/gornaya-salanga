package service

import "testing"

func TestParseGetCardInfoRequest(t *testing.T) {
	body := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<ROOT>
<QRY Card="8002" Restaurant="9999" UnitNo="2">
    <INPBUF><ITEM cardcode="8002"/></INPBUF>
</QRY>
</ROOT>`)
	card, rest, unit, err := parseGetCardInfoRequest(body)
	if err != nil || card != "8002" || rest != "9999" || unit != "2" {
		t.Fatalf("parse=%v card=%q rest=%q unit=%q", err, card, rest, unit)
	}
}

func TestParseTransactionsRequest(t *testing.T) {
	body := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<Root>
  <Transactions>
    <TransactionsEx Card="32" Kind="0" Summa="-1500" Restaurant="73" RKUnit="201" RKCheck="139"/>
    <TransactionsEx Card="32" Kind="2" Summa="200" Restaurant="73" RKUnit="201" RKCheck="139"/>
  </Transactions>
</Root>`)
	items, err := parseTransactionsRequest(body)
	if err != nil || len(items) != 2 {
		t.Fatalf("items=%d err=%v", len(items), err)
	}
}
