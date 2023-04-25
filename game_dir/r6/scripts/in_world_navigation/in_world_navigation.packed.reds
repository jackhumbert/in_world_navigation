// In-World Navigation v0.0.8
// Licensed under the MIT license. See the license.md in the root project for details.
// https://github.com/jackhumbert/in_world_navigation

// This file was automatically generated on 2023-04-25 20:46:50 UTC

// in_world_navigation/InWorldNavigation.reds

enum InWorldNavigationMode {
  Always = 0,
  Driving = 1,
  Walking = 2
}

public native class InWorldNavigation extends IScriptable {
  public static native func GetInstance() -> ref<InWorldNavigation>;

  public let mmcc: ref<MinimapContainerController>;
  public let player: ref<GameObject>;
  
  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Enabled")
  let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Display mode")
  @runtimeProperty("ModSettings.displayValues", "\"Always\", \"When Driving\", \"When Walking\"")
  let mode: InWorldNavigationMode = InWorldNavigationMode.Driving;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow spacing")
  @runtimeProperty("ModSettings.description", "In-game units between arrows")
  @runtimeProperty("ModSettings.step", "0.5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20.0")
  let spacing: Float = 5.0;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Max number of arrows")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "10")
  @runtimeProperty("ModSettings.max", "2000")
  let maxPoints: Int32 = 200;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Distance within arrows will fade")
  @runtimeProperty("ModSettings.description", "Measures from player")
  @runtimeProperty("ModSettings.step", "1.0")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "100.0")
  let distanceToFade: Float = 25.0;

  let navPathFXs: array<array<ref<FxInstance>>>;
  let navPathTransforms: array<array<Transform>>;

  let navPathYellowResource: FxResource;
  let navPathBlueResource: FxResource;
  let navPathWhiteResource: FxResource;
  let navPathTealResource: FxResource;
  let navPathCyanResource: FxResource;

  let questResource: FxResource;
  let poiResource: FxResource;

  let questVariant: gamedataMappinVariant;
  let poiVariant: gamedataMappinVariant;

  let distanceToAnimate: Float;

  public func Setup(player: ref<GameObject>) -> Void {
    this.player = player;
    this.distanceToAnimate = 50.0;
    
    this.navPathYellowResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_yellow.effect");
    this.navPathBlueResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_blue.effect");
    this.navPathWhiteResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_white.effect");
    this.navPathTealResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_teal.effect");
    this.navPathCyanResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_cyan.effect");

    let questFx: array<ref<FxInstance>>;
    let poiFx: array<ref<FxInstance>>;
    ArrayPush(this.navPathFXs, questFx);
    ArrayPush(this.navPathFXs, poiFx);

    let questTransforms: array<Transform>;
    let poisTransforms: array<Transform>;
    ArrayPush(this.navPathTransforms, questTransforms);
    ArrayPush(this.navPathTransforms, poisTransforms);
    ModSettings.RegisterListenerToClass(this);
  }

  public func GetResourceForVariant(variant: gamedataMappinVariant) -> FxResource {
      switch (variant) {     
        case gamedataMappinVariant.Zzz02_MotorcycleForPurchaseVariant:
        case gamedataMappinVariant.Zzz01_CarForPurchaseVariant:
        case gamedataMappinVariant.Zzz05_ApartmentToPurchaseVariant:
        case gamedataMappinVariant.QuestGiverVariant:
        case gamedataMappinVariant.FixerVariant:
        case gamedataMappinVariant.RetrievingVariant:
        case gamedataMappinVariant.SabotageVariant:
        case gamedataMappinVariant.ClientInDistressVariant:
        case gamedataMappinVariant.ThieveryVariant:
        case gamedataMappinVariant.HuntForPsychoVariant:
        case gamedataMappinVariant.Zzz06_NCPDGigVariant:
        case gamedataMappinVariant.BountyHuntVariant:
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
        case gamedataMappinVariant.GangWatchVariant:
        case gamedataMappinVariant.HiddenStashVariant: 
        case gamedataMappinVariant.OutpostVariant:
          return this.navPathCyanResource;
          break; 
        case gamedataMappinVariant.ServicePointDropPointVariant:
        case gamedataMappinVariant.CustomPositionVariant:
          return this.navPathWhiteResource;
          break;
      }
      return this.navPathWhiteResource;
  }

  public func Update(canUpdate: Int32) {
    if IsDefined(this.mmcc) {
      let isMounted = VehicleComponent.IsMountedToVehicle(this.player.GetGame(), this.player);
      if this.enabled && 
        ((isMounted && NotEquals(this.mode, InWorldNavigationMode.Walking)) ||
         (!isMounted && NotEquals(this.mode, InWorldNavigationMode.Driving))
        ) { 
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
      } else {
        this.Stop();
      }
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

  let timer: Float;

  private func UpdateNavPath(type: Int32, points: array<Vector4>, resource: FxResource, force: Bool) -> Void {
    let pointDrawnCount: Int32 = 0;
    let dots: array<Transform>;
    let i = ArraySize(points) - 1;
    let lastDrawnPoint: Vector4 = points[i];

    // let firstDistance = Vector4.Distance( points[i],points[i-1]);
    // let lastDrawnPoint: Vector4 = Vector4.Interpolate(points[i], points[i-1], this.timer / firstDistance);
    // this.timer += 0.01;
    // if this.timer > this.spacing {
    //   this.timer -= this.spacing;
    //   ArrayRemove(this.navPathFXs[type], this.navPathFXs[type][0]);
    // }

    while i > 0 {
      let tweenPointDistance = Vector4.Distance(points[i-1], lastDrawnPoint);
      if i == 1 {
        tweenPointDistance += this.spacing;
      }
      if tweenPointDistance >= this.spacing {
        // let rounded = Cast<Float>(RoundF(tweenPointDistance / this.spacing));
        // let tweenPointSpacing = this.spacing + (tweenPointDistance - rounded * this.spacing) / rounded;
        let lastDrawnPointInLastGroup = lastDrawnPoint;
        let distance = this.spacing;
        while distance <= tweenPointDistance {
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

// in_world_navigation/OperatorHelpers.reds

// FxResource

public static native func Cast(a: ResRef) -> FxResource;


// in_world_navigation/_MinimapContainerController.reds

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

