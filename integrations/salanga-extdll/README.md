# SalangaExtDll — FarCards Type=1 для «Горная Саланга»

Собственная DLL по [Extdll.txt](../../docs/farcards/Extdll.txt) (FarCards 6.xx): эмулирует CardServ и ходит в наш backend по HTTP (те же XML-методы, что ExtDllHTTP).

## Режим FarCards

В `Farcards.ini`:

```ini
[FarServer]
Type=1
DLL=SalangaExtDll
Log=3
XMLCP=1251
```

Запуск FarCards для отладки: `FarCards.exe /desktop` (из комплекта FC 6.05).

## Экспорты (stdcall)

| Функция | Назначение |
|---------|------------|
| **GetCardInfoEx** | Карта → баланс, лимит оплаты, ФИО (структура 1164 байт) |
| **TransactionsEx** | Списание/начисление бонусов по чеку (атомарно) |
| **Init** / **Done** | Загрузка `SalangaExtDll.ini`, лог |
| **FindAccountsByKind** | Kind=3 — поиск по QR (JWT из приложения) |
| **AnyInfo** | Заглушка |

## Конфиг `SalangaExtDll.ini`

Рядом с DLL (см. `SalangaExtDll.ini.example`):

- **BaseUrl** — `https://admin.salanga.ru`
- **ApiKey** — ключ POS системы **RKeeper** (`X-API-Key`)
- **Log** — 0…3 → файл `SalangaExtDll.log` в каталоге FarCards
- **XMLCP** — кодовая страница строк в структурах (1251 для DOS-кассы)

## API backend

| Метод | Путь |
|-------|------|
| POST | `/api/farcards/getcardinfoex` |
| POST | `/api/farcards/transactionsex` |
| POST | `/api/farcards/findbyqr` |

Код карты = **participant_id** (UDS). QR = JWT из мобильного приложения.

## Локальная проверка (FC 6.05)

1. Распакуйте `FC 6.05.7z` (в репозитории можно держать в `integrations/farcards-6.05/`, каталог в `.gitignore`).
2. Соберите `SalangaExtDll.dll` (Win32) и положите рядом с `FarCards.exe`.
3. Скопируйте `SalangaExtDll.ini` из `SalangaExtDll.ini.example`, укажите **ApiKey** RKeeper.
4. В `Farcards.ini` задайте `Type=1`, `DLL=SalangaExtDll` (см. `Farcards.ini.example`).
5. Запуск: `FarCards.exe /desktop` — отладочный UI CardServ.

## Сборка

**Важно:** r_keeper / FarCards обычно грузят **32-bit** DLL.

### PowerShell (рекомендуется)

```powershell
integrations/salanga-extdll/build.ps1
```

### Visual Studio (x86)

```bat
cmake -S integrations/salanga-extdll -B build/salanga-extdll -A Win32
cmake --build build/salanga-extdll --config Release
```

### MinGW w64 i686

```bat
i686-w64-mingw32-gcc -shared -o SalangaExtDll.dll ^
  src/*.c -Iinclude -Isrc -lwinhttp -DSalangaExtDll_EXPORTS ^
  -Wl,--def,SalangaExtDll.def -O2 -s
```

## Сопоставление с документацией

- Структуры **1164** / **122** байт — `#pragma pack(1)` в `include/farcards_types.h`.
- Возврат **0** — успех, **1** — карта/чек не обработан (как Extdll.txt).
- `TransactionsEx`: либо все транзакции, либо ошибка (backend + idempotency по чеку).
- HTTP XML — по [описанию протокола FarCards](https://docs.restera.com/fortranslate2/description-of-http-protocol-for-farcards-97026049.html); наш API упрощён, но совместим с текущим Go-сервисом.

## Документы в репозитории

- `docs/farcards/farcards.txt` — режимы FarCards (Type 0 / 1)
- `docs/farcards/Extdll.txt` — контракт DLL
