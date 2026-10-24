#include <RED4ext/InstanceType.hpp>
#include <RED4ext/RED4ext.hpp>
#include <RED4ext/RTTITypes.hpp>
#include <RED4ext/Scripting/IScriptable.hpp>
#include <iostream>

#include "Utils.hpp"
#include "stdafx.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/mappins/PointOfInterestMappin.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/mappins/QuestMappin.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>

#include "Addresses.hpp"
#ifndef __APPLE__
#include "LoadResRef.hpp"
#endif
#include <ArchiveXL.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/FxResource.hpp>
#include <RED4ext/Scripting/Natives/Generated/red/ResourceReferenceScriptToken.hpp>
#include <RedLib.hpp>
#ifndef __APPLE__
#include <Registrar.hpp>
#endif
#include "InWorldNavigation.hpp"
#ifndef __APPLE__
#include <CyberpunkMod.hpp>
#endif
#ifdef __APPLE__
#include <atomic>
#include "IwnFields.hpp"
#include "MacShims.hpp"
#endif


void CastResRefToFxResource(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                            RED4ext::game::FxResource *aOut, int64_t a4) {
  RED4ext::red::ResourceReferenceScriptToken value;
  RED4ext::GetParameter(aFrame, &value);
  aFrame->code++; // skip ParamEnd

  // auto resHandle = new RED4ext::ResourceHandle<RED4ext::world::Effect>();
  // if (value.resource.path.hash != 0) {
  // RED4ext::CName fc = value.resource.path.hash;
  // value.resource.Resolve();
  // LoadResRef<RED4ext::world::Effect>((uint64_t *)&fc, resHandle, true);
  //}

  if (aOut) {
    aOut->effect.path = value.resource.path;
    // aOut->effect.Resolve();
  }
}

void GetQuestMappin(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                    RED4ext::Handle<RED4ext::game::mappins::QuestMappin> *aOut, int64_t a4) {
  aFrame->code++; // skip ParamEnd

  if (aOut) {
    auto ms = reinterpret_cast<RED4ext::game::ui::MinimapContainerController *>(aContext);
#ifdef __APPLE__
    auto quest = IwnWeakAt<RED4ext::game::mappins::QuestMappin>(ms, IwnFields::QuestMappin);
    if (quest && !quest->Expired()) {
      *aOut = quest->Lock();
    } else {
      *aOut = NULL;
    }
#else
    if (!ms->questMappin.Expired()) {
      *aOut = ms->questMappin.Lock();
    } else {
      *aOut = NULL;
    }
#endif
  }
}

void GetPOIMappin(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                  RED4ext::Handle<RED4ext::game::mappins::IMappin> *aOut, int64_t a4) {
  aFrame->code++; // skip ParamEnd

  if (aOut) {
    auto ms = reinterpret_cast<RED4ext::game::ui::MinimapContainerController *>(aContext);
#ifdef __APPLE__
    auto poi = IwnWeakAt<RED4ext::game::mappins::IMappin>(ms, IwnFields::PoiMappin);
    if (poi && !poi->Expired()) {
      *aOut = poi->Lock();
    } else {
      *aOut = NULL;
    }
#else
    if (!ms->poiMappin.Expired()) {
      *aOut = ms->poiMappin.Lock();
    } else {
      *aOut = NULL;
    }
#endif
  }
}


#ifndef __APPLE__
// Input Loader is optional: resolve its exported Add() at runtime instead of linking against it, so the
// plugin still loads (without the toggle keybind) when Input Loader is not installed.
using InputLoaderAdd_t = void (*)(RED4ext::PluginHandle, const wchar_t *);

void RegisterInputs(RED4ext::PluginHandle aHandle) {
  auto module = GetModuleHandleW(L"input_loader");
  if (!module) {
    auto pluginDir = Utils::GetRootDir() / "red4ext" / "plugins" / "input_loader";
    SetDllDirectoryW(pluginDir.c_str());
    module = LoadLibraryW(L"input_loader");
  }
  if (!module) {
    spdlog::warn("Input Loader not found - the toggle keybind will not be available");
    return;
  }
  auto add = reinterpret_cast<InputLoaderAdd_t>(GetProcAddress(module, "Add"));
  if (!add) {
    spdlog::warn("Input Loader found, but it does not export Add() - the toggle keybind will not be available");
    return;
  }
  add(aHandle, L"inputs.xml");
  spdlog::info("Registered inputs.xml with Input Loader");
}
#endif // macOS: Input Loader is a Windows plugin; the arrows are toggled from the settings page there

RED4EXT_C_EXPORT void RED4EXT_CALL RegisterTypes() {

}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes() {
  spdlog::info("Registering members & functions");

  auto rtti = RED4ext::CRTTISystem::Get();

  // expose the minimap members to the scripts
#ifdef __APPLE__
  auto ms = rtti->GetClass("gameuiMinimapContainerController");
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "questPoints", nullptr, IwnFields::QuestMappinPoints));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasQuestMappin", nullptr, IwnFields::HasQuestMappin));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "poiPoints", nullptr, IwnFields::PoiMappinPoints));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasPoiMappin", nullptr, IwnFields::HasPoiMappin));
#else
  auto ms = rtti->GetClass("gameuiMinimapContainerController");
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "questPoints", nullptr, offsetof(RED4ext::game::ui::MinimapContainerController, questMappinPoints)));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasQuestMappin", nullptr, offsetof(RED4ext::game::ui::MinimapContainerController, hasQuestMappin)));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "poiPoints", nullptr, offsetof(RED4ext::game::ui::MinimapContainerController, poiMappinPoints)));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasPoiMappin", nullptr, offsetof(RED4ext::game::ui::MinimapContainerController, hasPoiMappin)));
#endif

  auto getQuestMappin =
      RED4ext::CClassFunction::Create(ms, "GetQuestMappin", "GetQuestMappin", &GetQuestMappin, {.isNative = true});
  ms->RegisterFunction(getQuestMappin);
  auto getPOIMappin =
      RED4ext::CClassFunction::Create(ms, "GetPOIMappin", "GetPOIMappin", &GetPOIMappin, {.isNative = true});
  ms->RegisterFunction(getPOIMappin);

  auto f =
      RED4ext::CGlobalFunction::Create("Cast;ResRef;FxResource", "Cast;ResRef;FxResource", &CastResRefToFxResource);
  rtti->RegisterFunction(f);
}

