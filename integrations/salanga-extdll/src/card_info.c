#include "salanga_internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void build_get_card_body(char *out, size_t cap, int64_t card,
                                uint32_t restaurant, uint32_t unit_no,
                                const void *inp_buf, uint32_t inp_len) {
    if (inp_len > 0 && inp_buf) {
        if (inp_len >= cap) inp_len = (uint32_t)cap - 1;
        memcpy(out, inp_buf, inp_len);
        out[inp_len] = '\0';
        if (strstr(out, "<ROOT") || strstr(out, "<Root") || strstr(out, "<?xml")) return;
    }
    sprintf_s(out, cap,
              "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n"
              "<ROOT><QRY Card=\"%lld\" Restaurant=\"%lu\" UnitNo=\"%lu\">",
              (long long)card, (unsigned long)restaurant, (unsigned long)unit_no);
    if (inp_len > 0 && inp_buf) {
        size_t base = strlen(out);
        if (base + inp_len + 32 < cap) {
            strcat_s(out, cap, "\r\n");
            strncat_s(out, cap, (const char *)inp_buf, inp_len);
        }
    }
    strcat_s(out, cap, "\r\n</QRY></ROOT>");
}

int salanga_get_card_info_ex(SalangaConfig *cfg, int64_t card,
                             uint32_t restaurant, uint32_t unit_no,
                             FC_CARD_INFO_EX *info,
                             const void *inp_buf, uint32_t inp_len) {
    if (!cfg || !info) return 1;
    if (info->struct_size != FC_CARD_INFO_SIZE && info->struct_size != 0) {
        salanga_log(cfg, 0, "GetCardInfoEx: unexpected struct size %u", info->struct_size);
    }

    char body[65536];
    build_get_card_body(body, sizeof(body), card, restaurant, unit_no, inp_buf, inp_len);

    char response[131072];
    if (!salanga_http_post(cfg, "/api/farcards/getcardinfoex", body, strlen(body), response, sizeof(response))) {
        return 1;
    }

    int result = 1;
    if (fc_xml_tag_result(response, "GetCardInfoEx", &result)) {
        if (result != 0) return 1;
        fc_fill_card_from_xml(info, response, cfg->xml_cp);
        return 0;
    }
    return 1;
}
