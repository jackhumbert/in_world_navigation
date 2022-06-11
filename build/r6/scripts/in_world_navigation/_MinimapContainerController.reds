@wrapMethod(MinimapContainerController)
protected final func InitializePlayer(playerPuppet: ref<GameObject>) -> Void {
  wrappedMethod(playerPuppet);
  let iwn = InWorldNavigation.GetInstance();
  iwn.Setup(playerPuppet);
  iwn.mmcc = this;
}

@addMethod(MinimapContainerController)
public native func GetQuestMappin() -> ref<QuestMappin>;

@addField(MinimapContainerController)
public native let questPoints: array<Vector4>;

@addMethod(MinimapContainerController)
public native func GetPOIMappin() -> ref<IMappin>;

@addField(MinimapContainerController)
public native let poiPoints: array<Vector4>;

@addField(MinimapContainerController)
public native let hasPoiMappin: Bool;

@addField(MinimapContainerController)
public native let hasQuestMappin: Bool;