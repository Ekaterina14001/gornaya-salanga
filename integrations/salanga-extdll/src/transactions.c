#include "salanga_internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void append_tx(char *out, size_t cap, size_t *pos, const FC_TRANSACTION_EX *tx) {
    char line[1024];
    sprintf_s(line, sizeof(line),
              "    <TransactionsEx Card=\"%lld\" PersonID=\"%lld\" Account=\"%lu\" "
              "Kind=\"%u\" Summa=\"%lld\" Restaurant=\"%u\" RKUnit=\"%u\" RKCheck=\"%lu\"/>\r\n",
              (long long)tx->card, (long long)tx->holder_id, (unsigned long)tx->account,
              (unsigned)tx->kind, (long long)tx->summa_k, (unsigned)tx->restaurant,
              (unsigned)tx->unit_no, (unsigned long)tx->check_no);
    strncat_s(out + *pos, cap - *pos, line, _TRUNCATE);
    *pos = strlen(out);
}

int salanga_transactions_ex(SalangaConfig *cfg, uint32_t count, void *list,
                            const void *inp_buf, uint32_t inp_len) {
    if (!cfg || !list || count == 0) return 1;

    char body[262144];
    strcpy_s(body, sizeof(body),
             "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<Root>\r\n  <Transactions>\r\n");
    size_t pos = strlen(body);

    void **ptrs = (void **)list;
    for (uint32_t i = 0; i < count; i++) {
        FC_TRANSACTION_EX *tx = (FC_TRANSACTION_EX *)ptrs[i];
        if (!tx) return 1;
        if (tx->struct_size != 0 && tx->struct_size != FC_TRANSACTION_SIZE) {
            salanga_log(cfg, 0, "TransactionsEx: tx[%u] size=%u", i, tx->struct_size);
        }
        append_tx(body, sizeof(body), &pos, tx);
    }

    strcat_s(body, sizeof(body), "  </Transactions>\r\n");
    if (inp_len > 0 && inp_buf) {
        strncat_s(body, sizeof(body), (const char *)inp_buf, inp_len);
        strcat_s(body, sizeof(body), "\r\n");
    }
    strcat_s(body, sizeof(body), "</Root>");

    char response[65536];
    if (!salanga_http_post(cfg, "/api/farcards/transactionsex", body, strlen(body), response, sizeof(response))) {
        return 1;
    }

    int result = 1;
    if (fc_xml_tag_result(response, "TransactionsEx", &result)) {
        return result == 0 ? 0 : 1;
    }
    if (strstr(response, "Result=\"0\"")) return 0;
    return 1;
}

void salanga_find_by_qr(SalangaConfig *cfg, const char *qr_token, FC_CB_FIND cb, void *back) {
    if (!cfg || !qr_token || !cb || !qr_token[0]) return;

    char body[8192];
    sprintf_s(body, sizeof(body),
              "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n"
              "<ROOT><QRY Kind=\"3\" FindText=\"");
    size_t base = strlen(body);
    for (const char *p = qr_token; *p && base + 8 < sizeof(body); p++) {
        if (*p == '&') { strcat_s(body, sizeof(body), "&amp;"); base += 5; }
        else if (*p == '<') { strcat_s(body, sizeof(body), "&lt;"); base += 4; }
        else if (*p == '"') { strcat_s(body, sizeof(body), "&quot;"); base += 6; }
        else { char ch[2] = { *p, 0 }; strcat_s(body, sizeof(body), ch); base++; }
    }
    strcat_s(body, sizeof(body), "\"/></ROOT>");

    char response[65536];
    if (!salanga_http_post(cfg, "/api/farcards/findbyqr", body, strlen(body), response, sizeof(response))) {
        return;
    }

    int result = 1;
    if (!fc_xml_tag_result(response, "FindByQR", &result) || result != 0) return;

    int64_t card = 0, account = 0;
    fc_xml_attr_int(response, "FindByQR", "CardCode", &card);
    fc_xml_attr_int(response, "FindByQR", "Account", &account);
    if (account == 0) account = card;

    char holder_utf8[128];
    char holder_ansi[64];
    holder_ansi[0] = '\0';
    if (fc_xml_attr_str(response, "FindByQR", "Name", holder_utf8, sizeof(holder_utf8))) {
        fc_utf8_to_ansi(holder_utf8, holder_ansi, sizeof(holder_ansi), cfg->xml_cp);
    }
    cb(back, (uint32_t)account, card, holder_ansi);
}
