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