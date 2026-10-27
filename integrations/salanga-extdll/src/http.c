#include "salanga_internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <winhttp.h>

#pragma comment(lib, "winhttp.lib")

static int parse_url(const char *url, wchar_t *host, size_t host_cap, INTERNET_PORT *port, int *https) {
    const char *p = url;
    *https = 0;
    *port = 80;
    if (_strnicmp(p, "https://", 8) == 0) {
        *https = 1;
        *port = 443;
        p += 8;
    } else if (_strnicmp(p, "http://", 7) == 0) {
        p += 7;
    }
    const char *slash = strchr(p, '/');
    size_t host_len = slash ? (size_t)(slash - p) : strlen(p);
    if (host_len + 1 > host_cap) return 0;
    char host_a[256];
    strncpy_s(host_a, sizeof(host_a), p, host_len);
    host_a[host_len] = '\0';
    char *colon = strchr(host_a, ':');
    if (colon) {
        *colon = '\0';
        *port = (INTERNET_PORT)atoi(colon + 1);
    }
    MultiByteToWideChar(CP_UTF8, 0, host_a, -1, host, (int)host_cap);
    return 1;
}

int salanga_http_post(SalangaConfig *cfg, const char *path,
                      const char *body, size_t body_len,
                      char *response, size_t response_cap) {
    if (!cfg || !path || !body || !response || response_cap < 2) return 0;

    wchar_t host[256];
    INTERNET_PORT port;
    int https;
    if (!parse_url(cfg->base_url, host, sizeof(host) / sizeof(host[0]), &port, &https)) {
        salanga_log(cfg, 0, "HTTP: bad BaseUrl %s", cfg->base_url);
        return 0;
    }

    wchar_t wpath[512];
    MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, 512);

    HINTERNET session = WinHttpOpen(L"SalangaExtDll/1.0",
                                    WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                                    WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!session) return 0;

    DWORD timeout_ms = (DWORD)cfg->timeout_sec * 1000u;
    WinHttpSetTimeouts(session, timeout_ms, timeout_ms, timeout_ms, timeout_ms);

    HINTERNET connect = WinHttpConnect(session, host, port, 0);
    if (!connect) {
        WinHttpCloseHandle(session);
        return 0;
    }

    DWORD flags = https ? WINHTTP_FLAG_SECURE : 0;
    HINTERNET request = WinHttpOpenRequest(connect, L"POST", wpath, NULL,
                                           WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, flags);
    if (!request) {
        WinHttpCloseHandle(connect);
        WinHttpCloseHandle(session);
        return 0;
    }

    wchar_t headers[512];
    swprintf_s(headers, 512,
               L"Content-Type: text/xml; charset=utf-8\r\nX-API-Key: %hs\r\n",
               cfg->api_key);

    BOOL ok = WinHttpSendRequest(request, headers, (DWORD)-1L,
                                 (LPVOID)body, (DWORD)body_len, (DWORD)body_len, 0);
    if (ok) ok = WinHttpReceiveResponse(request, NULL);

    size_t total = 0;
    response[0] = '\0';
    if (ok) {
        DWORD avail = 0;
        do {
            if (!WinHttpQueryDataAvailable(request, &avail) || avail == 0) break;
            if (total + avail + 1 >= response_cap) break;
            DWORD read = 0;
            if (!WinHttpReadData(request, response + total, avail, &read)) break;
            total += read;
            response[total] = '\0';
        } while (avail > 0);
    }

    WinHttpCloseHandle(request);
    WinHttpCloseHandle(connect);
    WinHttpCloseHandle(session);

    if (!ok || total == 0) {
        salanga_log(cfg, 0, "HTTP POST %s failed", path);
        return 0;
    }
    salanga_log(cfg, 3, "HTTP POST %s ok, %zu bytes", path, total);
    return 1;
}
