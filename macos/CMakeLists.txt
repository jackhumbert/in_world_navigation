cmake_minimum_required(VERSION 3.21)
# arm64 build of In-World Navigation for the native macOS game. Windows builds keep the top-level CMakeLists.txt.

set(IWN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
find_package(Git QUIET)
set(_iwn_tag "")
if(GIT_FOUND)
    execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${IWN_DIR}" describe --tags --abbrev=0 --match "v[0-9]*"
                    OUTPUT_VARIABLE _iwn_tag OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
endif()
string(REGEX MATCH "^v?([0-9]+)\\.([0-9]+)\\.([0-9]+)" _iwn_ver "${_iwn_tag}")
if(_iwn_ver)
    set(IWN_VER_MAJOR ${CMAKE_MATCH_1})
    set(IWN_VER_MINOR ${CMAKE_MATCH_2})
    set(IWN_VER_PATCH ${CMAKE_MATCH_3})
else()
    message(WARNING "no v<major>.<minor>.<patch> tag found, using 0.1.22")
    set(IWN_VER_MAJOR 0)
    set(IWN_VER_MINOR 1)
    set(IWN_VER_PATCH 22)
endif()
project(in_world_navigation VERSION ${IWN_VER_MAJOR}.${IWN_VER_MINOR}.${IWN_VER_PATCH} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_ARCHITECTURES "arm64")

if(NOT APPLE)
    message(FATAL_ERROR "This target builds the macOS In-World Navigation dylib")
endif()

set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -undefined dynamic_lookup")

set(RED4EXT_SDK_DIR "${IWN_DIR}/../../RED4ext.SDK-macos" CACHE PATH "macOS RED4ext SDK checkout")
get_filename_component(RED4EXT_SDK_DIR "${RED4EXT_SDK_DIR}" ABSOLUTE)
set(SDK_INCLUDE "${RED4EXT_SDK_DIR}/include")
set(CODEWARE_DIR "${IWN_DIR}/../../cp2077-codeware" CACHE PATH "macOS Codeware checkout (its SDK-core address rows are reused)")
get_filename_component(CODEWARE_DIR "${CODEWARE_DIR}" ABSOLUTE)
if(NOT EXISTS "${SDK_INCLUDE}/RED4ext/Relocation-inl.hpp")
    message(FATAL_ERROR "no RED4ext SDK headers at ${SDK_INCLUDE} (set -DRED4EXT_SDK_DIR=...)")
endif()

add_compile_definitions(
    RED4EXT_PLATFORM_MACOS
    RED4EXT_HEADER_ONLY
    MOD_VERSION_STR="${PROJECT_VERSION}"
    MOD_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
    MOD_VERSION_MINOR=${PROJECT_VERSION_MINOR}
    MOD_VERSION_PATCH=${PROJECT_VERSION_PATCH}
)

get_filename_component(_iwn_root "${IWN_DIR}" ABSOLUTE)
add_compile_options("-ffile-prefix-map=${_iwn_root}=in_world_navigation"
                    "-ffile-prefix-map=${RED4EXT_SDK_DIR}=RED4ext.SDK-macos"
                    "-ffile-prefix-map=${CMAKE_BINARY_DIR}=build")

find_package(spdlog REQUIRED)
find_package(fmt REQUIRED)

# Generated SDK overlay: the Mac address table plus Codeware's macos/MacSdkRows.inc (SDK-core rows such as TTypedClass_IsEqual,
# the same rows the Let There Be Flight port uses) plus macos/IwnSdkRows.inc. An unknown hash goes to iwn_mac_trap_for_hash.
set(SDK_OVERLAY "${CMAKE_CURRENT_BINARY_DIR}/sdk-overlay")
set(SDK_RELOC "${SDK_INCLUDE}/RED4ext/Relocation-inl.hpp")
set(SDK_ROWS_INC "${CMAKE_CURRENT_SOURCE_DIR}/IwnSdkRows.inc")
file(READ "${SDK_RELOC}" SDK_RELOC_TEXT)
file(READ "${SDK_ROWS_INC}" SDK_ROWS_TEXT)
set(CW_ROWS_INC "${CODEWARE_DIR}/macos/MacSdkRows.inc")
if(NOT EXISTS "${CW_ROWS_INC}")
    message(FATAL_ERROR "no Codeware Mac rows at ${CW_ROWS_INC} (set -DCODEWARE_DIR=...)")
endif()
file(READ "${CW_ROWS_INC}" CW_ROWS_TEXT)
set(SDK_ROWS_MARKER "        { 4201325776, 0x109BAA8 },  // CGlobalFunction_ctor\n")
string(FIND "${SDK_RELOC_TEXT}" "${SDK_ROWS_MARKER}" SDK_ROWS_POS)
if(SDK_ROWS_POS EQUAL -1)
    message(FATAL_ERROR "the anchor row (CGlobalFunction_ctor) is not in ${SDK_RELOC}")
endif()
string(REPLACE "${SDK_ROWS_MARKER}" "${SDK_ROWS_MARKER}        // --- cp2077-codeware/macos/MacSdkRows.inc ---\n${CW_ROWS_TEXT}        // --- in_world_navigation/macos/IwnSdkRows.inc ---\n${SDK_ROWS_TEXT}" SDK_RELOC_TEXT "${SDK_RELOC_TEXT}")
set(SDK_TAIL_START "    // Address not found or placeholder - return a non-zero sentinel value")
set(SDK_TAIL_END "    return 0;\n#else\n    if constexpr (Detail::AddressResolverOverride<uint32_t>::value)")
string(FIND "${SDK_RELOC_TEXT}" "${SDK_TAIL_START}" SDK_TAIL_A)
string(FIND "${SDK_RELOC_TEXT}" "${SDK_TAIL_END}" SDK_TAIL_B)
if(SDK_TAIL_A EQUAL -1 OR SDK_TAIL_B EQUAL -1)
    message(FATAL_ERROR "the unknown-hash tail of Resolve was not found in ${SDK_RELOC}")
endif()
string(SUBSTRING "${SDK_RELOC_TEXT}" 0 ${SDK_TAIL_A} SDK_HEAD)
math(EXPR SDK_REST_FROM "${SDK_TAIL_B} + 14")
string(SUBSTRING "${SDK_RELOC_TEXT}" ${SDK_REST_FROM} -1 SDK_REST)
set(SDK_RELOC_TEXT "${SDK_HEAD}    // In-World Navigation: unknown hash logs once and returns a stub. Never returns 0.\n    return iwn_mac_trap_for_hash(aHash);\n${SDK_REST}")
set(SDK_DECL_MARKER "extern \"C\" uintptr_t tweakxl_class_vslot(uint32_t aByteOffset);\n")
string(FIND "${SDK_RELOC_TEXT}" "${SDK_DECL_MARKER}" SDK_DECL_POS)
if(SDK_DECL_POS EQUAL -1)
    message(FATAL_ERROR "the extern declaration anchor was not found in ${SDK_RELOC}")
endif()
string(REPLACE "${SDK_DECL_MARKER}" "${SDK_DECL_MARKER}extern \"C\" uintptr_t iwn_mac_trap_for_hash(uint32_t aHash);\n" SDK_RELOC_TEXT "${SDK_RELOC_TEXT}")
file(WRITE "${SDK_OVERLAY}/RED4ext/Relocation-inl.hpp" "${SDK_RELOC_TEXT}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SDK_RELOC}" "${SDK_ROWS_INC}")

# RedLib: copy the headers, then overlay Registrar.hpp (RunPending). Quoted includes must resolve inside this tree.
set(REDLIB_GEN "${CMAKE_CURRENT_BINARY_DIR}/redlib")
set(REDLIB_SRC "${IWN_DIR}/deps/red_lib/include")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_directory "${REDLIB_SRC}" "${REDLIB_GEN}")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/redlib/Red/TypeInfo/Registrar.hpp"
    "${REDLIB_GEN}/Red/TypeInfo/Registrar.hpp")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/redlib/Red/TypeInfo/Resolving.hpp"
    "${REDLIB_GEN}/Red/TypeInfo/Resolving.hpp")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/redlib/Red/TypeInfo/Macros/Definition.hpp"
    "${REDLIB_GEN}/Red/TypeInfo/Macros/Definition.hpp")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/redlib/Red/TypeInfo/Registrar.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/redlib/Red/TypeInfo/Resolving.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/redlib/Red/TypeInfo/Macros/Definition.hpp")

