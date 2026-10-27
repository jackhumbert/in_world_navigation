#pragma once

// macOS layer for In-World Navigation. Windows code keeps the upstream paths; Apple calls here.

#include <cstdint>
#include <filesystem>

#include <RED4ext/Api/PluginHandle.hpp>
#include <RED4ext/Api/Sdk.hpp>

extern "C"
{
// An address hash with no Mac row: logs once and returns a stub that logs its first call and returns 0.
uintptr_t iwn_mac_trap_for_hash(uint32_t aHash);
}

namespace IwnMac
{
uintptr_t ImageBase();
bool IsTrap(uintptr_t aAddress);

std::filesystem::path PluginDir();
std::filesystem::path RootDir();

void Log(const char* aFormat, ...) __attribute__((format(printf, 1, 2)));

void SetPlugin(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle);
const RED4ext::Sdk* PluginSdk();
RED4ext::PluginHandle PluginHandleValue();

// One attach attempt. Logs INSTALLED, or SKIPPED when the attach does not take.
// *aOriginal is null unless the hook was installed.
bool TryAttach(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle, uintptr_t aTarget, void* aDetour,
               void** aOriginal, const char* aName);

void AttachUpdateNavPath(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle);
void DetachUpdateNavPath(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle);

bool VaultReady();
bool VaultSelfTest();
}
