public native class InWorldNavigation extends IScriptable {
  public static native func GetInstance() -> ref<InWorldNavigation>;

  public let mmcc: ref<MinimapContainerController>;
  public let player: ref<GameObject>;
  let spacing: Float;
  let maxPoints: Int32;
  let distanceToFade: Float;

  let navPathFXs: array<array<ref<FxInstance>>>;
  let navPathTransforms: array<array<Transform>>;

  let navPathYellowResource: FxResource;
  let navPathBlueResource: FxResource;
  let navPathWhiteResource: FxResource;
  let navPathTealResource: FxResource;

  let questMappin: wref<QuestMappin>;
  let poiMappin: wref<IMappin>;
  let questResource: FxResource;
  let poiResource: FxResource;

  let questVariant: gamedataMappinVariant;
  let poiVariant: gamedataMappinVariant;

  let distanceToAnimate: Float;

  public func Setup(player: ref<GameObject>) -> Void {
    this.player = player;
    this.spacing = 5.0; // meters
    this.maxPoints = 200;
    this.distanceToAnimate = 50.0;
    this.distanceToFade = 25.0;
    
    this.navPathYellowResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_yellow.effect");
    this.navPathBlueResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_blue.effect");
    this.navPathWhiteResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_white.effect");
    this.navPathTealResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_teal.effect");

    let questFx: array<ref<FxInstance>>;
    let poiFx: array<ref<FxInstance>>;
    ArrayPush(this.navPathFXs, questFx);
    ArrayPush(this.navPathFXs, poiFx);

    let questTransforms: array<Transform>;
    let poisTransforms: array<Transform>;
    ArrayPush(this.navPathTransforms, questTransforms);
    ArrayPush(this.navPathTransforms, poisTransforms);
  }

  public func GetResourceForVariant(variant: gamedataMappinVariant) -> FxResource {
      switch (variant) {     
        case gamedataMappinVariant.Zzz02_MotorcycleForPurchaseVariant:
        case gamedataMappinVariant.Zzz01_CarForPurchaseVariant:
        case gamedataMappinVariant.Zzz05_ApartmentToPurchaseVariant:
        case gamedataMappinVariant.QuestGiverVariant:
        case gamedataMappinVariant.FixerVariant:
        case gamedataMappinVariant.RetrievingVariant:
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
      // if questOrPOI == 0 {
        let questMappin = this.mmcc.GetQuestMappin();
        if IsDefined(questMappin) {
          let questVariant = questMappin.GetVariant();
          if !Equals(questVariant, this.questVariant) {
            this.questVariant = questVariant;
            this.UpdateNavPath(0, this.mmcc.questPoints, this.GetResourceForVariant(this.questVariant), true);
          } else {
            this.UpdateNavPath(0, this.mmcc.questPoints, this.GetResourceForVariant(this.questVariant), false);
          }
        } else {     
          for fx in this.navPathFXs[0] {
            fx.BreakLoop();
          }
        }
      // } else {
        let poiMappin = this.mmcc.GetPOIMappin();
        if IsDefined(poiMappin) {
          let poiVariant = poiMappin.GetVariant();
          if !Equals(poiVariant, this.poiVariant) {
            this.poiVariant = poiVariant;
            this.UpdateNavPath(1, this.mmcc.poiPoints, this.GetResourceForVariant(this.poiVariant), true);
          } else {
            this.UpdateNavPath(1, this.mmcc.poiPoints, this.GetResourceForVariant(this.poiVariant), false);
          }
        } else {
          for fx in this.navPathFXs[1] {
            fx.BreakLoop();
          }
        }
      // }
    }
  }

  public func Stop() {
    for fx in this.navPathFXs[0] {
      fx.BreakLoop();
    }
    for fx in this.navPathFXs[1] {
      fx.BreakLoop();
    }
  }

  private func UpdateNavPath(type: Int32, points: array<Vector4>, resource: FxResource, force: Bool) -> Void {
    let pointDrawnCount: Int32 = 0;
    let dots: array<Transform>;

    let i = ArraySize(points) - 1;
    let lastDrawnPoint: Vector4 = points[i];

    while i > 0 {
      let tweenPointDistance = Vector4.Distance(points[i-1], lastDrawnPoint);
      if tweenPointDistance >= this.spacing {
        // let rounded = Cast<Float>(RoundF(tweenPointDistance / this.spacing));
        // let tweenPointSpacing = this.spacing + (tweenPointDistance - rounded * this.spacing) / rounded;
        let lastDrawnPointInLastGroup = lastDrawnPoint;
        let distance = this.spacing;
        while distance < tweenPointDistance {
          let ratio: Float = distance / tweenPointDistance;
          let position = Vector4.Interpolate(lastDrawnPointInLastGroup, points[i-1], ratio);
          let orientation = Quaternion.BuildFromDirectionVector(lastDrawnPoint - position);
          distance += this.spacing;
          ArrayPush(dots, Transform.Create(position, orientation));
          lastDrawnPoint = position;
        }
      }
      i -= 1;
    }

    i = 0;

    while i < ArraySize(dots) {
      if ArraySize(this.navPathTransforms[type]) <= i {
        ArrayPush(this.navPathTransforms[type], dots[i]);
      } else {
        if Vector4.Distance(this.navPathTransforms[type][i].position, dots[i].position) < this.distanceToAnimate {
          this.navPathTransforms[type][i].position = Vector4.Interpolate(this.navPathTransforms[type][i].position, dots[i].position, 0.1);
          this.navPathTransforms[type][i].orientation = Quaternion.Slerp(this.navPathTransforms[type][i].orientation, dots[i].orientation, 0.1);
        } else {
          this.navPathTransforms[type][i].position = dots[i].position;
          this.navPathTransforms[type][i].orientation = dots[i].orientation;
        }
      }
      i += 1;
    }

    ArrayResize(this.navPathTransforms[type], ArraySize(dots));

    i = ArraySize(dots) - 1;

    while pointDrawnCount < this.maxPoints && i >= 0 {
      let p = this.navPathTransforms[type][i].position;
      let q = this.navPathTransforms[type][i].orientation;
      this.UpdateFxInstance(type, pointDrawnCount, p, q, resource, force);
      pointDrawnCount += 1;
      i -= 1;
    }

    while pointDrawnCount < this.maxPoints && pointDrawnCount < ArraySize(this.navPathFXs[type]) {   
      this.navPathFXs[type][pointDrawnCount].SetBlackboardValue(n"alpha", 0.0);
      this.navPathFXs[type][pointDrawnCount].BreakLoop();
      this.navPathFXs[type][pointDrawnCount].Kill();
      pointDrawnCount += 1;
    }
  }

  private func UpdateFxInstance(type: Int32, i: Int32, p: Vector4, q: Quaternion, resource: FxResource, force: Bool) {
    let wt: WorldTransform;
    WorldTransform.SetPosition(wt, p);
    WorldTransform.SetOrientation(wt, q);
    if i >= ArraySize(this.navPathFXs[type]) {
      ArrayPush(this.navPathFXs[type], GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffect(resource, wt));
    } else { 
      if IsDefined(this.navPathFXs[type][i]) && this.navPathFXs[type][i].IsValid() && !force {
        this.navPathFXs[type][i].UpdateTransform(wt);
      } else {
        if IsDefined(this.navPathFXs[type][i]) {
          this.navPathFXs[type][i].BreakLoop();
          this.navPathFXs[type][i].Kill();
        }
        this.navPathFXs[type][i] = GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffect(resource, wt);
      }
    }
    this.navPathFXs[type][i].SetBlackboardValue(n"alpha", MinF(Vector4.Distance2D(this.player.GetWorldPosition(), p) / this.distanceToFade, 1.0));
  }
}