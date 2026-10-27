#ifndef SALANGA_INTERNAL_H
#define SALANGA_INTERNAL_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>

#include "../include/farcards_types.h"

#define SALANGA_DLL_VERSION "1.0.0-gornaya-salanga"

typedef struct SalangaConfig {
    char base_url[512];
    char api_key[256];
    int timeout_sec;
    int log_level;
    int xml_cp;
} SalangaConfig;

void salanga_log(SalangaConfig *cfg, int level, const char *fmt, ...);
void salanga_config_load(SalangaConfig *cfg);

int salanga_http_post(SalangaConfig *cfg, const char *path,
                      const char *body, size_t body_len,
                      char *response, size_t response_cap);

int salanga_get_card_info_ex(SalangaConfig *cfg, int64_t card,
                             uint32_t restaurant, uint32_t unit_no,
                             FC_CARD_INFO_EX *info,
                             const void *inp_buf, uint32_t inp_len);

int salanga_transactions_ex(SalangaConfig *cfg, uint32_t count, void *list,
                          const void *inp_buf, uint32_t inp_len);

void salanga_find_by_qr(SalangaConfig *cfg, const char *qr_token,
                        FC_CB_FIND cb, void *back);

void fc_zero_card_info(FC_CARD_INFO_EX *info);
void fc_fill_card_from_xml(FC_CARD_INFO_EX *info, const char *xml, int xml_cp);

int fc_xml_attr_int(const char *xml, const char *tag, const char *attr, int64_t *out);
int fc_xml_attr_str(const char *xml, const char *tag, const char *attr, char *out, size_t out_cap);
int fc_xml_tag_result(const char *xml, const char *tag, int *result_out);

void fc_utf8_to_ansi(const char *utf8, char *out, size_t out_cap, int code_page);

#endif
