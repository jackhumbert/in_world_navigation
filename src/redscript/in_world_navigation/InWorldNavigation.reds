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
  @runtimeProperty("ModSettings.displayValues.Always", "Always")
  @runtimeProperty("ModSettings.displayValues.Driving", "When Driving")
  @runtimeProperty("ModSettings.displayValues.Walking", "When Walking")

  @runtimeProperty("ModSettings.dependency", "enabled")
  let mode: InWorldNavigationMode = InWorldNavigationMode.Driving;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow spacing")
  @runtimeProperty("ModSettings.description", "In-game units between arrows")
  @runtimeProperty("ModSettings.step", "0.5")
  @runtimeProperty("ModSettings.min", "0.5")
  @runtimeProperty("ModSettings.max", "20.0")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let spacing: Float = 5.0;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Max number of arrows")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "10")
  @runtimeProperty("ModSettings.max", "2000")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let maxPoints: Int32 = 200;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Distance within arrows will fade")
  @runtimeProperty("ModSettings.description", "Measures from player")
  @runtimeProperty("ModSettings.step", "1.0")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "100.0")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let distanceToFade: Float = 25.0;

  let navPathFXs: array<array<ref<FxInstance>>>;
  let navPathTransforms: array<array<Transform>>;

  let navPathYellowResource: FxResource;
  let navPathBlueResource: FxResource;
  let navPathWhiteResource: FxResource;
  let navPathTealResource: FxResource;
  let navPathCyanResource: FxResource;
  let navPathFastTravelMetroResource: FxResource;

  let distanceToAnimate: Float;

  let questMappin: wref<IMappin>;
  let poiMappin: wref<IMappin>;

  let questState: CName;
  let poiState: CName;

  let currentQuestState: CName;
  let currentPoiState: CName;

  public func Setup(player: ref<GameObject>) -> Void {
    this.player = player;
    this.distanceToAnimate = 50.0;
    
    this.navPathYellowResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_yellow.effect");
    this.navPathBlueResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_blue.effect");
    this.navPathWhiteResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_white.effect");
    this.navPathTealResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_teal.effect");
    this.navPathCyanResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_cyan.effect");
    this.navPathFastTravelMetroResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\fast_travel_metro.effect");

    let questFx: array<ref<FxInstance>>;
    let poiFx: array<ref<FxInstance>>;
    ArrayPush(this.navPathFXs, questFx);
    ArrayPush(this.navPathFXs, poiFx);

    this.questState = n"Quest";
    this.poiState = n"Gigs";

    let questTransforms: array<Transform>;
    let poisTransforms: array<Transform>;
    ArrayPush(this.navPathTransforms, questTransforms);
    ArrayPush(this.navPathTransforms, poisTransforms);
    ModSettings.RegisterListenerToClass(this);
  }

  // use the state the game uses to determine the color
  public func GetResourceForState(state: CName) -> FxResource {
    switch (state) {
      case n"Quest":
      case n"IncendiaryGrenade":
        // ActiveYellow
        return this.navPathYellowResource; 
      case n"QuestUntracked":
        // DarkGold
        return this.navPathYellowResource; 
      case n"QuestComplete":
        // QuestComplete
        return this.navPathYellowResource; 
      case n"Gigs":
        // StreetCred
        return this.navPathTealResource;
      case n"FastTravel":
        // StrongFastTravel
        return this.navPathBlueResource;
      case n"FastTravelMetro":
        // FastTravelMetro
        return this.navPathFastTravelMetroResource;
      case n"InteractionDefault":
      case n"EMPGrenade":
      case n"RemoteControlDriving":
        // ActiveBlue
        return this.navPathCyanResource;
      case n"Story":
        // Blue
        return this.navPathBlueResource;
      case n"Default":
      case n"Impossible":
      case n"Available":
      case n"FragGrenade":
      case n"CuttingGrenade":
        // ActiveRed
        return this.navPathWhiteResource;
      case n"Player":
      case n"BiohazardGrenade":
        // ActiveGreen
        return this.navPathWhiteResource;
      case n"Vehicle":
      case n"VehicleForPurchase":
      case n"ServicePoint":
        // White
        return this.navPathWhiteResource;
      case n"Relic":
        // Relic
        return this.navPathTealResource;
      case n"Shard":
        // Shared
        return this.navPathWhiteResource;
      case n"ShardRead":
        // DarkGrey
        return this.navPathWhiteResource;
      case n"PlayerTracked":
        // DamageTypeChemical_Critical
        return this.navPathWhiteResource;
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
        this.questMappin = this.mmcc.GetQuestMappin();
        if IsDefined(this.questMappin) {
          if !Equals(this.currentQuestState, this.questState) {
            this.currentQuestState = this.questState;
            this.UpdateNavPath(0, this.mmcc.questPoints, this.GetResourceForState(this.currentQuestState), true);
          } else {
            this.UpdateNavPath(0, this.mmcc.questPoints, this.GetResourceForState(this.currentQuestState), false);
          }
        } else {     
          for fx in this.navPathFXs[0] {
            fx.BreakLoop();
          }
        }
        this.poiMappin = this.mmcc.GetPOIMappin();
        if IsDefined(this.poiMappin) {
          if !Equals(this.currentPoiState, this.poiState) {
            this.currentPoiState = this.poiState;
            this.UpdateNavPath(1, this.mmcc.poiPoints, this.GetResourceForState(this.currentPoiState), true);
          } else {
            this.UpdateNavPath(1, this.mmcc.poiPoints, this.GetResourceForState(this.currentPoiState), false);
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
