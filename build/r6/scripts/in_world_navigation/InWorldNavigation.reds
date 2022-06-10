public native class InWorldNavigation extends IScriptable {
  public static native func GetInstance() -> ref<InWorldNavigation>;

  public let mmcc: ref<MinimapContainerController>;
  public let player: ref<GameObject>;
  let spacing: Float;
  let maxPoints: Int32;
  let distanceToFade: Float;

  let navPathFXs: array<array<ref<FxInstance>>>;
  let navPathTransforms: array<array<WorldTransform>>;

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

  let distanceToAnimate: Float;

  public func Setup(player: ref<GameObject>) -> Void {
    this.player = player;
    this.spacing = 5.0; // meters
    this.maxPoints = 200;
    this.distanceToAnimate = 2.5;
    this.distanceToFade = 25.0;
    
    this.navPathYellowResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_yellow.effect");
    this.navPathBlueResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_blue.effect");
    this.navPathWhiteResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_white.effect");
    this.navPathTealResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_teal.effect");

    let questFx: array<ref<FxInstance>>;
    let poiFx: array<ref<FxInstance>>;
    ArrayPush(this.navPathFXs, questFx);
    ArrayPush(this.navPathFXs, poiFx);

    let questTransforms: array<WorldTransform>;
    let poisTransforms: array<WorldTransform>;
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
    let lastDrawnPoint: Vector4 = points[0];
    let pointDrawnCount: Int32 = 0;

    let i = 1;
    while i < ArraySize(points) && pointDrawnCount < this.maxPoints {
      let tweenPointDistance = Vector4.Distance(points[i-1], points[i]);
      let orientation = Quaternion.BuildFromDirectionVector(points[i] - lastDrawnPoint);
      if i == 1 {
        let tweenPointCount = FloorF(tweenPointDistance / this.spacing);
        let distance = AbsF(tweenPointDistance - (Cast<Float>(tweenPointCount) * this.spacing));
        if distance >= this.spacing / 2.0 {
          distance -= this.spacing;
        }
        // let distance = 0.0;
        while distance <= tweenPointDistance && pointDrawnCount < this.maxPoints {
          let ratio: Float = distance / tweenPointDistance;
          let position = Vector4.Interpolate(points[i-1], points[i], ratio);
          this.UpdateFxInstance(type, pointDrawnCount, position, orientation, resource, force);
          distance += this.spacing;
          pointDrawnCount += 1;
          lastDrawnPoint = position;
        }
      } else {
        if tweenPointDistance >= this.spacing {
          // let rounded = Cast<Float>(RoundF(tweenPointDistance / this.spacing));
          // let tweenPointSpacing = this.spacing + (tweenPointDistance - rounded * this.spacing) / rounded;
          let lastDrawnPointDistance = Vector4.Distance(lastDrawnPoint, points[i-1]);
          let lastDrawnPointInLastGroup = lastDrawnPoint;
          let distance = -lastDrawnPointDistance + this.spacing;
          while distance <= tweenPointDistance && pointDrawnCount < this.maxPoints {
            let ratio: Float = distance / tweenPointDistance;
            let position = Vector4.Interpolate(points[i-1], points[i], ratio);
            if ratio < 0.0 {
              position = Vector4.Interpolate(lastDrawnPointInLastGroup, position, (lastDrawnPointDistance + distance) / lastDrawnPointDistance);
              orientation = Quaternion.BuildFromDirectionVector(position - lastDrawnPoint);
            }
            distance += this.spacing;
            this.UpdateFxInstance(type, pointDrawnCount, position, orientation, resource, force);
            pointDrawnCount += 1;
            lastDrawnPoint = position;
          }
        }
      }
      i += 1;
    }
    while pointDrawnCount < this.maxPoints && pointDrawnCount < ArraySize(this.navPathFXs[type]) {   
      this.navPathFXs[type][pointDrawnCount].SetBlackboardValue(n"alpha", 0.0);
      this.navPathFXs[type][pointDrawnCount].BreakLoop();
      this.navPathFXs[type][pointDrawnCount].Kill();
      pointDrawnCount += 1;
    }
  }

  private func UpdateFxInstance(type: Int32, i: Int32, p: Vector4, q: Quaternion, resource: FxResource, force: Bool) {
    let p_new = p;
    let q_new = q;
    if i >= ArraySize(this.navPathTransforms[type]) {
      let wt: WorldTransform;
      ArrayPush(this.navPathTransforms[type], wt);
    } else {
      let p_old = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(this.navPathTransforms[type][i]));
      let q_old = WorldTransform.GetOrientation(this.navPathTransforms[type][i]);
      if Vector4.Distance(p_old, p_new) < this.distanceToAnimate {
        p_new = Vector4.Interpolate(p_old, p, 0.1);
        q_new = Quaternion.Slerp(q_old, q, 0.1);
      }
    }
    WorldTransform.SetPosition(this.navPathTransforms[type][i], p_new);
    WorldTransform.SetOrientation(this.navPathTransforms[type][i], q_new);

    if i >= ArraySize(this.navPathFXs[type]) {
      ArrayPush(this.navPathFXs[type], GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffect(resource, this.navPathTransforms[type][i]));
    } else { 
      if IsDefined(this.navPathFXs[type][i]) && this.navPathFXs[type][i].IsValid() && !force {
        this.navPathFXs[type][i].UpdateTransform(this.navPathTransforms[type][i]);
      } else {
        if IsDefined(this.navPathFXs[type][i]) {
          this.navPathFXs[type][i].BreakLoop();
          this.navPathFXs[type][i].Kill();
        }
        this.navPathFXs[type][i] = GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffect(resource, this.navPathTransforms[type][i]);
      }
    }
    this.navPathFXs[type][i].SetBlackboardValue(n"alpha", MinF(Vector4.Distance2D(this.player.GetWorldPosition(), p) / this.distanceToFade, 1.0));
  }
}