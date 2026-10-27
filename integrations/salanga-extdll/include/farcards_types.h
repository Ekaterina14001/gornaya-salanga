#ifndef SALANGA_FARCARDS_TYPES_H
#define SALANGA_FARCARDS_TYPES_H

#include <stdint.h>

#define FC_CARD_INFO_SIZE 1164u
#define FC_TRANSACTION_SIZE 122u

#pragma pack(push, 1)

/* Extdll.txt — GetCardInfoEx, 1164 bytes */
typedef struct FC_CARD_INFO_EX {
    uint16_t struct_size;
    uint8_t deleted;
    uint8_t seize;
    uint8_t expired;
    uint8_t not_active;
    uint8_t need_confirm;
    uint8_t locked;
    char block_reason[256];
    char holder[40];
    int64_t holder_id;
    uint32_t account;
    uint32_t payer_type;
    uint16_t bonus_no;
    uint16_t discount_no;
    int64_t disc_limit_k;
    int64_t sum_available_k;
    int64_t sum2_k;
    int64_t sum3_k;
    int64_t sum4_k;
    int64_t sum5_k;
    int64_t sum6_k;
    int64_t sum7_k;
    int64_t sum8_k;
    char card_info[256];
    char screen_text[256];
    char printer_text[256];
} FC_CARD_INFO_EX;

/* Extdll.txt — one transaction, 122 bytes */
typedef struct FC_TRANSACTION_EX {
    uint16_t struct_size;
    int64_t card;
    int64_t holder_id;
    uint32_t account;
    uint8_t kind;
    int64_t summa_k;
    uint16_t restaurant;
    uint32_t cash_date;
    uint8_t unit_no;
    uint32_t check_no;
    int64_t vat_sum_a;
    uint16_t vat_prc_a;
    int64_t vat_sum_b;
    uint16_t vat_prc_b;
    int64_t vat_sum_c;
    uint16_t vat_prc_c;
    int64_t vat_sum_d;
    uint16_t vat_prc_d;
    int64_t vat_sum_e;
    uint16_t vat_prc_e;
    int64_t vat_sum_f;
    uint16_t vat_prc_f;
    int64_t vat_sum_g;
    uint16_t vat_prc_g;
    int64_t vat_sum_h;
    uint16_t vat_prc_h;
} FC_TRANSACTION_EX;

#pragma pack(pop)

#if defined(__cplusplus)
static_assert(sizeof(FC_CARD_INFO_EX) == FC_CARD_INFO_SIZE, "FC_CARD_INFO_EX size");
static_assert(sizeof(FC_TRANSACTION_EX) == FC_TRANSACTION_SIZE, "FC_TRANSACTION_EX size");
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(FC_CARD_INFO_EX) == FC_CARD_INFO_SIZE, "FC_CARD_INFO_EX size");
_Static_assert(sizeof(FC_TRANSACTION_EX) == FC_TRANSACTION_SIZE, "FC_TRANSACTION_EX size");
#endif

typedef void (__stdcall *FC_CB_FIND)(void *back, uint32_t account, int64_t card, const char *holder);

#endif
