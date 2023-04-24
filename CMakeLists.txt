cmake_minimum_required(VERSION 3.24)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/deps/cyberpunk_cmake")

include(CMakeDependentOption)

project(
  in_world_navigation
  DESCRIPTION "In-World Navigation"
  VERSION 0.0.8
  LANGUAGES CXX
  HOMEPAGE_URL "https://github.com/jackhumbert/in_world_navigation"
)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Customizable options
set(MOD_NAME ${PROJECT_DESCRIPTION})
set(MOD_SLUG ${PROJECT_NAME})
set(MOD_AUTHOR "Jack Humbert")
set(MOD_SOURCE_DIR "${PROJECT_SOURCE_DIR}")
set(MOD_URL ${PROJECT_HOMEPAGE_URL})
set(MOD_LICENSE "Licensed under the MIT license. See the license.md in the root project for details.")
set(MOD_REDSCRIPT_DIR "${PROJECT_SOURCE_DIR}/src/redscript")
set(MOD_TOOLS_DIR "${PROJECT_SOURCE_DIR}/tools")
set(MOD_GAME_DIR "${PROJECT_SOURCE_DIR}/game_dir")
set(MOD_ARCHIVES "${PROJECT_SOURCE_DIR}/resources/packed/archive/pc/mod/in_world_navigation.archive")

set(MOD_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(MOD_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(MOD_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(MOD_VERSION_STR "v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")

set(MOD_ZIP_FILE "${CMAKE_SOURCE_DIR}/${CMAKE_PROJECT_NAME}_${MOD_VERSION_STR}.zip" CACHE STRING "Location and name of release zip file")
set(CYBERPUNK_2077_GAME_DIR "C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077" CACHE STRING "Cyberpunk 2077 game directory")
set(CYBERPUNK_2077_REDSCRIPT_BACKUP "${CYBERPUNK_2077_GAME_DIR}/r6/cache/final.redscripts.bk" CACHE STRING "final.redscripts.bk file created by Redscript after running it for the first time")

set(MOD_RED4EXT_SDK_DIR "${PROJECT_SOURCE_DIR}/deps/red4ext.sdk")
set(MOD_RED4EXT_SOURCE_DIR "${PROJECT_SOURCE_DIR}/src/red4ext")
set(ZOLTAN_USER_SIGNATURES "${MOD_RED4EXT_SOURCE_DIR}/Main.cpp")
set(ZOLTAN_ADDRESSES_OUTPUT "${MOD_RED4EXT_SOURCE_DIR}/Addresses.hpp")

find_program(ZOLTAN_CLANG_EXE NAMES zoltan-clang.exe PATHS "${MOD_TOOLS_DIR}")
find_program(REDSCRIPT_CLI_EXE NAMES redscript-cli.exe PATHS "${MOD_TOOLS_DIR}")
find_program(CYBERPUNK_2077_EXE NAMES Cyberpunk2077.exe PATHS "${CYBERPUNK_2077_GAME_DIR}/bin/x64" DOC "Cyberpunk2077.exe Executable File")

find_package(Detours)
find_package(RED4ext.SDK)
find_package(Spdlog)
find_package(ModSettings)

include(CyberpunkMod)
add_subdirectory(src/red4ext)

include(Redscript)
include(Archives)
include(Release)
include(Install)