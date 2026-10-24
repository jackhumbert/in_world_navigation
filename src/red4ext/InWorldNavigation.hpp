#include <RedLib.hpp>
#ifdef __APPLE__
// clang instantiates Handle<T> for the members inkWidget.hpp only forward-declares, so it needs the full types (MSVC does not)
#include <RED4ext/Scripting/Natives/Generated/ink/IEffect.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/Layer.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/LayerProxy.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/PropertyManager.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/StyleResourceWrapper.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/UserData.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/WidgetLibraryResource.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/WidgetLogicController.hpp>
#endif
#include <RED4ext/Scripting/Natives/inkWidget.hpp>

struct InWorldNavigation : RED4ext::IScriptable {
  static RED4ext::Handle<InWorldNavigation> GetInstance();
  // true when the widget and all of its parents are visible with non-zero opacity
  static bool IsWidgetTreeVisible(RED4ext::WeakHandle<RED4ext::ink::Widget> widget);
  RTTI_IMPL_TYPEINFO(InWorldNavigation);
  RTTI_IMPL_ALLOCATOR();
  
  virtual bool CanBeDestructed() override {
    return false;
  }
};

RTTI_DEFINE_CLASS(InWorldNavigation, { 
  RTTI_METHOD(GetInstance); 
  RTTI_METHOD(IsWidgetTreeVisible);
});