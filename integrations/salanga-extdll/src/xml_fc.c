#include "salanga_internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *find_tag(const char *xml, const char *tag) {
    char open[64];
    sprintf_s(open, sizeof(open), "<%s", tag);
    const char *p = strstr(xml, open);
    if (!p) {
        sprintf_s(open, sizeof(open), "<%s>", tag);
        p = strstr(xml, open);
    }
    return p;
}

static int read_attr_int64(const char *tag_start, const char *attr, int64_t *out) {
    if (!tag_start || !attr || !out) return 0;
    char pattern[64];
    sprintf_s(pattern, sizeof(pattern), "%s=\"", attr);
    const char *p = strstr(tag_start, pattern);
    if (!p) return 0;
    p += strlen(pattern);
    *out = _strtoi64(p, NULL, 10);
    return 1;
}

static int read_attr_str(const char *tag_start, const char *attr, char *out, size_t out_cap) {
    if (!tag_start || !attr || !out || out_cap == 0) return 0;
    char pattern[64];
    sprintf_s(pattern, sizeof(pattern), "%s=\"", attr);
    const char *p = strstr(tag_start, pattern);
    if (!p) return 0;
    p += strlen(pattern);
    const char *end = strchr(p, '"');
    if (!end) return 0;
    size_t len = (size_t)(end - p);
    if (len >= out_cap) len = out_cap - 1;
    memcpy(out, p, len);
    out[len] = '\0';
    return 1;
}

int fc_xml_tag_result(const char *xml, const char *tag, int *result_out) {
    const char *t = find_tag(xml, tag);
    if (!t) return 0;
    int64_t v = 1;
    if (read_attr_int64(t, "Result", &v)) {
        if (result_out) *result_out = (int)v;
        return 1;
    }
    return 0;
}

int fc_xml_attr_int(const char *xml, const char *tag, const char *attr, int64_t *out) {
    const char *t = find_tag(xml, tag);
    if (!t) return 0;
    return read_attr_int64(t, attr, out);
}

int fc_xml_attr_str(const char *xml, const char *tag, const char *attr, char *out, size_t out_cap) {
    const char *t = find_tag(xml, tag);
    if (!t) return 0;
    return read_attr_str(t, attr, out, out_cap);
}

void fc_utf8_to_ansi(const char *utf8, char *out, size_t out_cap, int code_page) {
    if (!out || out_cap == 0) return;
    out[0] = '\0';
    if (!utf8 || !utf8[0]) return;
    wchar_t wbuf[512];
    int wlen = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, wbuf, 512);
    if (wlen <= 0) {
        strncpy_s(out, out_cap, utf8, _TRUNCATE);
        return;
    }
    WideCharToMultiByte(code_page, 0, wbuf, -1, out, (int)out_cap, NULL, NULL);
}

void fc_zero_card_info(FC_CARD_INFO_EX *info) {
    if (!info) return;
    uint16_t sz = info->struct_size;
    memset(info, 0, sizeof(*info));
    info->struct_size = sz ? sz : FC_CARD_INFO_SIZE;
}

void fc_fill_card_from_xml(FC_CARD_INFO_EX *info, const char *xml, int xml_cp) {
    if (!info || !xml) return;
    fc_zero_card_info(info);

    const char *t = find_tag(xml, "GetCardInfoEx");
    if (!t) return;

    int64_t v;
    char utf8[512];

    if (read_attr_int64(t, "Locked", &v) && v) info->locked = 1;
    if (read_attr_int64(t, "Deleted", &v) && v) info->deleted = 1;
    if (read_attr_int64(t, "Seize", &v) && v) info->seize = 1;

    if (read_attr_int64(t, "Account", &v)) info->account = (uint32_t)v;
    if (read_attr_int64(t, "CardCode", &v)) {
        info->holder_id = v;
        if (info->account == 0) info->account = (uint32_t)v;
    }
    if (read_attr_int64(t, "Bonus", &v)) info->bonus_no = (uint16_t)v;
    if (read_attr_int64(t, "Discount", &v)) info->discount_no = (uint16_t)v;
    if (read_attr_int64(t, "Summa", &v)) info->sum_available_k = v;
    if (read_attr_int64(t, "DiscLimit", &v)) info->disc_limit_k = v;
    if (read_attr_int64(t, "Sum2", &v)) info->sum2_k = v;

    if (read_attr_str(t, "Holder", utf8, sizeof(utf8))) {
        fc_utf8_to_ansi(utf8, info->holder, sizeof(info->holder), xml_cp);
    }
    if (read_attr_str(t, "ScrMessage", utf8, sizeof(utf8))) {
        fc_utf8_to_ansi(utf8, info->screen_text, sizeof(info->screen_text), xml_cp);
    } else if (read_attr_str(t, "DopInfo", utf8, sizeof(utf8))) {
        fc_utf8_to_ansi(utf8, info->card_info, sizeof(info->card_info), xml_cp);
    }
    if (read_attr_str(t, "WhyLock", utf8, sizeof(utf8))) {
        fc_utf8_to_ansi(utf8, info->block_reason, sizeof(info->block_reason), xml_cp);
    }
    if (read_attr_str(t, "PrnMessage", utf8, sizeof(utf8))) {
        fc_utf8_to_ansi(utf8, info->printer_text, sizeof(info->printer_text), xml_cp);
    }

    if (info->screen_text[0] == '\0' && info->sum2_k > 0) {
        sprintf_s(info->screen_text, sizeof(info->screen_text),
                  "Bonus: %lld.%02lld",
                  (long long)(info->sum2_k / 100), (long long)(info->sum2_k % 100));
    }
}
