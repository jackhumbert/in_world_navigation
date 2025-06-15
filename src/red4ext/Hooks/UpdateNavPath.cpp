#include <Registrar.hpp>
#include "Addresses.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>
#include "CyberpunkMod.hpp"
#include "InWorldNavigation.hpp"

// 3797170204 (this, context, type, widgetRef)
// void game::ui::MinimapContainerController::UpdateGPSPath(ink::IWidgetController::UpdateContext const &, game::gps::ETargetType, ink::LinePatternWidgetReference const &)

// could use 1268721260 (this, type, data)
// void game::ui::MappinsContainerController::OnGPSPathChanged(game::gps::ETargetType, game::gps::IListener::PathData const &)

REGISTER_HOOK_HASH(void, 3797170204, UpdateNavPath, 
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
