#include "salanga_internal.h"

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

static void trim(char *s) {
    if (!s) return;
    size_t n = strlen(s);
    while (n > 0 && (s[n - 1] == '\r' || s[n - 1] == '\n' || s[n - 1] == ' ')) {
        s[--n] = '\0';
    }
    char *p = s;
    while (*p == ' ' || *p == '\t') p++;
    if (p != s) memmove(s, p, strlen(p) + 1);
}

static void read_ini_value(const char *path, const char *section, const char *key, char *out, size_t out_cap) {
    if (!out || out_cap == 0) return;
    out[0] = '\0';
    char tmp[1024];
    DWORD n = GetPrivateProfileStringA(section, key, "", tmp, (DWORD)sizeof(tmp), path);
    if (n == 0) return;
    strncpy_s(out, out_cap, tmp, _TRUNCATE);
    trim(out);
}

void salanga_config_load(SalangaConfig *cfg) {
    char dll_path[MAX_PATH];
    char ini_path[MAX_PATH];
    HMODULE mod = NULL;
    if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            (LPCSTR)&salanga_config_load, &mod)) {
        GetModuleFileNameA(NULL, dll_path, MAX_PATH);
    } else {
        GetModuleFileNameA(mod, dll_path, MAX_PATH);
    }
    strncpy_s(ini_path, sizeof(ini_path), dll_path, _TRUNCATE);
    char *slash = strrchr(ini_path, '\\');
    if (slash) strcpy_s(slash + 1, sizeof(ini_path) - (slash + 1 - ini_path), "SalangaExtDll.ini");

    memset(cfg, 0, sizeof(*cfg));
    cfg->timeout_sec = 30;
    cfg->log_level = 2;
    cfg->xml_cp = 1251;

    read_ini_value(ini_path, "API", "BaseUrl", cfg->base_url, sizeof(cfg->base_url));
    read_ini_value(ini_path, "API", "ApiKey", cfg->api_key, sizeof(cfg->api_key));

    char buf[32];
    read_ini_value(ini_path, "API", "TimeoutSec", buf, sizeof(buf));
    if (buf[0]) cfg->timeout_sec = atoi(buf);
    read_ini_value(ini_path, "API", "Log", buf, sizeof(buf));
    if (buf[0]) cfg->log_level = atoi(buf);
    read_ini_value(ini_path, "API", "XMLCP", buf, sizeof(buf));
    if (buf[0]) cfg->xml_cp = atoi(buf);

    if (cfg->base_url[0] == '\0') {
        strncpy_s(cfg->base_url, sizeof(cfg->base_url), "https://admin.salanga.ru", _TRUNCATE);
    }
    size_t len = strlen(cfg->base_url);
    while (len > 0 && cfg->base_url[len - 1] == '/') {
        cfg->base_url[--len] = '\0';
    }
}

void salanga_log(SalangaConfig *cfg, int level, const char *fmt, ...) {
    if (!cfg || level > cfg->log_level) return;
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    char *slash = strrchr(path, '\\');
    if (slash) *(slash + 1) = '\0';
    strcat_s(path, sizeof(path), "SalangaExtDll.log");

    FILE *f = NULL;
    if (fopen_s(&f, path, "a") != 0 || !f) return;
    SYSTEMTIME st;
    GetLocalTime(&st);
    fprintf(f, "%04u-%02u-%02u %02u:%02u:%02u ",
            st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
    va_list ap;
    va_start(ap, fmt);
    vfprintf(f, fmt, ap);
    va_end(ap);
    fputc('\n', f);
    fclose(f);
}
