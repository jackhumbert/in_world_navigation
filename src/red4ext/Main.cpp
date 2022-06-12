#include <RED4ext/InstanceType.hpp>
#include <RED4ext/RED4ext.hpp>
#include <RED4ext/RTTITypes.hpp>
#include <RED4ext/Scripting/IScriptable.hpp>
#include <iostream>

#include "Utils.hpp"
#include "stdafx.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/mappins/QuestMappin.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/mappins/PointOfInterestMappin.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>

#include "LoadResRef.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/FxResource.hpp>
#include <RED4ext/Scripting/Natives/Generated/red/ResourceReferenceScriptToken.hpp>

void CastResRefToFxResource(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                            RED4ext::game::FxResource *aOut, int64_t a4) {
  RED4ext::red::ResourceReferenceScriptToken value;
  RED4ext::GetParameter(aFrame, &value);
  aFrame->code++; // skip ParamEnd

  auto resHandle = new RED4ext::ResourceHandle<RED4ext::world::Effect>();
  if (value.resource.ref != 0) {
    RED4ext::CName fc = value.resource.ref;
    LoadResRef<RED4ext::world::Effect>((uint64_t *)&fc, resHandle, true);
  }

  if (aOut) {
    *aOut = *(RED4ext::game::FxResource *)&value.resource;
  }
}

struct InWorldNavigation : RED4ext::IScriptable {
  RED4ext::CClass *GetNativeType();
  static InWorldNavigation *GetInstance();
};

RED4ext::TTypedClass<InWorldNavigation> cls("InWorldNavigation");

RED4ext::CClass *InWorldNavigation::GetNativeType() { return &cls; }

RED4ext::Handle<InWorldNavigation> handle;

InWorldNavigation *InWorldNavigation::GetInstance() {
  if (!handle.instance) {
    spdlog::info("[RED4ext] New InWorldNavigation Instance");
    auto instance = reinterpret_cast<InWorldNavigation *>(cls.AllocInstance());
    handle = RED4ext::Handle<InWorldNavigation>(instance);
  }

  return (InWorldNavigation *)handle.instance;
}

void GetInstanceScripts(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                        RED4ext::Handle<InWorldNavigation> *aOut, int64_t a4) {
  aFrame->code++;

  if (!handle.instance) {
    spdlog::info("[RED4ext] New InWorldNavigation Instance");
    auto instance = reinterpret_cast<InWorldNavigation *>(cls.AllocInstance());
    handle = RED4ext::Handle<InWorldNavigation>(instance);
  }

  if (aOut) {
    handle.refCount->IncRef();
    *aOut = RED4ext::Handle<InWorldNavigation>(handle);
  }
}

// 48 8B C4 48 89 48 08 55 41 55 48 8D 68 A8 48 81 EC 48 01 00 00 48 89 58 10 0F 57 C0 48 89 70 E8
constexpr uintptr_t UpdateNavPathAddr = 0x140000C00 + 0x255D180 - RED4ext::Addresses::ImageBase;
void UpdateNavPath(RED4ext::game::ui::MinimapContainerController *, __int64, unsigned __int8,
                   RED4ext::ink::WidgetReference *);
decltype(&UpdateNavPath) UpdateNavPath_Original;

void UpdateNavPath(RED4ext::game::ui::MinimapContainerController *mmcc, __int64 a2, unsigned __int8 questOrPOI,
                   RED4ext::ink::WidgetReference *widgetRef) {
  UpdateNavPath_Original(mmcc, a2, questOrPOI, widgetRef);

  auto rtti = RED4ext::CRTTISystem::Get();
  if (mmcc->GetType() == rtti->GetClass("gameuiMinimapContainerController")) {
    auto fnp = InWorldNavigation::GetInstance();
    auto args = RED4ext::CStackType(rtti->GetType("Int32"), &questOrPOI);
    auto stack = RED4ext::CStack(fnp, &args, 1, nullptr, 0);
    cls.GetFunction("Update")->Execute(&stack);
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
  spdlog::info("Registering classes & types");
  auto rtti = RED4ext::CRTTISystem::Get();
  auto scriptable = rtti->GetClass("IScriptable");
  cls.parent = scriptable;
  cls.flags = {.isNative = true};
  RED4ext::CRTTISystem::Get()->RegisterType(&cls);
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes() {
  spdlog::info("Registering members & functions");

  auto rtti = RED4ext::CRTTISystem::Get();

  auto getInstance = RED4ext::CClassStaticFunction::Create(&cls, "GetInstance", "GetInstance", &GetInstanceScripts,
                                                           {.isNative = true, .isStatic = true});
  cls.RegisterFunction(getInstance);

  // expose the minimap members to the scripts
  auto ms = rtti->GetClass("gameuiMinimapContainerController");
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "questPoints", nullptr, 0x1E0));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasQuestMappin", nullptr, 0x1F0));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "poiPoints", nullptr, 0x208));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "hasPoiMappin", nullptr, 0x218));

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
    spdlog::info("[RED4ext] Starting up");

    RED4ext::RTTIRegistrator::Add(RegisterTypes, PostRegisterTypes);

    aSdk->hooking->Attach(aHandle, RED4EXT_OFFSET_TO_ADDR(UpdateNavPathAddr), &UpdateNavPath,
                          reinterpret_cast<void **>(&UpdateNavPath_Original));

    break;
  }
  case RED4ext::EMainReason::Unload: {
    // Free memory, detach hooks.
    // The game's memory is already freed, to not try to do anything with it.

    spdlog::info("[RED4ext] Shutting down");
    aSdk->hooking->Detach(aHandle, RED4EXT_OFFSET_TO_ADDR(UpdateNavPathAddr));
    spdlog::shutdown();
    break;
  }
  }

  return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo *aInfo) {
  aInfo->name = L"In-World Navigation";
  aInfo->author = L"Jack Humbert";
  aInfo->version = RED4EXT_SEMVER(0, 0, 2);
  aInfo->runtime = RED4EXT_RUNTIME_LATEST;
  aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports() { return RED4EXT_API_VERSION_LATEST; }
