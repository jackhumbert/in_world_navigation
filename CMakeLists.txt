cmake_minimum_required(VERSION 3.24)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CMakeDependentOption)

project(
  in_world_navigation
  DESCRIPTION "In-World Navigation"
  VERSION 0.0.8
  LANGUAGES CXX
)

set(MOD_TOOLS_DIR "${PROJECT_SOURCE_DIR}/tools")
set(MOD_GAME_DIR "${PROJECT_SOURCE_DIR}/game_dir")

set(CYBERPUNK_2077_GAME_DIR "C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077" CACHE STRING "Cyberpunk 2077 game directory")

set(ZOLTAN_USER_SIGNATURES "${PROJECT_SOURCE_DIR}/src/red4ext/Main.cpp")
set(ZOLTAN_USER_ADDRESSES "${PROJECT_SOURCE_DIR}/src/red4ext/Addresses.hpp")

add_custom_command(
  OUTPUT ${ZOLTAN_USER_ADDRESSES}
  DEPENDS ${ZOLTAN_USER_SIGNATURES}
  COMMAND ${MOD_TOOLS_DIR}/zoltan-clang.exe
  # COMMAND "C:/Users/Jack/Documents/cyberpunk/zoltan/target/debug/zoltan-clang.exe"
  ARGS ${ZOLTAN_USER_SIGNATURES} "${CYBERPUNK_2077_GAME_DIR}/bin/x64/Cyberpunk2077.exe" -f "std=c++20" -f "I${PROJECT_SOURCE_DIR}/deps/red4ext.sdk/include" --c-output "${ZOLTAN_USER_ADDRESSES}" --safe-addr
  COMMENT "Finding binary addresses of declared functions in Main.hpp"
)

add_custom_target(addresses DEPENDS ${ZOLTAN_USER_ADDRESSES})

# Release

set(MOD_ZIP_FILE ${CMAKE_SOURCE_DIR}/${CMAKE_PROJECT_NAME}_v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.zip)

add_custom_target(release
  COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${MOD_ZIP_FILE}" --format=zip .
  WORKING_DIRECTORY ${MOD_GAME_DIR}
  DEPENDS ${CMAKE_PROJECT_NAME}
  COMMENT "Zipping game_dir for v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")