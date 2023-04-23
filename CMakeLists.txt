cmake_minimum_required(VERSION 3.24)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(MOD_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH ${MOD_MODULE_PATH})

include(CMakeDependentOption)

project(
  in_world_navigation
  DESCRIPTION "In-World Navigation"
  VERSION 0.0.8
  LANGUAGES CXX
)

set(MOD_NAME ${PROJECT_DESCRIPTION})
set(MOD_SLUG ${PROJECT_NAME})
set(MOD_REDSCRIPT_DIR "${PROJECT_SOURCE_DIR}/src/redscript")
set(MOD_TOOLS_DIR "${PROJECT_SOURCE_DIR}/tools")
set(MOD_GAME_DIR "${PROJECT_SOURCE_DIR}/game_dir")
set(MOD_PREREQ_DIR "${PROJECT_SOURCE_DIR}/prereqs")
set(MOD_ZIP_FILE ${CMAKE_SOURCE_DIR}/${CMAKE_PROJECT_NAME}_v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.zip)

set(CYBERPUNK_GAME_DIR "C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077" CACHE STRING "Cyberpunk 2077 game directory")
set(CYBERPUNK_EXE "${CYBERPUNK_GAME_DIR}/bin/x64/Cyberpunk2077.exe")
set(CYBERPUNK_REDSCRIPT_BACKUP "${CYBERPUNK_GAME_DIR}/r6/cache/final.redscripts.bk")

set(ZOLTAN_USER_SIGNATURES "${PROJECT_SOURCE_DIR}/src/red4ext/Main.cpp")
set(ZOLTAN_USER_ADDRESSES "${PROJECT_SOURCE_DIR}/src/red4ext/Addresses.hpp")
set(ZOLTAN_CLANG_EXE "${MOD_TOOLS_DIR}/zoltan-clang.exe")
# set(ZOLTAN_CLANG_EXE "C:/Users/Jack/Documents/cyberpunk/zoltan/target/debug/zoltan-clang.exe")

add_custom_command(
  OUTPUT ${ZOLTAN_USER_ADDRESSES}
  DEPENDS ${ZOLTAN_USER_SIGNATURES}
  COMMAND ${ZOLTAN_CLANG_EXE}
  ARGS ${ZOLTAN_USER_SIGNATURES} ${CYBERPUNK_EXE} -f "std=c++20" -f "I${PROJECT_SOURCE_DIR}/deps/red4ext.sdk/include" --c-output "${ZOLTAN_USER_ADDRESSES}" --safe-addr
  COMMENT "Finding binary addresses of declared functions in Main.hpp"
)

add_custom_target(addresses DEPENDS ${ZOLTAN_USER_ADDRESSES})

add_subdirectory(src/redscript)

# Release

add_custom_target(release
  COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${MOD_ZIP_FILE}" --format=zip .
  WORKING_DIRECTORY ${MOD_GAME_DIR}
  DEPENDS ${CMAKE_PROJECT_NAME}
  COMMENT "Zipping game_dir for v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")