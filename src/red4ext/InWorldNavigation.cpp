#include "InWorldNavigation.hpp"

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
