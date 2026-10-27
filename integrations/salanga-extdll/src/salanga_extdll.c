#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "salanga_internal.h"

static SalangaConfig g_cfg;
static CRITICAL_SECTION g_lock;
static int g_inited;

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD reason, LPVOID reserved) {
    (void)hinst;
    (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinst);
        InitializeCriticalSection(&g_lock);
    } else if (reason == DLL_PROCESS_DETACH) {
        DeleteCriticalSection(&g_lock);
    }
    return TRUE;
}

__declspec(dllexport) void __stdcall Init(void) {
    EnterCriticalSection(&g_lock);
    if (!g_inited) {
        salanga_config_load(&g_cfg);
        g_inited = 1;
        salanga_log(&g_cfg, 1, "SalangaExtDll Init %s", SALANGA_DLL_VERSION);
    }
    LeaveCriticalSection(&g_lock);
}

__declspec(dllexport) void __stdcall Done(void) {
    EnterCriticalSection(&g_lock);
    salanga_log(&g_cfg, 1, "SalangaExtDll Done");
    g_inited = 0;
    LeaveCriticalSection(&g_lock);
}

__declspec(dllexport) int __stdcall GetCardInfoEx(
    int64_t card, uint32_t restaurant, uint32_t unit_no,
    void *info,
    void *inp_buf, uint32_t inp_len, uint16_t inp_kind,
    void **out_buf, uint32_t *out_len, uint16_t *out_kind) {
    (void)inp_kind;
    if (out_buf) *out_buf = NULL;
    if (out_len) *out_len = 0;
    if (out_kind) *out_kind = 0;
    if (!info) return 1;

    EnterCriticalSection(&g_lock);
    if (!g_inited) salanga_config_load(&g_cfg);
    int rc = salanga_get_card_info_ex(&g_cfg, card, restaurant, unit_no,
                                      (FC_CARD_INFO_EX *)info,
                                      inp_buf, inp_len);
    LeaveCriticalSection(&g_lock);
    return rc;
}

__declspec(dllexport) int __stdcall TransactionsEx(
    uint32_t count, void *list,
    void *inp_buf, uint32_t inp_len, uint16_t inp_kind,
    void **out_buf, uint32_t *out_len, uint16_t *out_kind) {
    (void)inp_kind;
    if (out_buf) *out_buf = NULL;
    if (out_len) *out_len = 0;
    if (out_kind) *out_kind = 0;
    if (!list || count == 0) return 1;

    EnterCriticalSection(&g_lock);
    if (!g_inited) salanga_config_load(&g_cfg);
    int rc = salanga_transactions_ex(&g_cfg, count, list, inp_buf, inp_len);
    LeaveCriticalSection(&g_lock);
    return rc;
}

__declspec(dllexport) void __stdcall FindAccountsByKind(
    int kind, char *find_text, void *cb_find, void *back) {
    if (kind != 3 || !find_text || !cb_find) return;
    EnterCriticalSection(&g_lock);
    if (!g_inited) salanga_config_load(&g_cfg);
    salanga_find_by_qr(&g_cfg, find_text, (FC_CB_FIND)cb_find, back);
    LeaveCriticalSection(&g_lock);
}

__declspec(dllexport) void __stdcall AnyInfo(
    void *inp_buf, uint32_t inp_len, void **out_buf, uint32_t *out_len) {
    if (out_buf) *out_buf = NULL;
    if (out_len) *out_len = 0;
    (void)inp_buf;
    (void)inp_len;
}
