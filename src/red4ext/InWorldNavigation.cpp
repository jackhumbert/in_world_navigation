#include "InWorldNavigation.hpp"

#include <algorithm>
#include <format>

RED4ext::Handle<InWorldNavigation> handle;

RED4ext::Handle<InWorldNavigation> InWorldNavigation::GetInstance() {
  if (!handle.instance) {
    auto rtti = RED4ext::CRTTISystem::Get();
    spdlog::info("[RED4ext] New InWorldNavigation Instance");
    auto instance = reinterpret_cast<InWorldNavigation *>(rtti->GetClass("InWorldNavigation")->CreateInstance());
    handle = RED4ext::Handle<InWorldNavigation>(instance);
  }

  return handle;
}

namespace {
struct UpdateStats {
  int64_t calls = 0;
  int64_t byTarget[2] = {0, 0};
  int64_t totalMicroseconds = 0;
  int64_t maxMicroseconds = 0;
};
UpdateStats stats;
} // namespace

void InWorldNavigation::RecordUpdate(uint8_t targetType, int64_t microseconds) {
  stats.calls++;
  if (targetType < 2) {
    stats.byTarget[targetType]++;
  }
  stats.totalMicroseconds += microseconds;
  stats.maxMicroseconds = std::max(stats.maxMicroseconds, microseconds);
}

RED4ext::CString InWorldNavigation::GetUpdateStats() {
  auto mean = stats.calls ? stats.totalMicroseconds / stats.calls : 0;
  auto text = std::format("calls {} (quest {}, poi {}), total {:.1f} ms, mean {} us, max {} us", stats.calls,
                          stats.byTarget[0], stats.byTarget[1], stats.totalMicroseconds / 1000.0, mean,
                          stats.maxMicroseconds);
  return RED4ext::CString(text.c_str());
}

void InWorldNavigation::ResetUpdateStats() {
  stats = UpdateStats{};
}

bool InWorldNavigation::IsWidgetTreeVisible(RED4ext::WeakHandle<RED4ext::ink::Widget> widget) {
  auto current = widget.Lock();
  if (!current) {
    // nothing to inspect; don't hide the arrows on account of a missing widget
    return true;
  }
  // HUD-hiding mods either SetVisible(false) or fade the opacity to 0 somewhere up the tree (the widget
  // itself, the HUD entry, or the HUD layer's window), so walk all the way up
  int depth = 0;
  while (current && depth < 64) {
    if (!current->visible || current->opacity <= 0.001f) {
      return false;
    }
    current = current->parentWidget.Lock();
    depth++;
  }
  return true;
}
