include(Red4ext)

target_link_libraries(${MOD_SLUG}.dll
  PUBLIC
    Detours
    RED4ext.SDK
    spdlog
)