set(MOD_VERSION_STR "${PROJECT_VERSION}")
set(MOD_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(MOD_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(MOD_VERSION_PATCH ${PROJECT_VERSION_PATCH})
configure_file("${IWN_DIR}/src/redscript/Module.reds.in" "${CMAKE_CURRENT_BINARY_DIR}/Scripts/Module.reds" @ONLY)

set(SRC "${IWN_DIR}/src/red4ext")
set(IWN_SOURCES
    ${SRC}/Main.cpp
    ${SRC}/Utils.cpp
    ${SRC}/InWorldNavigation.cpp
    ${SRC}/Hooks/UpdateNavPath.cpp
    ${SRC}/stdafx.cpp
    MacShims.cpp
    MacVault.cpp
)

add_library(in_world_navigation SHARED ${IWN_SOURCES})
set_target_properties(in_world_navigation PROPERTIES OUTPUT_NAME "in_world_navigation" PREFIX "" SUFFIX ".dylib")

target_include_directories(in_world_navigation PRIVATE
    "${SDK_OVERLAY}"
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/support"
    "${SDK_INCLUDE}"
    "${SRC}"
    "${REDLIB_GEN}"
    "${IWN_DIR}/deps/red_lib/vendor"
)

target_link_libraries(in_world_navigation PRIVATE spdlog::spdlog fmt::fmt)
target_precompile_headers(in_world_navigation PRIVATE "${SRC}/stdafx.hpp")

target_compile_options(in_world_navigation PRIVATE
    -fexceptions
    -fms-extensions
    -Wno-deprecated-declarations
    -Wno-microsoft-template
    -Wno-invalid-offsetof
    -fvisibility=hidden
    -fvisibility-inlines-hidden
)

add_custom_command(TARGET in_world_navigation POST_BUILD
    COMMAND /bin/bash "${CMAKE_CURRENT_SOURCE_DIR}/fix-install-names.sh" "$<TARGET_FILE:in_world_navigation>"
    COMMAND /bin/bash "${CMAKE_CURRENT_SOURCE_DIR}/check-undefined.sh" "$<TARGET_FILE:in_world_navigation>"
    VERBATIM
)

message(STATUS "In-World Navigation ${PROJECT_VERSION} configured for macOS")
