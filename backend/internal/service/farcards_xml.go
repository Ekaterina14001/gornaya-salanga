package service

import (
	"encoding/xml"
	"regexp"
	"strconv"
	"strings"
)

var cardCodeInXML = regexp.MustCompile(`(?i)cardcode="([^"]+)"`)

type fcQRY struct {
	Card       string `xml:"Card,attr"`
	Restaurant string `xml:"Restaurant,attr"`
	UnitNo     string `xml:"UnitNo,attr"`
	Kind       string `xml:"Kind,attr"`
	FindText   string `xml:"FindText,attr"`
	Inner      string `xml:",innerxml"`
}

type fcGetCardInfoQuery struct {
	XMLName xml.Name `xml:"ROOT"`
	QRY     fcQRY    `xml:"QRY"`
}

type fcFindByQRQuery struct {
	XMLName xml.Name `xml:"ROOT"`
	QRY     fcQRY    `xml:"QRY"`
}

type fcTransactionsRoot struct {
	XMLName xml.Name            `xml:"Root"`
	Items   []fcTransactionItem `xml:"Transactions>TransactionsEx"`
}

type fcTransactionItem struct {
	Card       string `xml:"Card,attr"`
	Account    string `xml:"Account,attr"`
	Kind       string `xml:"Kind,attr"`
	Summa      string `xml:"Summa,attr"`
	Restaurant string `xml:"Restaurant,attr"`
	RKUnit     string `xml:"RKUnit,attr"`
	RKCheck    string `xml:"RKCheck,attr"`
}

func parseGetCardInfoRequest(body []byte) (card, restaurant, unit string, err error) {
	qry, err := unmarshalQRY(body)
	if err != nil {
		return "", "", "", err
	}
	card = strings.TrimSpace(qry.Card)
	if card == "" {
		card = extractCardCodeFromInpBuf(string(body))
		if card == "" {
			card = extractCardCodeFromInpBuf(qry.Inner)
		}
	}
	return card, strings.TrimSpace(qry.Restaurant), strings.TrimSpace(qry.UnitNo), nil
}

func unmarshalQRY(body []byte) (fcQRY, error) {
	var q fcGetCardInfoQuery
	if err := xml.Unmarshal(body, &q); err == nil {
		return q.QRY, nil
	}
	var alt struct {
		XMLName xml.Name `xml:"Root"`
		QRY     fcQRY    `xml:"QRY"`
	}
	if err := xml.Unmarshal(body, &alt); err != nil {
		return fcQRY{}, err
	}
	return alt.QRY, nil
}

func extractCardCodeFromInpBuf(raw string) string {
	m := cardCodeInXML.FindStringSubmatch(raw)
	if len(m) < 2 {
		return ""
	}
	return strings.TrimSpace(m[1])
}

func parseFindByQRRequest(body []byte) (kind, text string, err error) {
	var q fcFindByQRQuery
	if err := xml.Unmarshal(body, &q); err != nil {
		return "", "", err
	}
	return strings.TrimSpace(q.QRY.Kind), strings.TrimSpace(q.QRY.FindText), nil
}

func parseTransactionsRequest(body []byte) ([]fcTransactionItem, error) {
	var root fcTransactionsRoot
	if err := xml.Unmarshal(body, &root); err != nil {
		var alt struct {
			XMLName xml.Name            `xml:"ROOT"`
			Items   []fcTransactionItem `xml:"Transactions>TransactionsEx"`
		}
		if err2 := xml.Unmarshal(body, &alt); err2 != nil {
			return nil, err
		}
		return alt.Items, nil
	}
	return root.Items, nil
}

func parseCardInt64(card string) (int64, bool) {
	card = strings.TrimSpace(card)
	if card == "" {
		return 0, false
	}
	v, err := strconv.ParseInt(card, 10, 64)
	if err != nil {
		return 0, false
	}
	return v, true
}

func kopecksToRubles(k int64) float64 {
	if k == 0 {
		return 0
	}
	sign := 1.0
	if k < 0 {
		sign = -1
		k = -k
	}
	return sign * float64(k) / 100.0
}

func rublesToKopecks(v float64) int64 {
	return int64(v * 100)
}

func escapeXMLAttr(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	s = strings.ReplaceAll(s, `"`, "&quot;")
	return s
}

func buildGetCardInfoResponse(cardCode int64, holder string, maxPayKopecks, balanceKopecks int64, notFound bool) string {
	if notFound {
		return `<?xml version="1.0" encoding="utf-8"?>` + "\n" +
			`<Root><GetCardInfoEx Result="1"/></Root>`
	}
	holder = escapeXMLAttr(holder)
	return `<?xml version="1.0" encoding="utf-8"?>` + "\n" +
		`<Root><GetCardInfoEx CardCode="` + strconv.FormatInt(cardCode, 10) + `" Account="` + strconv.FormatInt(cardCode, 10) +
		`" Deleted="0" Locked="0" Seize="0" Discount="0" Bonus="1" Summa="` + strconv.FormatInt(maxPayKopecks, 10) +
		`" DiscLimit="` + strconv.FormatInt(maxPayKopecks, 10) + `" Holder="` + holder +
		`" Sum2="` + strconv.FormatInt(balanceKopecks, 10) + `" Result="0"/></Root>`
}

func buildFindByQRResponse(cardCode int64, holder string, notFound bool) string {
	if notFound {
		return `<?xml version="1.0" encoding="utf-8"?>` + "\n" +
			`<Root><FindByQR Result="1"/></Root>`
	}
	return `<?xml version="1.0" encoding="utf-8"?>` + "\n" +
		`<Root><FindByQR Account="` + strconv.FormatInt(cardCode, 10) + `" CardCode="` + strconv.FormatInt(cardCode, 10) +
		`" Name="` + escapeXMLAttr(holder) + `" Result="0"/></Root>`
}

func buildTransactionsResponse(ok bool, message string) string {
	if ok {
		return `<?xml version="1.0" encoding="utf-8"?>` + "\n" +
			`<Root><TransactionsEx Result="0"/></Root>`
	}
	msg := escapeXMLAttr(message)
	if msg == "" {
		msg = "transaction failed"
	}
	return `<?xml version="1.0" encoding="utf-8"?>` + "\n" +
		`<Root><TransactionsEx Result="1"><OutBuf OutKind="1"><TRRESPONSE error_code="1" err_text="` + msg +
		`"/></OutBuf></TransactionsEx></Root>`
}

// farCardsTxKind maps FarCards / r_keeper transaction kind to spend/earn/cash.
func farCardsTxKind(kind int, summa int64) string {
	switch kind {
	case 0:
		return "spend"
	case 1:
		return "discount"
	case 2:
		return "earn"
	case 3:
		return "cash"
	default:
		if summa < 0 {
			return "spend"
		}
		if summa > 0 {
			return "earn"
		}
		return "skip"
	}
}

func parseKindAttr(raw string) int {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return -1
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return -1
	}
	if v >= 0 && v <= 3 {
		return v
	}
	return v % 256
}
