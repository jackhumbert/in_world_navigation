#include "MacShims.hpp"

#include <atomic>
#include <cstdarg>
#include <cstdio>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mutex>
#include <set>

#include <spdlog/spdlog.h>

namespace
{
int g_anchor = 0;
std::atomic<bool> g_trapCalled{false};
const RED4ext::Sdk* g_sdk = nullptr;
RED4ext::PluginHandle g_handle = nullptr;

std::mutex& LogLock()
{
    static std::mutex s_lock;
    return s_lock;
}

std::set<uint32_t>& TrappedHashes()
{
    static std::set<uint32_t> s_set;
    return s_set;
}

__attribute__((noinline)) uintptr_t iwn_mac_trap_stub()
{
    if (!g_trapCalled.exchange(true))
    {
        IwnMac::Log("[iwn] trap stub called (a function with no Mac address); it returns 0. Further calls are not logged.");
    }
    return 0;
}

const char* PluginPathC()
{
    Dl_info info{};
    if (dladdr(&g_anchor, &info) && info.dli_fname)
    {
        return info.dli_fname;
    }
    return nullptr;
}
}

extern "C" __attribute__((visibility("hidden"))) uintptr_t iwn_mac_trap_for_hash(uint32_t aHash)
{
    {
        std::scoped_lock lock(LogLock());
        if (TrappedHashes().insert(aHash).second)
        {
            std::fprintf(stderr, "[iwn] address hash %u has no Mac row: it resolves to the fail-safe trap stub (see macos/NOT_YET.md)\n",
                         aHash);
        }
    }
    return reinterpret_cast<uintptr_t>(&iwn_mac_trap_stub);
}

namespace IwnMac
{
uintptr_t ImageBase()
{
    static const uintptr_t base = []() -> uintptr_t {
        const uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; ++i)
        {
            const auto* header = reinterpret_cast<const mach_header_64*>(_dyld_get_image_header(i));
            if (header && header->filetype == MH_EXECUTE)
            {
                return reinterpret_cast<uintptr_t>(header);
            }
        }
        return reinterpret_cast<uintptr_t>(_dyld_get_image_header(0));
    }();
    return base;
}

bool IsTrap(uintptr_t aAddress)
{
    return aAddress == reinterpret_cast<uintptr_t>(&iwn_mac_trap_stub) || aAddress == 0;
}

std::filesystem::path PluginDir()
{
    const char* path = PluginPathC();
    return path ? std::filesystem::path(path).parent_path() : std::filesystem::path();
}

std::filesystem::path RootDir()
{
    // <root>/red4ext/plugins/in_world_navigation/<dylib>: three levels up from the plugin folder.
    return PluginDir().parent_path().parent_path().parent_path();
}

void Log(const char* aFormat, ...)
{
    char buffer[1024];
    va_list args;
    va_start(args, aFormat);
    std::vsnprintf(buffer, sizeof(buffer), aFormat, args);
    va_end(args);
    std::fprintf(stderr, "%s\n", buffer);
    if (spdlog::default_logger_raw())
    {
        spdlog::info("{}", buffer);
    }
}

void SetPlugin(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle)
{
    g_sdk = aSdk;
    g_handle = aHandle;
}

const RED4ext::Sdk* PluginSdk()
{
    return g_sdk;
}

RED4ext::PluginHandle PluginHandleValue()
{
    return g_handle;
}

bool TryAttach(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle, uintptr_t aTarget, void* aDetour, void** aOriginal,
               const char* aName)
{
    if (aOriginal)
    {
        *aOriginal = nullptr;
    }
    const auto rva = static_cast<unsigned long>(aTarget - ImageBase());
    if (IsTrap(aTarget))
    {
        Log("[iwn] hook %s SKIPPED (no Mac address)", aName);
        return false;
    }
    if (!aSdk || !aSdk->hooking || !aSdk->hooking->Attach)
    {
        Log("[iwn] hook %s rva=0x%lx SKIPPED (no hooking API)", aName, rva);
        return false;
    }
    if (!aSdk->hooking->Attach(aHandle, reinterpret_cast<void*>(aTarget), aDetour, aOriginal))
    {
        if (aOriginal)
        {
            *aOriginal = nullptr;
        }
        Log("[iwn] hook %s rva=0x%lx SKIPPED (attach refused)", aName, rva);
        return false;
    }
    if (aOriginal && *aOriginal == reinterpret_cast<void*>(aTarget))
    {
        *aOriginal = nullptr;
        Log("[iwn] hook %s rva=0x%lx SKIPPED (offset is not on the allowlist)", aName, rva);
        return false;
    }
    Log("[iwn] hook %s rva=0x%lx INSTALLED", aName, rva);
    return true;
}
}
