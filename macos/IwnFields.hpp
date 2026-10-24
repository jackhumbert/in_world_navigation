#pragma once

// Live field offsets of gameuiMinimapContainerController (slot stride 0x28, base 0x218).
// The Windows fork header still names the old offsets. This header is included on macOS only.

#include <cstdint>

#include <RED4ext/Handle.hpp>

namespace IwnFields
{
constexpr std::uint32_t QuestMappin = 0x218;       // WeakHandle
constexpr std::uint32_t QuestMappinPoints = 0x228; // DynArray<Vector4>
constexpr std::uint32_t HasQuestMappin = 0x238;    // Bool byte
constexpr std::uint32_t PoiMappin = 0x240;         // WeakHandle
constexpr std::uint32_t PoiMappinPoints = 0x250;   // DynArray<Vector4>
constexpr std::uint32_t HasPoiMappin = 0x260;      // Bool byte
}

template <typename T>
inline RED4ext::WeakHandle<T>* IwnWeakAt(void* aObject, std::uint32_t aOffset)
{
    return reinterpret_cast<RED4ext::WeakHandle<T>*>(static_cast<std::uint8_t*>(aObject) + aOffset);
}
