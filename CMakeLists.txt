cmake_minimum_required(VERSION 3.24)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/deps/cpcmake")

include(CMakeDependentOption)

project(
  in_world_navigation
  DESCRIPTION "In-World Navigation"
  VERSION 0.0.8
  LANGUAGES CXX
)

# Customizable options
set(MOD_NAME ${PROJECT_DESCRIPTION})
set(MOD_SLUG ${PROJECT_NAME})
set(MOD_AUTHOR "Jack Humbert")
set(MOD_URL "https://github.com/jackhumbert/in_world_navigation")
set(MOD_LICENSE "Licensed under the MIT license. See the license.md in the root project for details.")
set(MOD_REDSCRIPT_DIR "${PROJECT_SOURCE_DIR}/src/redscript")
set(MOD_TOOLS_DIR "${PROJECT_SOURCE_DIR}/tools")
set(MOD_GAME_DIR "${PROJECT_SOURCE_DIR}/game_dir")
set(MOD_PREREQ_DIR "${PROJECT_SOURCE_DIR}/prereqs")
set(MOD_ARCHIVES "${PROJECT_SOURCE_DIR}/resources/packed/archive/pc/mod/in_world_navigation.archive")

set(MOD_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(MOD_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(MOD_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(MOD_VERSION_STR "v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")

set(MOD_ZIP_FILE "${CMAKE_SOURCE_DIR}/${CMAKE_PROJECT_NAME}_${MOD_VERSION_STR}.zip" CACHE STRING "Location and name of zip file")
set(CYBERPUNK_2077_GAME_DIR "C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077" CACHE STRING "Cyberpunk 2077 game directory")
set(CYBERPUNK_2077_EXE "${CYBERPUNK_2077_GAME_DIR}/bin/x64/Cyberpunk2077.exe")
set(CYBERPUNK_2077_REDSCRIPT_BACKUP "${CYBERPUNK_2077_GAME_DIR}/r6/cache/final.redscripts.bk")

set(MOD_RED4EXT_SDK_DIR "${PROJECT_SOURCE_DIR}/deps/red4ext.sdk")
set(MOD_RED4EXT_SOURCE_DIR "${PROJECT_SOURCE_DIR}/src/red4ext")
set(ZOLTAN_USER_SIGNATURES "${MOD_RED4EXT_SOURCE_DIR}/Main.cpp")
set(ZOLTAN_ADDRESSES_OUTPUT "${MOD_RED4EXT_SOURCE_DIR}/Addresses.hpp")
set(ZOLTAN_CLANG_EXE "${MOD_TOOLS_DIR}/zoltan-clang.exe")
# set(ZOLTAN_CLANG_EXE "C:/Users/Jack/Documents/cyberpunk/zoltan/target/debug/zoltan-clang.exe")

find_package(Detours)
find_package(RED4ext.SDK)
find_package(Spdlog)

add_subdirectory(src/red4ext)

target_link_libraries(${MOD_SLUG}.dll
  PUBLIC
    Detours
    RED4ext.SDK
    spdlog
)

add_subdirectory(src/redscript)
include(Archives)
include(Release)

add_custom_target(${MOD_SLUG} DEPENDS ${MOD_SLUG}.dll archives redscript)