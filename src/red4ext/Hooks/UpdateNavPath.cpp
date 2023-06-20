#include <Registrar.hpp>
#include "Addresses.hpp"
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>
#include "CyberpunkMod.hpp"
#include "InWorldNavigation.hpp"

// 1.6  RVA: 0x259E440
// 1.61 RVA: 0x259F3C0
// 1.61hf RVA: 0x259FAF0
// 1.62 RVA: 0x25B1920
/// @pattern 48 8B C4 48 89 48 08 55 41 55 48 8D 68 A8 48 81 EC 48 01 00 00 48 89 58 10 0F 57 C0 48 89 70 E8
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
    auto stack = RED4ext::CStack(fnp, &args, 1, nullptr, 0);
    rtti->GetClass("InWorldNavigation")->GetFunction("Update")->Execute(&stack);
    // auto avg = profiler.End();
    // if (avg) {
      // spdlog::info("Average InWorldNavigation loop time: {}", avg);
    // }
  }
}
