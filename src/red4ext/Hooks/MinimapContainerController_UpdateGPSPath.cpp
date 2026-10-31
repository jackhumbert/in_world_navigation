#include <Registrar.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>
#include "CyberpunkMod.hpp"
#include "InWorldNavigation.hpp"

// void game::ui::MinimapContainerController::UpdateGPSPath(ink::IWidgetController::UpdateContext const &, game::gps::ETargetType, ink::LinePatternWidgetReference const &)
REGISTER_HOOK_HASH(void, 3770693656, MinimapContainerController_UpdateGPSPath, 
    RED4ext::game::ui::MinimapContainerController *mmcc, 
    __int64 updateContext, 
    unsigned __int8 targetType,
    RED4ext::ink::WidgetReference *widgetRef
  ) {
  MinimapContainerController_UpdateGPSPath_Original(mmcc, updateContext, targetType, widgetRef);

  auto rtti = RED4ext::CRTTISystem::Get();
  if (mmcc->GetType() == rtti->GetClass("gameuiMinimapContainerController")) {
    auto fnp = InWorldNavigation::GetInstance();
    auto args = RED4ext::CStackType(rtti->GetType("Int32"), &targetType);
    auto stack = RED4ext::CStack(fnp, &args, 1, nullptr);
    auto update = rtti->GetClass("InWorldNavigation")->GetFunction("Update");
    if (update)
      update->Execute(&stack);
  }
}