#ifdef __APPLE__
static std::atomic<bool> s_iwnLoaded{false};

RED4EXT_C_EXPORT void RED4EXT_CALL iwn_registerNatives() {
  static std::atomic<bool> s_once{false};
  if (s_once.exchange(true)) {
    IwnMac::Log("[iwn] iwn_registerNatives: already ran");
    return;
  }
  if (!s_iwnLoaded.load() || !IwnMac::PluginSdk()) {
    IwnMac::Log("[iwn] iwn_registerNatives: Main(Load) did not finish: nothing registered");
    return;
  }
  if (!RED4ext::CRTTISystem::Get()) {
    IwnMac::Log("[iwn] iwn_registerNatives: no RTTI system yet: nothing registered");
    return;
  }

  const bool vaultOk = IwnMac::VaultSelfTest();
  IwnMac::Log("[iwn] iwn_registerNatives vault self-test: %s", vaultOk ? "ok" : "FAILED");
  IwnMac::Log("[iwn] iwn_registerNatives RedLib queued: %zu register, %zu describe",
              Red::TypeInfoRegistrar::PendingRegisterCount(), Red::TypeInfoRegistrar::PendingDescribeCount());
  Red::TypeInfoRegistrar::RunPending();
  PostRegisterTypes();

  std::error_code archiveError;
  const auto macArchive = Utils::GetRootDir() / "archive" / "Mac" / "mod" / "in_world_navigation.archive";
  if (std::filesystem::is_regular_file(macArchive, archiveError)) {
    IwnMac::Log("[iwn] archive is in archive/Mac/mod (ArchiveXL mounts it; RegisterArchive skipped)");
  } else {
    const bool registered = ArchiveXL::RegisterArchive(IwnMac::PluginHandleValue(), "in_world_navigation.archive");
    IwnMac::Log("[iwn] RegisterArchive %s", registered ? "ok" : "failed");
  }
  IwnMac::Log("[iwn] iwn_registerNatives done (RedLib left %zu / %zu)",
              Red::TypeInfoRegistrar::PendingRegisterCount(), Red::TypeInfoRegistrar::PendingDescribeCount());
}
#endif
RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::PluginHandle aHandle, RED4ext::EMainReason aReason,
                                        const RED4ext::Sdk *aSdk) {
  switch (aReason) {
  case RED4ext::EMainReason::Load: {
    // Attach hooks, register RTTI types, add custom states or initalize your
    // application. DO NOT try to access the game's memory at this point, it
    // is not initalized yet.

    Utils::CreateLogger();
    spdlog::info("Starting up In-World Navigation " MOD_VERSION_STR);

#ifdef __APPLE__
    spdlog::info("[iwn] old script folder and archive cleanup skipped; natives register from iwn_registerNatives");
    IwnMac::SetPlugin(aSdk, aHandle);
    IwnMac::AttachUpdateNavPath(aSdk, aHandle);
    s_iwnLoaded.store(true);
#else
    auto scriptsFolder = Utils::GetRootDir() / "r6" / "scripts" / "in_world_navigation";
    if (std::filesystem::exists(scriptsFolder)) {
      spdlog::info("Deleting old scripts folder");
      std::filesystem::remove_all(scriptsFolder);
    }
    auto archive = Utils::GetRootDir() / "archive" / "pc" / "mod" / "in_world_navigation.archive";
    if (std::filesystem::exists(archive)) {
      spdlog::info("Deleting old archive");
      std::filesystem::remove_all(archive);
    }

    RED4ext::RTTIRegistrator::Add(RegisterTypes, PostRegisterTypes);
    Red::TypeInfoRegistrar::RegisterDiscovered();

    aSdk->scripts->Add(aHandle, L"packed.reds");
    aSdk->scripts->Add(aHandle, L"module.reds");
    RegisterInputs(aHandle);
    ArchiveXL::RegisterArchive(aHandle, "in_world_navigation.archive");
    ModModuleFactory::GetInstance().Load(aSdk, aHandle);
#endif

    break;
  }
  case RED4ext::EMainReason::Unload: {
    // Free memory, detach hooks.
    // The game's memory is already freed, to not try to do anything with it.

    spdlog::info("Shutting down");
#ifdef __APPLE__
    IwnMac::DetachUpdateNavPath(aSdk, aHandle);
#else
    ModModuleFactory::GetInstance().Unload(aSdk, aHandle);
#endif
    spdlog::shutdown();
    break;
  }
  }

  return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo *aInfo) {
  aInfo->name = L"In-World Navigation";
  aInfo->author = L"Jack Humbert";
  aInfo->version = RED4EXT_SEMVER(MOD_VERSION_MAJOR, MOD_VERSION_MINOR, MOD_VERSION_PATCH);
  // aInfo->runtime = RED4EXT_V0_FILEVER(GAME_VERSION_MAJOR, GAME_VERSION_MINOR, GAME_VERSION_BUILD, GAME_VERSION_PRIVATE);
  aInfo->runtime = RED4EXT_RUNTIME_INDEPENDENT;
  aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports() { return RED4EXT_API_VERSION_LATEST; }
