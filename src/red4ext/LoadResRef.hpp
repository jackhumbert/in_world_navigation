#include <RED4ext/RED4ext.hpp>
#include "Addresses.hpp"

// 1.61 RVA: 0x204390
// 1.62 RVA: 0x204A90
/// @pattern 48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 60 41 0F B6 D8 48 8B FA 48 8B F1 48 C7 44 24 20 00 00
constexpr uintptr_t LoadResRefAddr = LoadResRefAddr_Addr;

template <typename T>
RED4ext::RelocFunc<RED4ext::ResourceToken<T> *(*)(RED4ext::ResourcePath *,
                                                  RED4ext::SharedPtr<RED4ext::ResourceToken<T>> *wrapper, bool sync)>
    LoadResRef(LoadResRefAddr);