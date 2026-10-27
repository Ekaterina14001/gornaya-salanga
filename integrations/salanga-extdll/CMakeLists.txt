cmake_minimum_required(VERSION 3.16)
project(SalangaExtDll C)

set(CMAKE_C_STANDARD 11)

add_library(SalangaExtDll SHARED
    src/salanga_extdll.c
    src/config.c
    src/http.c
    src/xml_fc.c
    src/card_info.c
    src/transactions.c
)

target_include_directories(SalangaExtDll PRIVATE include src)
target_link_libraries(SalangaExtDll PRIVATE winhttp)

if(MSVC)
    target_compile_options(SalangaExtDll PRIVATE /W4)
    target_link_options(SalangaExtDll PRIVATE "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/SalangaExtDll.def")
else()
    target_link_options(SalangaExtDll PRIVATE "-Wl,--def,${CMAKE_CURRENT_SOURCE_DIR}/SalangaExtDll.def")
endif()

set_target_properties(SalangaExtDll PROPERTIES OUTPUT_NAME "SalangaExtDll")

# FarCards 6.x — 32-bit DLL
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(WARNING "Build 32-bit (i686) for r_keeper FarCards: use -A Win32 or i686-w64-mingw32-gcc")
endif()
