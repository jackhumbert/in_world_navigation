cmake_minimum_required(VERSION 3.24)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/deps/cyberpunk_cmake")

include(CyberpunkMod)

project(in_world_navigation VERSION 0.0.8)

configure_mod(
  NAME "In-World Navigation"
  SLUG ${PROJECT_NAME}
  AUTHOR "Jack Humbert"
  URL "https://github.com/jackhumbert/in_world_navigation"
  LICENSE "Licensed under the MIT license. See the license.md in the root project for details."
)

find_program(ZOLTAN_CLANG_EXE NAMES zoltan-clang.exe PATHS "${MOD_TOOLS_DIR}" CACHE)
find_program(REDSCRIPT_CLI_EXE NAMES redscript-cli.exe PATHS "${MOD_TOOLS_DIR}" CACHE)
find_program(CYBERPUNK_2077_EXE NAMES Cyberpunk2077.exe PATHS "${CYBERPUNK_2077_GAME_DIR}/bin/x64" CACHE DOC "Cyberpunk2077.exe Executable File")

find_package(Detours)
# find_package(RED4ext.SDK)
find_package(Spdlog)
find_package(ModSettings)

# add_subdirectory(src/red4ext)
configure_red4ext(src/red4ext)
configure_red4ext_addresses(Main.cpp Addresses.hpp)

target_link_libraries(${MOD_SLUG}.dll
  PUBLIC
    Detours
    spdlog
)

configure_redscript(src/redscript)
configure_archives(resources/packed/archive/pc/mod/in_world_navigation.archive)
configure_folder_file(readme.md)
configure_folder_file(license.md)
configure_uninstall()
configure_release(${MOD_SLUG}_${MOD_VERSION_STR}.zip)
configure_install()