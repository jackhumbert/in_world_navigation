#include <RED4ext/RED4ext.hpp>

// red::SharedStorage<res::ResourceToken, ...> res::ResourceAsyncReference::IssueLoadingRequest(io::EAsyncPriority) const
template <typename T>
RED4ext::UniversalRelocFunc<RED4ext::ResourceToken<T> *(*)(RED4ext::ResourcePath *,
                                                  RED4ext::SharedPtr<RED4ext::ResourceToken<T>> *wrapper, bool sync)>
    ResourceAsyncReference_IssueLoadingRequest(1157708450);
