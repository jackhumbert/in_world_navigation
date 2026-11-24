#include <Registrar.hpp>
#include <chrono>
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
    // widen first: an Int32 read straight from the one-byte argument takes three bytes of stack garbage with it
    int32_t target = targetType;
    auto args = RED4ext::CStackType(rtti->GetType("Int32"), &target);
    auto stack = RED4ext::CStack(fnp, &args, 1, nullptr);
    auto update = rtti->GetClass("InWorldNavigation")->GetFunction("Update");
    if (update) {
      auto start = std::chrono::steady_clock::now();
      update->Execute(&stack);
      auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now() - start);
      InWorldNavigation::RecordUpdate(targetType, elapsed.count());
    }
  }
}
