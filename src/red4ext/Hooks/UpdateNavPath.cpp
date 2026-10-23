#ifdef __APPLE__
#include "MacShims.hpp"
#include "IwnFields.hpp"
#else
#include <Registrar.hpp>
#endif
#include "Addresses.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>
#ifndef __APPLE__
#include "CyberpunkMod.hpp"
#endif
#include "InWorldNavigation.hpp"

// 3797170204 (this, context, type, widgetRef)
// void game::ui::MinimapContainerController::UpdateGPSPath(ink::IWidgetController::UpdateContext const &, game::gps::ETargetType, ink::LinePatternWidgetReference const &)

// could use 1268721260 (this, type, data)
// void game::ui::MappinsContainerController::OnGPSPathChanged(game::gps::ETargetType, game::gps::IListener::PathData const &)

// 3770693656
// void game::ui::MinimapContainerController::UpdateGPSPath(struct ink::IWidgetController::UpdateContext const &,enum game::gps::ETargetType,struct ink::LinePatternWidgetReference const &)

// 3637917225
// UpdateFromPoints(game::ui::MinimapContainerController *this, DynArray<Vector4> *points, __int64 linePatternWidgetRef)

#ifdef __APPLE__
namespace
{
using IwnUpdateNavPath_t = void (*)(RED4ext::game::ui::MinimapContainerController*);
IwnUpdateNavPath_t g_updateNavPathOriginal = nullptr;
bool g_updateNavPathInstalled = false;
uintptr_t g_updateNavPathTarget = 0;

void IwnCallUpdate(int32_t aType)
{
  auto rtti = RED4ext::CRTTISystem::Get();
  if (!rtti) {
    return;
  }
  auto cls = rtti->GetClass("InWorldNavigation");
  if (!cls) {
    return;
  }
  auto update = cls->GetFunction("Update");
  if (!update) {
    return;
  }
  auto fnp = InWorldNavigation::GetInstance();
  auto args = RED4ext::CStackType(rtti->GetType("Int32"), &aType);
  auto stack = RED4ext::CStack(fnp, &args, 1, nullptr);
  update->Execute(&stack);
}

void IwnUpdateNavPath(RED4ext::game::ui::MinimapContainerController* mmcc)
{
  if (g_updateNavPathOriginal) {
    g_updateNavPathOriginal(mmcc);
  }
  if (!mmcc) {
    return;
  }
  auto rtti = RED4ext::CRTTISystem::Get();
  if (!rtti) {
    return;
  }
  if (mmcc->GetType() == rtti->GetClass("gameuiMinimapContainerController")) {
    IwnCallUpdate(0);
    IwnCallUpdate(1);
  }
}
}

void IwnMac::AttachUpdateNavPath(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle)
{
  g_updateNavPathTarget = ImageBase() + 0x4c55228;
  void* original = nullptr;
  g_updateNavPathInstalled = TryAttach(aSdk, aHandle, g_updateNavPathTarget, reinterpret_cast<void*>(&IwnUpdateNavPath),
                                       &original, "UpdateNavPath");
  g_updateNavPathOriginal = g_updateNavPathInstalled ? reinterpret_cast<IwnUpdateNavPath_t>(original) : nullptr;
}

void IwnMac::DetachUpdateNavPath(const RED4ext::Sdk* aSdk, RED4ext::PluginHandle aHandle)
{
  if (!g_updateNavPathInstalled || !aSdk || !aSdk->hooking || !aSdk->hooking->Detach) {
    return;
  }
  aSdk->hooking->Detach(aHandle, reinterpret_cast<void*>(g_updateNavPathTarget));
  g_updateNavPathInstalled = false;
  g_updateNavPathOriginal = nullptr;
}
#else
REGISTER_HOOK_HASH(void, 3770693656, UpdateNavPath, 
    RED4ext::game::ui::MinimapContainerController *mmcc, 
    __int64 updateContext, 
    unsigned __int8 targetType,
    RED4ext::ink::WidgetReference *widgetRef
  ) {
  UpdateNavPath_Original(mmcc, updateContext, targetType, widgetRef);

  auto rtti = RED4ext::CRTTISystem::Get();
  if (mmcc->GetType() == rtti->GetClass("gameuiMinimapContainerController")) {
    // auto profiler = CyberpunkMod::Profiler("UpdateNavPath", 5);
    auto fnp = InWorldNavigation::GetInstance();
    auto args = RED4ext::CStackType(rtti->GetType("Int32"), &targetType);
    auto stack = RED4ext::CStack(fnp, &args, 1, nullptr);
    auto update = rtti->GetClass("InWorldNavigation")->GetFunction("Update");
    if (update)
      update->Execute(&stack);
    // auto avg = profiler.End();
    // if (avg) {
      // spdlog::info("Average InWorldNavigation loop time: {}", avg);
    // }
  }
}
#endif
