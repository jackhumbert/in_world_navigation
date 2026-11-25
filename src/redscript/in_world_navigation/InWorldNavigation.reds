// how strongly the arrows glow: each level is its own effect, its channel arrows' colour multiplier 0.5, 1, 1.5
// and 2 times Normal's (world_navigation_rgb[_dim|_bright|_brightest].effect)
enum InWorldNavigationBrightness {
  Dim = 0,
  Normal = 1,
  Bright = 2,
  Brightest = 3
}

enum InWorldNavigationMode {
  Always = 0,
  Driving = 1,
  Walking = 2
}

public native class InWorldNavigation extends IScriptable {
  public static native func GetInstance() -> ref<InWorldNavigation>;
  // true when the widget and every parent up to the HUD layer is visible with non-zero opacity
  public static native func IsWidgetTreeVisible(widget: wref<inkWidget>) -> Bool;
  // time spent in Update, measured by the UpdateGPSPath hook, for the performance check in the smoke tools:
  // "calls <n> (quest <q>, poi <p>), total <ms> ms, mean <us> us, max <us> us"
  public static native func GetUpdateStats() -> String;
  public static native func ResetUpdateStats() -> Void;
  // Let There Be Flight's route while the player flies with it (FlightRoute.hpp): the GPS path it stands in for (0 the
  // quest's, 1 the POI's), -1 when there is none (not flying, nothing tracked, or LTBF not installed)
  public static native func GetFlightTarget() -> Int32;
  // its world points, V's end first as the minimap's are; empty when GetFlightTarget is -1
  public static native func GetFlightRoute() -> array<Vector4>;
  // what the minimap's last flight redraw did: "drawn <n> (...)", "vertices <v> for <p> points", "poor fit (...)" or
  // "none"; read-only, for the in-game check
  public static native func GetFlightMinimapStatus() -> String;

  public let mmcc: ref<MinimapContainerController>;
  public let player: ref<GameObject>;
  
  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Show arrows")
  @runtimeProperty("ModSettings.description", "Can also be toggled with the key below")
  let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Toggle arrows key")
  @runtimeProperty("ModSettings.description", "Requires Input Loader")
  let inWorldNavigationToggle: EInputKey = EInputKey.IK_Semicolon;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Hide with the minimap")
  @runtimeProperty("ModSettings.description", "Hide the arrows whenever the minimap is hidden (minimap setting, Limited HUD, HUD toggles). Off: they show without the minimap. Photo mode always hides them")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let followMinimapVisibility: Bool = false;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Display mode")
  @runtimeProperty("ModSettings.displayValues", "\"Always\", \"When Driving\", \"When Walking\"")
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

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow opacity")
  @runtimeProperty("ModSettings.step", "0.05")
  @runtimeProperty("ModSettings.min", "0.05")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let opacity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow brightness")
  @runtimeProperty("ModSettings.description", "How strongly the arrows glow: raise it if they wash out in daylight")
  @runtimeProperty("ModSettings.displayValues", "\"Dim\", \"Normal\", \"Bright\", \"Brightest\"")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let brightness: InWorldNavigationBrightness = InWorldNavigationBrightness.Normal;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow size")
  @runtimeProperty("ModSettings.description", "Scales the arrows from their base on the path")
  @runtimeProperty("ModSettings.step", "0.05")
  @runtimeProperty("ModSettings.min", "0.25")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let arrowSize: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Custom arrow colour")
  @runtimeProperty("ModSettings.description", "Off: the arrows take the minimap's colour for where they lead (yellow for quests). On: every arrow uses the colour below")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let useCustomColor: Bool = false;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow colour: red")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "255")
  @runtimeProperty("ModSettings.dependency", "useCustomColor")
  let customRed: Int32 = 255;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow colour: green")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "255")
  @runtimeProperty("ModSettings.dependency", "useCustomColor")
  let customGreen: Int32 = 230;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Arrow colour: blue")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "255")
  @runtimeProperty("ModSettings.dependency", "useCustomColor")
  let customBlue: Int32 = 60;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Vertical offset")
  @runtimeProperty("ModSettings.description", "Meters to raise (or lower) the arrows from the path")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "-1.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let verticalOffset: Float = 0.0;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Hide during autodrive")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let hideInAutodrive: Bool = true;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Hide as a passenger")
  @runtimeProperty("ModSettings.description", "Hide while someone else is driving (Delamain, quest rides)")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let hideAsPassenger: Bool = true;

  @runtimeProperty("ModSettings.mod", "In-World Navigation")
  @runtimeProperty("ModSettings.displayName", "Hide on the metro")
  @runtimeProperty("ModSettings.dependency", "enabled")
  let hideOnMetro: Bool = true;

  // one arrow effect for every colour: a red, a green and a blue arrow drawn additively in the same place, each
  // one's alpha read from its own blackboard input ("red", "green", "blue"), so any colour is three floats; one
  // effect per InWorldNavigationBrightness, spawnedBrightness the one the arrows were spawned with
  let navPathResources: array<FxResource>;
  let spawnedBrightness: InWorldNavigationBrightness;

  // Per path: index 0 is the quest's, 1 the POI's (the minimap's GPS target types, the hook's argument).
  // The route as last laid out, destination first: the end that stays put while V moves, so a new route is laid
  // out again only from where it starts to differ.
  let routeRev: array<array<Vector4>>;
  // the arrows along it, destination first: position on the route (before the vertical offset), orientation, and
  // the route segment (routeRev[s] to routeRev[s + 1]) each was placed on
  let dotPos: array<array<Vector4>>;
  let dotRot: array<array<Quaternion>>;
  let dotSeg: array<array<Int32>>;
  // effect slots: arrow k is drawn by slot k % maxPoints, so V passing an arrow touches one slot, not all of them
  let slotFx: array<array<ref<FxInstance>>>;
  let slotDot: array<array<Int32>>;
  let slotPos: array<array<Vector4>>;
  let slotRot: array<array<Quaternion>>;
  let slotAlpha: array<array<Float>>;
  let slotGliding: array<array<Bool>>;
  let gliding: array<array<Int32>>;
  // drawn arrows are dots lo to count - 1 (the ones nearest V), as of the last update
  let drawnLo: array<Int32>;
  let drawnCount: array<Int32>;
  let liveArrows: array<Int32>;
  let pathColor: array<Vector4>;
  // true: start the path afresh on its next update (first draw, hidden, or a layout setting changed)
  let pathDirty: array<Bool>;
  // the settings a path was drawn with, compared on every update (Mod Settings' OnModSettingsChange did not fire
  // for accepted changes in testing): layout (spacing, max arrows, vertical offset, size) and look (opacity, fade)
  let pathLayout: array<Vector4>;
  let pathLook: array<Vector4>;

  let distanceToAnimate: Float;

  let questMappin: wref<IMappin>;
  let poiMappin: wref<IMappin>;

  let questState: CName;
  let poiState: CName;

  public func Setup(player: ref<GameObject>) -> Void {
    this.player = player;
    this.distanceToAnimate = 50.0;
    
    ArrayPush(this.navPathResources, Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_rgb_dim.effect"));
    ArrayPush(this.navPathResources, Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_rgb.effect"));
    ArrayPush(this.navPathResources, Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_rgb_bright.effect"));
    ArrayPush(this.navPathResources, Cast<FxResource>(r"user\\jackhumbert\\effects\\world_navigation_rgb_brightest.effect"));
    this.spawnedBrightness = this.brightness;

    this.questState = n"Quest";
    this.poiState = n"Gigs";

    // Setup runs on every player attach: drop what an earlier one drew
    if ArraySize(this.slotFx) == 2 {
      this.ResetPath(0);
      this.ResetPath(1);
    }
    ArrayClear(this.routeRev); ArrayClear(this.dotPos); ArrayClear(this.dotRot); ArrayClear(this.dotSeg);
    ArrayClear(this.slotFx); ArrayClear(this.slotDot); ArrayClear(this.slotPos); ArrayClear(this.slotRot);
    ArrayClear(this.slotAlpha); ArrayClear(this.slotGliding); ArrayClear(this.gliding);
    ArrayClear(this.drawnLo); ArrayClear(this.drawnCount); ArrayClear(this.liveArrows); ArrayClear(this.pathColor);
    ArrayClear(this.pathDirty); ArrayClear(this.pathLayout); ArrayClear(this.pathLook);
    let type = 0;
    while type < 2 {
      let vectors: array<Vector4>;
      let rotations: array<Quaternion>;
      let ints: array<Int32>;
      let floats: array<Float>;
      let bools: array<Bool>;
      let effects: array<ref<FxInstance>>;
      ArrayPush(this.routeRev, vectors); ArrayPush(this.dotPos, vectors); ArrayPush(this.dotRot, rotations);
      ArrayPush(this.dotSeg, ints); ArrayPush(this.slotFx, effects); ArrayPush(this.slotDot, ints);
      ArrayPush(this.slotPos, vectors); ArrayPush(this.slotRot, rotations); ArrayPush(this.slotAlpha, floats);
      ArrayPush(this.slotGliding, bools); ArrayPush(this.gliding, ints);
      ArrayPush(this.drawnLo, 0); ArrayPush(this.drawnCount, 0); ArrayPush(this.liveArrows, 0);
      ArrayPush(this.pathColor, new Vector4(0.0, 0.0, 0.0, 0.0)); ArrayPush(this.pathDirty, true);
      ArrayPush(this.pathLayout, new Vector4(0.0, 0.0, 0.0, 0.0)); ArrayPush(this.pathLook, new Vector4(0.0, 0.0, 0.0, 0.0));
      type += 1;
    }
    ModSettings.RegisterListenerToClass(this);

    // Setup runs on every player attach; unregister first so a press only toggles once
    player.UnregisterInputListener(this, n"InWorldNavigation_Toggle");
    player.RegisterInputListener(this, n"InWorldNavigation_Toggle");
  }

  // Read-only state for the in-game smoke test (cp2077_tools mods/in_world_navigation): the class is native, so
  // a test helper cannot @addMethod onto it.
  // arrows showing along the tracked quest's path: 0 with nothing tracked
  public func GetQuestArrowCount() -> Int32 {
    return IsDefined(this.questMappin) && ArraySize(this.liveArrows) > 0 ? this.liveArrows[0] : 0;
  }

  public func HasQuestMappin() -> Bool {
    return IsDefined(this.questMappin);
  }

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if Equals(ListenerAction.GetName(action), n"InWorldNavigation_Toggle") && ListenerAction.IsButtonJustPressed(action) {
      this.ToggleEnabled();
    }
  }

  // Flips the "Show arrows" setting through Mod Settings so it persists and the settings page stays in sync
  public func ToggleEnabled() -> Void {
    for configVar in ModSettings.GetVars(n"In-World Navigation", n"None") {
      if Equals(configVar.GetName(), n"enabled") {
        let boolVar = configVar as ModConfigVarBool;
        if IsDefined(boolVar) {
          boolVar.SetValue(!boolVar.GetValue());
          ModSettings.AcceptChanges();
          return;
        }
      }
    }
    // setting not found (shouldn't happen): flip the runtime value only
    this.enabled = !this.enabled;
  }

  // false in photo mode, and while the minimap is hidden if the arrows follow it. The game gives scripts no
  // whole-HUD signal (each HUD entry is hidden on its own), and many players turn the minimap off and keep
  // the arrows, so following the minimap is opt-in
  public func IsHudVisible() -> Bool {
    if GameInstance.GetPhotoModeSystem(this.player.GetGame()).IsPhotoModeActive() {
      return false;
    }
    if !this.followMinimapVisibility {
      return true;
    }
    // covers the game's minimap setting, vanilla context hiding, Limited HUD (fades the minimap root to
    // 0 opacity) and HUD toggle mods, without depending on any of them
    return InWorldNavigation.IsWidgetTreeVisible(this.mmcc.GetRootWidget());
  }

  // true while the player is along for the ride: on the metro, as a passenger, or with autodrive on
  public func IsRideHidden(isMounted: Bool) -> Bool {
    let game = this.player.GetGame();
    // the metro counts as a mounted vehicle, so check its tag (the one the game's radio and hints use) first
    if this.hideOnMetro && StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"MetroRide") {
      return true;
    }
    if !isMounted {
      return false;
    }
    if this.hideAsPassenger && !VehicleComponent.IsDriver(game, this.player) {
      return true;
    }
    if this.hideInAutodrive {
      // the blackboard the minimap watches for its autodrive highlight
      let autodrive = GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_AutodriveData);
      if IsDefined(autodrive) && autodrive.GetBool(GetAllBlackboardDefs().UI_AutodriveData.AutoDriveEnabled) {
        return true;
      }
    }
    return false;
  }

  // An arrow colour as the three channel arrows' alphas: the sRGB colour in linear light (the material's colour
  // parameter is sRGB), times the material's colour multiplier over the channel arrows' 15 (the blackboard clamps
  // to 0..1, so the brightest colour sets the channels' multiplier; the coloured arrows had 7, white 15).
  // A higher channel multiplier with smaller alphas does not work: the material thins its dots out as alpha
  // drops, per channel, so faint channels vanish first and the hue shifts (docs/history.md, 2026-11-24).
  public static func ArrowColor(r: Int32, g: Int32, b: Int32, multiplier: Float) -> Vector4 {
    let scale = multiplier / 15.0;
    return new Vector4(InWorldNavigation.SrgbToLinear(r) * scale, InWorldNavigation.SrgbToLinear(g) * scale,
      InWorldNavigation.SrgbToLinear(b) * scale, 1.0);
  }

  private static func SrgbToLinear(c: Int32) -> Float {
    let v = Cast<Float>(c) / 255.0;
    return v <= 0.04045 ? v / 12.92 : PowF((v + 0.055) / 1.055, 2.4);
  }

  // the colours of the old per-colour effects (world_navigation_<colour>.particle, before 2026-11-24)
  public static func Yellow() -> Vector4 { return InWorldNavigation.ArrowColor(255, 230, 62, 7.0); }
  public static func Teal() -> Vector4 { return InWorldNavigation.ArrowColor(0, 230, 188, 7.0); }
  public static func Blue() -> Vector4 { return InWorldNavigation.ArrowColor(0, 134, 252, 7.0); }
  public static func Cyan() -> Vector4 { return InWorldNavigation.ArrowColor(25, 215, 247, 7.0); }
  public static func FastTravelMetro() -> Vector4 { return InWorldNavigation.ArrowColor(204, 128, 255, 7.0); }
  public static func White() -> Vector4 { return InWorldNavigation.ArrowColor(255, 254, 254, 15.0); }

  // use the state the game uses to determine the color
  public func GetColorForState(state: CName) -> Vector4 {
    if this.useCustomColor {
      return InWorldNavigation.ArrowColor(this.customRed, this.customGreen, this.customBlue, 7.0);
    }
    switch (state) {
      case n"Quest":
      case n"IncendiaryGrenade":
        // ActiveYellow
        return InWorldNavigation.Yellow(); 
      case n"QuestUntracked":
        // DarkGold
        return InWorldNavigation.Yellow(); 
      case n"QuestComplete":
        // QuestComplete
        return InWorldNavigation.Yellow(); 
      case n"Gigs":
        // StreetCred
        return InWorldNavigation.Teal();
      case n"FastTravel":
        // StrongFastTravel
        return InWorldNavigation.Blue();
      case n"FastTravelMetro":
        // FastTravelMetro
        return InWorldNavigation.FastTravelMetro();
      case n"InteractionDefault":
      case n"EMPGrenade":
      case n"RemoteControlDriving":
        // ActiveBlue
        return InWorldNavigation.Cyan();
      case n"Story":
        // Blue
        return InWorldNavigation.Blue();
      case n"Default":
      case n"Impossible":
      case n"Available":
      case n"FragGrenade":
      case n"CuttingGrenade":
        // ActiveRed
        return InWorldNavigation.White();
      case n"Player":
      case n"BiohazardGrenade":
        // ActiveGreen
        return InWorldNavigation.White();
      case n"Vehicle":
      case n"VehicleForPurchase":
      case n"ServicePoint":
        // White
        return InWorldNavigation.White();
      case n"Relic":
        // Relic
        return InWorldNavigation.Teal();
      case n"Shard":
        // Shared
        return InWorldNavigation.White();
      case n"ShardRead":
        // DarkGrey
        return InWorldNavigation.White();
      case n"PlayerTracked":
        // DamageTypeChemical_Critical
        return InWorldNavigation.White();
    }
    return InWorldNavigation.White();
  }

  // Called by the hook after the minimap updates one GPS path: target 0 is the quest's, 1 the POI's.
  public func Update(target: Int32) {
    if !IsDefined(this.mmcc) || ArraySize(this.slotFx) != 2 {
      return;
    }
    let type = target == 0 ? 0 : 1;
    if NotEquals(this.spawnedBrightness, this.brightness) {
      // another effect: drop every arrow so they spawn anew
      this.spawnedBrightness = this.brightness;
      this.ResetPath(0);
      this.ResetPath(1);
    }
    let isMounted = VehicleComponent.IsMountedToVehicle(this.player.GetGame(), this.player);
    if !this.enabled || !this.IsHudVisible() || this.IsRideHidden(isMounted) ||
      (isMounted && Equals(this.mode, InWorldNavigationMode.Walking)) ||
      (!isMounted && Equals(this.mode, InWorldNavigationMode.Driving)) {
      this.ResetPath(type);
      return;
    }
    // flying with Let There Be Flight's route: the GPS path it stands in for follows it, and the other one, which
    // leads by road, hides
    let flight = InWorldNavigation.GetFlightTarget();
    if flight >= 0 {
      if type != flight {
        this.ResetPath(type);
        return;
      }
      let state: CName;
      if type == 0 {
        this.questMappin = this.mmcc.GetQuestMappin();
        state = this.questState;
      } else {
        this.poiMappin = this.mmcc.GetPOIMappin();
        state = this.poiState;
      }
      this.UpdateNavPath(type, InWorldNavigation.GetFlightRoute(), this.GetColorForState(state));
      return;
    }
    if type == 0 {
      this.questMappin = this.mmcc.GetQuestMappin();
      if IsDefined(this.questMappin) {
        this.UpdateNavPath(0, this.mmcc.questPoints, this.GetColorForState(this.questState));
      } else {
        this.ResetPath(0);
      }
    } else {
      this.poiMappin = this.mmcc.GetPOIMappin();
      if IsDefined(this.poiMappin) {
        this.UpdateNavPath(1, this.mmcc.poiPoints, this.GetColorForState(this.poiState));
      } else {
        this.ResetPath(1);
      }
    }
  }

  public func Stop() {
    if ArraySize(this.slotFx) == 2 {
      this.ResetPath(0);
      this.ResetPath(1);
    }
  }

  // Removes a path's arrows and forgets its layout; the next update starts it afresh.
  private func ResetPath(type: Int32) {
    if this.pathDirty[type] && ArraySize(this.slotFx[type]) == 0 && ArraySize(this.routeRev[type]) == 0 {
      return;
    }
    for fx in this.slotFx[type] {
      if IsDefined(fx) {
        fx.BreakLoop();
        fx.Kill();
      }
    }
    ArrayClear(this.slotFx[type]);
    ArrayClear(this.slotDot[type]);
    ArrayClear(this.slotPos[type]);
    ArrayClear(this.slotRot[type]);
    ArrayClear(this.slotAlpha[type]);
    ArrayClear(this.slotGliding[type]);
    ArrayClear(this.gliding[type]);
    ArrayClear(this.routeRev[type]);
    ArrayClear(this.dotPos[type]);
    ArrayClear(this.dotRot[type]);
    ArrayClear(this.dotSeg[type]);
    this.drawnLo[type] = 0;
    this.drawnCount[type] = 0;
    this.liveArrows[type] = 0;
    this.pathDirty[type] = true;
  }

  private func UpdateNavPath(type: Int32, points: array<Vector4>, color: Vector4) -> Void {
    let n = ArraySize(points);
    if n < 2 {
      this.ResetPath(type);
      return;
    }
    let layout = new Vector4(this.spacing, Cast<Float>(this.maxPoints), this.verticalOffset, this.arrowSize);
    let look = new Vector4(this.opacity, this.distanceToFade, 0.0, 0.0);
    let applied = this.pathLayout[type];
    if applied.X != layout.X || applied.Y != layout.Y || applied.Z != layout.Z {
      this.pathDirty[type] = true;
    }
    let resize = applied.W != layout.W;
    let relook = Vector4.DistanceSquared(look, this.pathLook[type]) > 0.0;
    this.pathLayout[type] = layout;
    this.pathLook[type] = look;
    if this.pathDirty[type] {
      this.ResetPath(type);
      this.pathDirty[type] = false;
      let slots = this.maxPoints;
      ArrayResize(this.slotFx[type], slots);
      ArrayResize(this.slotDot[type], slots);
      ArrayResize(this.slotPos[type], slots);
      ArrayResize(this.slotRot[type], slots);
      ArrayResize(this.slotAlpha[type], slots);
      ArrayResize(this.slotGliding[type], slots);
      let slot = 0;
      while slot < slots {
        this.slotDot[type][slot] = -1;
        this.slotAlpha[type][slot] = -1.0;
        this.slotGliding[type][slot] = false;
        slot += 1;
      }
      this.pathColor[type] = color;
    }
    let recolor = relook || Vector4.DistanceSquared(color, this.pathColor[type]) > 0.0;
    this.pathColor[type] = color;
    if resize {
      for fx in this.slotFx[type] {
        if IsDefined(fx) {
          fx.SetBlackboardValue(n"size", this.arrowSize * 0.5);
        }
      }
    }

    // where the new route starts to differ, counted from the destination (1 cm tolerance: the start jitters). A
    // route changes from V's end (V moving, a re-plan up to where it rejoins), so check both ends first, then walk
    // back from V's end to where the old and new routes agree.
    let old = ArraySize(this.routeRev[type]);
    let same = old;
    if old != n || Vector4.DistanceSquared(this.routeRev[type][0], points[n - 1]) >= 0.0001
      || Vector4.DistanceSquared(this.routeRev[type][n - 1], points[0]) >= 0.0001 {
      same = Min(old, n);
      while same > 0 && Vector4.DistanceSquared(this.routeRev[type][same - 1], points[n - same]) >= 0.0001 {
        same -= 1;
      }
    }
    let routeChanged = same < n || old != n;
    if !routeChanged && ArraySize(this.gliding[type]) == 0 && !recolor {
      return;
    }

    let keep = ArraySize(this.dotPos[type]);
    if routeChanged {
      ArrayResize(this.routeRev[type], n);
      let k = same;
      while k < n {
        this.routeRev[type][k] = points[n - 1 - k];
        k += 1;
      }
      // lay out again from the first segment that touches a changed point; the last segment (V's end) is laid
      // out with an extra spacing, so it is always redone when the route's length changed
      let firstSeg = same - 1;
      if old != n {
        firstSeg = Min(firstSeg, Min(old, n) - 2);
      }
      firstSeg = Max(firstSeg, 0);
      while keep > 0 && this.dotSeg[type][keep - 1] >= firstSeg {
        keep -= 1;
      }
      ArrayResize(this.dotPos[type], keep);
      ArrayResize(this.dotRot[type], keep);
      ArrayResize(this.dotSeg[type], keep);
      let lastDrawn = keep > 0 ? this.dotPos[type][keep - 1] : this.routeRev[type][0];
      let seg = firstSeg;
      while seg < n - 1 {
        let next = this.routeRev[type][seg + 1];
        let tween = Vector4.Distance(next, lastDrawn);
        if seg == n - 2 {
          tween += this.spacing;
        }
        if tween >= this.spacing {
          let groupStart = lastDrawn;
          let distance = this.spacing;
          while distance <= tween {
            let position = Vector4.Interpolate(groupStart, next, distance / tween);
            ArrayPush(this.dotRot[type], Quaternion.BuildFromDirectionVector(lastDrawn - position));
            ArrayPush(this.dotPos[type], position);
            ArrayPush(this.dotSeg[type], seg);
            lastDrawn = position;
            distance += this.spacing;
          }
        }
        seg += 1;
      }
    }

    let count = ArraySize(this.dotPos[type]);
    let slots = ArraySize(this.slotFx[type]);
    let lo = count - Min(count, slots);
    let v = this.player.GetWorldPosition();

    // slots whose arrow is no longer drawn
    if lo != this.drawnLo[type] || count != this.drawnCount[type] {
      let slot = 0;
      while slot < slots {
        let dot = this.slotDot[type][slot];
        if dot >= 0 && (dot < lo || dot >= count) {
          this.HideSlot(type, slot);
        }
        slot += 1;
      }
    }

    if recolor {
      let slot = 0;
      while slot < slots {
        this.slotAlpha[type][slot] = -1.0;
        slot += 1;
      }
    }

    // arrows newly drawn: the re-laid ones near V, and the ones the window reached at its far end
    let k = Max(lo, Min(keep, count));
    while k < count {
      this.PlaceDot(type, k, v);
      k += 1;
    }
    k = lo;
    while k < Min(this.drawnLo[type], Min(keep, count)) {
      this.PlaceDot(type, k, v);
      k += 1;
    }
    this.drawnLo[type] = lo;
    this.drawnCount[type] = count;

    // arrows still gliding to a re-planned route
    if ArraySize(this.gliding[type]) > 0 {
      let still: array<Int32>;
      for slot in this.gliding[type] {
        let dot = this.slotDot[type][slot];
        if dot < 0 {
          this.slotGliding[type][slot] = false;
        } else {
          let target = this.Lifted(this.dotPos[type][dot]);
          if Vector4.DistanceSquared(this.slotPos[type][slot], target) < 0.0001 {
            this.slotPos[type][slot] = target;
            this.slotRot[type][slot] = this.dotRot[type][dot];
            this.slotGliding[type][slot] = false;
          } else {
            this.slotPos[type][slot] = Vector4.Interpolate(this.slotPos[type][slot], target, 0.1);
            this.slotRot[type][slot] = Quaternion.Slerp(this.slotRot[type][slot], this.dotRot[type][dot], 0.1);
            ArrayPush(still, slot);
          }
          this.MoveSlot(type, slot);
        }
      }
      this.gliding[type] = still;
    }

    // colours: every arrow after a colour change, else the ones near V, where the distance fade changes
    if recolor {
      k = lo;
      while k < count {
        this.WriteAlpha(type, k % slots, v);
        k += 1;
      }
    } else {
      let reach = this.distanceToFade + 2.0 * this.spacing;
      k = count - 1;
      while k >= lo {
        let slot = k % slots;
        if Vector4.Distance2D(v, this.slotPos[type][slot]) > reach {
          break;
        }
        this.WriteAlpha(type, slot, v);
        k -= 1;
      }
    }
  }

  // the drawn position of a point on the route
  private func Lifted(p: Vector4) -> Vector4 {
    return new Vector4(p.X, p.Y, p.Z + this.verticalOffset, p.W);
  }

  // Draws dot k in its slot: a dot new to the slot jumps there, the same dot moved by a re-planned route glides.
  private func PlaceDot(type: Int32, k: Int32, v: Vector4) {
    let slot = k % ArraySize(this.slotFx[type]);
    let target = this.Lifted(this.dotPos[type][k]);
    let fx = this.slotFx[type][slot];
    let alive = IsDefined(fx) && fx.IsValid();
    if this.slotDot[type][slot] == k && alive
      && Vector4.Distance(this.slotPos[type][slot], target) < this.distanceToAnimate {
      if !this.slotGliding[type][slot] {
        this.slotGliding[type][slot] = true;
        ArrayPush(this.gliding[type], slot);
      }
      return;
    }
    this.slotDot[type][slot] = k;
    this.slotPos[type][slot] = target;
    this.slotRot[type][slot] = this.dotRot[type][k];
    this.slotAlpha[type][slot] = -1.0;
    if alive {
      this.MoveSlot(type, slot);
    } else {
      let wt: WorldTransform;
      WorldTransform.SetPosition(wt, target);
      WorldTransform.SetOrientation(wt, this.dotRot[type][k]);
      if !IsDefined(fx) {
        this.liveArrows[type] += 1;
      }
      fx = GameInstance.GetFxSystem(this.player.GetGame()).SpawnEffect(this.navPathResources[EnumInt(this.brightness)], wt);
      this.slotFx[type][slot] = fx;
      // the effect's size is 2 times its input (the blackboard clamps to 0..1), so half the scale goes in
      fx.SetBlackboardValue(n"size", this.arrowSize * 0.5);
    }
    this.WriteAlpha(type, slot, v);
  }

  private func MoveSlot(type: Int32, slot: Int32) {
    let wt: WorldTransform;
    WorldTransform.SetPosition(wt, this.slotPos[type][slot]);
    WorldTransform.SetOrientation(wt, this.slotRot[type][slot]);
    this.slotFx[type][slot].UpdateTransform(wt);
  }

  private func HideSlot(type: Int32, slot: Int32) {
    let fx = this.slotFx[type][slot];
    if IsDefined(fx) {
      fx.BreakLoop();
      fx.Kill();
      this.slotFx[type][slot] = null;
      this.liveArrows[type] -= 1;
    }
    this.slotDot[type][slot] = -1;
    this.slotAlpha[type][slot] = -1.0;
  }

  // Sends a slot's colour times its alpha (opacity and the fade near V) when it changed.
  private func WriteAlpha(type: Int32, slot: Int32, v: Vector4) {
    let fx = this.slotFx[type][slot];
    if !IsDefined(fx) {
      return;
    }
    let fade = this.distanceToFade > 0.0 ? MinF(Vector4.Distance2D(v, this.slotPos[type][slot]) / this.distanceToFade, 1.0) : 1.0;
    let alpha = fade * this.opacity;
    if AbsF(alpha - this.slotAlpha[type][slot]) > 0.002 {
      InWorldNavigation.SetArrowColor(fx, this.pathColor[type], alpha);
      this.slotAlpha[type][slot] = alpha;
    }
  }

  private static func SetArrowColor(fx: ref<FxInstance>, color: Vector4, alpha: Float) {
    fx.SetBlackboardValue(n"red", color.X * alpha);
    fx.SetBlackboardValue(n"green", color.Y * alpha);
    fx.SetBlackboardValue(n"blue", color.Z * alpha);
  }
}
