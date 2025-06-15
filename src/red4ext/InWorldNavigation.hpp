#include <RedLib.hpp>

struct InWorldNavigation : RED4ext::IScriptable {
  static RED4ext::Handle<InWorldNavigation> GetInstance();
  RTTI_IMPL_TYPEINFO(InWorldNavigation);
  RTTI_IMPL_ALLOCATOR();
  
  virtual bool CanBeDestructed() override {
    return false;
  }
};

RTTI_DEFINE_CLASS(InWorldNavigation, { 
  RTTI_METHOD(GetInstance); 
});