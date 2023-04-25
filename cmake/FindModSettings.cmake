message(STATUS "Configuring Mod Settings")
list(APPEND CMAKE_MESSAGE_INDENT "  ")
add_subdirectory(${PROJECT_SOURCE_DIR}/deps/mod_settings)
list(POP_BACK CMAKE_MESSAGE_INDENT)