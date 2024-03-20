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
#include "LoadResRef.hpp"
#include <ArchiveXL.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/FxResource.hpp>
#include <RED4ext/Scripting/Natives/Generated/red/ResourceReferenceScriptToken.hpp>
#include <RedLib.hpp>
#include <Registrar.hpp>
#include "InWorldNavigation.hpp"
#include <CyberpunkMod.hpp>


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
    if (!ms->questMappin.Expired()) {
      *aOut = ms->questMappin.Lock();
    } else {
      *aOut = NULL;
    }
  }
}

void GetPOIMappin(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                  RED4ext::Handle<RED4ext::game::mappins::IMappin> *aOut, int64_t a4) {
  aFrame->code++; // skip ParamEnd

  if (aOut) {
    auto ms = reinterpret_cast<RED4ext::game::ui::MinimapContainerController *>(aContext);
    if (!ms->poiMappin.Expired()) {
      *aOut = ms->poiMappin.Lock();
    } else {
      *aOut = NULL;
    }
  }
}


RED4EXT_C_EXPORT void RED4EXT_CALL RegisterTypes() {

}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes() {
  spdlog::info("Registering members & functions");

  auto rtti = RED4ext::CRTTISystem::Get();

  // expose the minimap members to the scripts
  auto ms = rtti->GetClass("gameuiMinimapContainerController");
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "questPoints", nullptr, 0x1F8));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasQuestMappin", nullptr, 0x208));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "poiPoints", nullptr, 0x220));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasPoiMappin", nullptr, 0x230));

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

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::PluginHandle aHandle, RED4ext::EMainReason aReason,
                                        const RED4ext::Sdk *aSdk) {
  switch (aReason) {
  case RED4ext::EMainReason::Load: {
    // Attach hooks, register RTTI types, add custom states or initalize your
    // application. DO NOT try to access the game's memory at this point, it
    // is not initalized yet.

    Utils::CreateLogger();
    spdlog::info("Starting up In-World Navigation " MOD_VERSION_STR);

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
    ArchiveXL::RegisterArchive(aHandle, "in_world_navigation.archive");
    ModModuleFactory::GetInstance().Load(aSdk, aHandle);

    break;
  }
  case RED4ext::EMainReason::Unload: {
    // Free memory, detach hooks.
    // The game's memory is already freed, to not try to do anything with it.

    spdlog::info("Shutting down");
    ModModuleFactory::GetInstance().Unload(aSdk, aHandle);
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
