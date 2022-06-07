public native class InWorldNavigation extends IScriptable {
  public static native func GetInstance() -> ref<InWorldNavigation>;

  public let mmcc: ref<MinimapContainerController>;
  public let player: ref<GameObject>;
  let spacing: Float;
  let maxPoints: Int32;

  let navPathQuestFX: array<ref<FxInstance>>;
  let navPathPOIFX: array<ref<FxInstance>>;
  let navPathYellowResource: FxResource;
  let navPathBlueResource: FxResource;
  let navPathWhiteResource: FxResource;
  let navPathTealResource: FxResource;

  let questMappin: ref<QuestMappin>;
  let poiMappin: ref<IMappin>;
  let questResource: FxResource;
  let poiResource: FxResource;

  let questVariant: gamedataMappinVariant;
  let poiVariant: gamedataMappinVariant;

  public func Setup(player: ref<GameObject>) -> Void {
    this.player = player;
    this.spacing = 5.0; // meters
    this.maxPoints = 100;
    this.navPathYellowResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_yellow.effect");
    this.navPathBlueResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_blue.effect");
    this.navPathWhiteResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_white.effect");
    this.navPathTealResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_teal.effect");
  }

  public func GetResourceForVariant(variant: gamedataMappinVariant) -> FxResource {
      switch (variant) {     
        case gamedataMappinVariant.Zzz02_MotorcycleForPurchaseVariant:
        case gamedataMappinVariant.Zzz01_CarForPurchaseVariant:
        case gamedataMappinVariant.Zzz05_ApartmentToPurchaseVariant:
        case gamedataMappinVariant.QuestGiverVariant:
        case gamedataMappinVariant.FixerVariant:
         return this.navPathTealResource;
          break;
        case gamedataMappinVariant.DefaultQuestVariant:
        case gamedataMappinVariant.ExclamationMarkVariant:
          return this.navPathYellowResource; 
          break;
        case gamedataMappinVariant.TarotVariant:
        case gamedataMappinVariant.FastTravelVariant:
          return this.navPathBlueResource;
          break; 
        case gamedataMappinVariant.ServicePointDropPointVariant:
        case gamedataMappinVariant.CustomPositionVariant:
          return this.navPathWhiteResource;
          break;
      }
      return this.navPathWhiteResource;
  }

  public func Update(questOrPOI: Int32) {
    if IsDefined(this.mmcc) {
      if questOrPOI == 0 {
        let questMappin = this.mmcc.GetQuestMappin();
        if IsDefined(questMappin) {
          let questVariant = questMappin.GetVariant();
          if !Equals(questVariant, this.questVariant) {
            this.questVariant = questVariant;
            this.UpdateNavPath(this.navPathQuestFX, this.mmcc.questPoints, this.GetResourceForVariant(this.questVariant));
          } else {
            this.UpdateNavPath(this.navPathQuestFX, this.mmcc.questPoints, this.GetResourceForVariant(this.questVariant));
          }
        }
      } else {
        let poiMappin = this.mmcc.GetPOIMappin();
        if IsDefined(poiMappin) {
          let poiVariant = poiMappin.GetVariant();
          if !Equals(poiVariant, this.poiVariant) {
            this.poiVariant = poiVariant;
            this.UpdateNavPath(this.navPathPOIFX, this.mmcc.poiPoints, this.GetResourceForVariant(this.poiVariant));
          } else {
            this.UpdateNavPath(this.navPathPOIFX, this.mmcc.poiPoints, this.GetResourceForVariant(this.poiVariant));
          }
        }
      }
    }
  }

  public func Stop() {
    for fx in this.navPathQuestFX {
      fx.BreakLoop();
    }
    for fx in this.navPathPOIFX {
      fx.BreakLoop();
    }
  }

  private func UpdateNavPath(out fxs:array<ref<FxInstance>>, points: array<Vector4>, resource: FxResource) -> Void {
    let lastPoint: Vector4 = points[0];
    ArrayErase(points, 0);
    let pointDrawnCount: Int32 = 0;

    for point in points {
        if pointDrawnCount >= this.maxPoints {
          break;
        }

        let tweenPointDistance = Vector4.distance(point, lastPoint);
        let tweenPointCount = Cast<Int32>(Cast<Float>(RoundF(tweenPointDistance / this.spacing)));

        if tweenPointCount >= 1 {
            let orientation = Quaternion.BuildFromDirectionVector(point - lastPoint);

            let tweenPointDrawnCount: Int32 = 0;
            while tweenPointDrawnCount < tweenPointCount {
                let ratio: Float = Cast<Float>(tweenPointDrawnCount)/Cast<Float>(tweenPointCount);
                let position = Vector4.Interpolate(point, lastPoint, ratio);

                this.UpdateNavPath(fxs, pointDrawnCount, position, orientation, resource);

                tweenPointDrawnCount += 1;
                pointDrawnCount += 1;
            }
            lastPoint = point;
        }
    }
  }

  private func UpdateNavPath(out fxs: array<ref<FxInstance>>, i: Int32, p: Vector4, q: Quaternion, resource: FxResource) {
    let navPathTransform: WorldTransform;
    WorldTransform.SetPosition(navPathTransform, p);
    WorldTransform.SetOrientation(navPathTransform, q);

    if ArraySize(fxs) <= i {
      ArrayPush(fxs, GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffectOnGround(resource, navPathTransform));
    } else {
        fxs[i].BreakLoop();
        fxs[i].Kill();
        fxs[i] = GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffectOnGround(resource, navPathTransform);
      }
  }
}