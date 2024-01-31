#include <Registrar.hpp>
#include "Addresses.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>
#include "CyberpunkMod.hpp"
#include "InWorldNavigation.hpp"

// could also use *(gameuiMinimapContainerController_VFT_Addr + 0x240) instead of this pattern
#define UpdateNavPath_Addr (0x002ea510 + 0x1000)
void UpdateNavPath(RED4ext::game::ui::MinimapContainerController *, __int64, unsigned __int8,
                   RED4ext::ink::WidgetReference *);

REGISTER_HOOK(void, UpdateNavPath, RED4ext::game::ui::MinimapContainerController *mmcc, __int64 a2, unsigned __int8 questOrPOI,
                   RED4ext::ink::WidgetReference *widgetRef) {
  UpdateNavPath_Original(mmcc, a2, questOrPOI, widgetRef);

  auto rtti = RED4ext::CRTTISystem::Get();
  if (mmcc->GetType() == rtti->GetClass("gameuiMinimapContainerController")) {
    // auto profiler = CyberpunkMod::Profiler("UpdateNavPath", 5);
    auto fnp = InWorldNavigation::GetInstance();
    auto args = RED4ext::CStackType(rtti->GetType("Int32"), &questOrPOI);
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
