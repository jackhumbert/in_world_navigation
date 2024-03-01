#include <RED4ext/RED4ext.hpp>
#include "Addresses.hpp"

// 1.61 RVA: 0x204390
// 1.62 RVA: 0x204A90
// // @pattern 40 53 48 83 EC 30 33 C0 45 8A C8 4C 8D 44 24 20 48 89 44 24 20 89 44 24 28 48 8B DA 88 44 24 2C
// / @hash 1157708450
// constexpr uintptr_t LoadResRefAddr = LoadResRefAddr_Addr;

template <typename T>
RED4ext::UniversalRelocFunc<RED4ext::ResourceToken<T> *(*)(RED4ext::ResourcePath *,
                                                  RED4ext::SharedPtr<RED4ext::ResourceToken<T>> *wrapper, bool sync)>
    LoadResRef(1157708450);