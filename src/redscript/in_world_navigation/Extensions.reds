
// BaseMappinBaseController: Default

// @wrapMethod(BaseWorldMapMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "BaseWorldMapMappinController " + NameToString(state));
//   return state;
// }
//   let mappinsGroup: wref<MappinsGroup_Record>;
//   let stateName: CName;
//   let variant: gamedataMappinVariant;
//   if this.m_isCompletedPhase {
//     stateName = n"QuestComplete";
//   };
//   if Equals(this.m_mappin.GetVariant(), gamedataMappinVariant.Zzz17_NCARTVariant) {
//     stateName = n"FastTravelMetro";
//   } else {
//     if this.m_mappin != null {
//       mappinsGroup = MappinUtils.GetMappinsGroup(this.m_mappin.GetVariant());
//       variant = this.m_mappin.GetVariant();
//       if Equals(variant, gamedataMappinVariant.Zzz16_RelicDeviceBasicVariant) {
//         stateName = n"Relic";
//       } else {
//         if IsDefined(mappinsGroup) {
//           stateName = mappinsGroup.WidgetState();
//         };
//       };
//     };
//   };
//   if Equals(stateName, n"None") {
//     stateName = n"Quest";
//   };
//   return stateName;
// }

// WorldMapPlayerMappinController : Player

// WATCH for QUEST

@wrapMethod(QuestMappinController)
protected func ComputeRootState() -> CName {
  let state = wrappedMethod();
  if IsDefined(InWorldNavigation.GetInstance().questMappin) && this.m_mappin == InWorldNavigation.GetInstance().questMappin {
    // LogChannel(n"DEBUG", "Quest: " + NameToString(state));
    InWorldNavigation.GetInstance().questState = state;
  }
  if IsDefined(InWorldNavigation.GetInstance().poiMappin) && this.m_mappin == InWorldNavigation.GetInstance().poiMappin {
    // LogChannel(n"DEBUG", "POI: " + NameToString(state));
    InWorldNavigation.GetInstance().poiState = state;
  }
  return state;
}

// private func ComputeRootState() -> CName {
//   let grenadeData: ref<GrenadeMappinData>;
//   let grenadeType: EGrenadeType;
//   let mappinsGroup: wref<MappinsGroup_Record>;
//   let stateName: CName;
//   let variant: gamedataMappinVariant;
//   if this.m_isCompletedPhase {
//     stateName = n"QuestComplete";
//   } else {
//     if this.m_mappin != null {
//       variant = this.m_mappin.GetVariant();
//       if this.m_mappin.IsExactlyA(n"gamemappinsGrenadeMappin") {
//         grenadeData = this.m_mappin.GetScriptData() as GrenadeMappinData;
//         grenadeType = grenadeData.m_grenadeType;
//         switch grenadeType {
//           case EGrenadeType.Frag:
//             stateName = n"FragGrenade";
//             break;
//           case EGrenadeType.Flash:
//             stateName = n"FlashGrenade";
//             break;
//           case EGrenadeType.Piercing:
//             stateName = n"PiercingGrenade";
//             break;
//           case EGrenadeType.EMP:
//             stateName = n"EMPGrenade";
//             break;
//           case EGrenadeType.Biohazard:
//             stateName = n"BiohazardGrenade";
//             break;
//           case EGrenadeType.Incendiary:
//             stateName = n"IncendiaryGrenade";
//             break;
//           case EGrenadeType.Recon:
//             stateName = n"ReconGrenade";
//             break;
//           case EGrenadeType.Cutting:
//             stateName = n"CuttingGrenade";
//             break;
//           case EGrenadeType.Sonic:
//             stateName = n"SonicGrenade";
//             break;
//           default:
//             stateName = n"FragGrenade";
//         };
//       } else {
//         if this.m_mappin.IsExactlyA(n"gamemappinsInteractionMappin") {
//           stateName = this.m_mappin.IsQuestImportant() ? n"Quest" : n"InteractionDefault";
//         } else {
//           if Equals(variant, gamedataMappinVariant.Zzz10_RemoteControlDrivingVariant) {
//             stateName = n"RemoteControlDriving";
//           } else {
//             if Equals(variant, gamedataMappinVariant.Zzz17_NCARTVariant) {
//               stateName = n"FastTravelMetro";
//             } else {
//               if Equals(variant, gamedataMappinVariant.Zzz16_RelicDeviceBasicVariant) {
//                 stateName = n"Relic";
//               } else {
//                 mappinsGroup = MappinUtils.GetMappinsGroup(this.m_mappin.GetVariant());
//                 if IsDefined(mappinsGroup) {
//                   stateName = mappinsGroup.WidgetState();
//                 };
//               };
//             };
//           };
//         };
//       };
//     };
//   };
//   if Equals(stateName, n"None") {
//     stateName = n"Quest";
//   };
//   return stateName;
// }

// @wrapMethod(GameplayMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "GameplayMappinController " + NameToString(state));
//   return state;
// }
// private func ComputeRootState() -> CName {
//   let returnValue: CName;
//   let visualState: EMappinVisualState = this.GetMappinVisualState();
//   let quality: gamedataQuality = this.GetQuality();
//   if this.IsShardRead() {
//     returnValue = n"ShardRead";
//   } else {
//     if this.IsQuest() {
//       returnValue = n"Quest";
//     } else {
//       if NotEquals(quality, gamedataQuality.Invalid) && NotEquals(quality, gamedataQuality.Random) {
//         if this.IsIconic() {
//           returnValue = n"Iconic";
//         } else {
//           switch quality {
//             case gamedataQuality.Common:
//               returnValue = n"Common";
//               break;
//             case gamedataQuality.Epic:
//               returnValue = n"Epic";
//               break;
//             case gamedataQuality.Legendary:
//               returnValue = n"Legendary";
//               break;
//             case gamedataQuality.Rare:
//               returnValue = n"Rare";
//               break;
//             case gamedataQuality.Uncommon:
//               returnValue = n"Uncommon";
//               break;
//             case gamedataQuality.Iconic:
//               returnValue = n"Iconic";
//               break;
//             default:
//               returnValue = n"Default";
//           };
//         };
//       } else {
//         switch visualState {
//           case EMappinVisualState.Inactive:
//             returnValue = n"Inactive";
//             break;
//           case EMappinVisualState.Available:
//             returnValue = n"Available";
//             break;
//           case EMappinVisualState.Unavailable:
//             returnValue = n"Unavailable";
//             break;
//           case EMappinVisualState.Default:
//             returnValue = n"Default";
//         };
//       };
//     };
//   };
//   if this.ShouldBeClamped() {
//     returnValue = n"Distraction";
//   };
//   this.UpdateVisibilityThroughWalls();
//   return returnValue;
// }

// @wrapMethod(MinimapStealthMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "MinimapStealthMappinController " + NameToString(state));
//   return state;
// }
// protected func ComputeRootState() -> CName {
//   return this.m_mappinState;
// }

  // protected final func GetPreventionMapinState() -> CName {
  //   let puppet: ref<ScriptedPuppet> = this.m_stealthMappin.GetGameObject() as ScriptedPuppet;
  //   let isInCombatWithPlayer: Bool = IsDefined(puppet) ? NPCPuppet.IsInCombatWithTarget(puppet, GetPlayerObject(puppet.GetGame())) : this.m_stealthMappin.IsInCombat();
  //   if this.m_isAlive && IsDefined(this.m_stealthMappin) {
  //     if isInCombatWithPlayer {
  //       return n"Prevention_Red";
  //     };
  //     return n"Prevention_LightBlue";
  //   };
  //   return n"Prevention_Blue";
  // }

// MinimapQuestMappinController: Quest
// MinimapQuestAreaMappinController: Quest

// @wrapMethod(MinimapDeviceMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "MinimapDeviceMappinController " + NameToString(state));
//   return state;
// }
// private func ComputeRootState() -> CName {
//   let quality: gamedataQuality;
//   let returnValue: CName;
//   let visualState: EMappinVisualState;
//   let gameplayRoleData: ref<GameplayRoleMappinData> = this.GetVisualData();
//   if IsDefined(gameplayRoleData) {
//     visualState = gameplayRoleData.m_mappinVisualState;
//     quality = gameplayRoleData.m_quality;
//     if gameplayRoleData.m_isQuest {
//       returnValue = n"Quest";
//     } else {
//       if Equals(gameplayRoleData.m_gameplayRole, EGameplayRole.ExplodeLethal) {
//         returnValue = n"Explosion";
//       } else {
//         if NotEquals(quality, gamedataQuality.Invalid) && NotEquals(quality, gamedataQuality.Random) {
//           switch quality {
//             case gamedataQuality.Common:
//               returnValue = n"Common";
//               break;
//             case gamedataQuality.Epic:
//               returnValue = n"Epic";
//               break;
//             case gamedataQuality.Legendary:
//               returnValue = n"Legendary";
//               break;
//             case gamedataQuality.Rare:
//               returnValue = n"Rare";
//               break;
//             case gamedataQuality.Uncommon:
//               returnValue = n"Uncommon";
//               break;
//             default:
//               returnValue = n"Default";
//           };
//         } else {
//           switch visualState {
//             case EMappinVisualState.Inactive:
//               returnValue = n"Inactive";
//               break;
//             case EMappinVisualState.Available:
//               returnValue = n"Available";
//               break;
//             case EMappinVisualState.Unavailable:
//               returnValue = n"Unavailable";
//               break;
//             case EMappinVisualState.Default:
//               returnValue = n"Default";
//           };
//         };
//       };
//     };
//   };
//   return returnValue;
// }

// WATCH for POI

// @wrapMethod(MinimapPOIMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "MinimapPOIMappinController " + NameToString(state));
//   return state;
// }
// protected func ComputeRootState() -> CName {
//   let mappinsGroup: wref<MappinsGroup_Record>;
//   let stateName: CName;
//   let variant: gamedataMappinVariant;
//   if this.m_isCompletedPhase {
//     stateName = n"QuestComplete";
//   } else {
//     if this.m_mappin != null {
//       variant = this.m_mappin.GetVariant();
//       if Equals(variant, gamedataMappinVariant.Zzz17_NCARTVariant) {
//         stateName = n"FastTravelMetro";
//       } else {
//         if Equals(variant, gamedataMappinVariant.Zzz16_RelicDeviceBasicVariant) {
//           stateName = n"Relic";
//         } else {
//           mappinsGroup = MappinUtils.GetMappinsGroup(this.m_mappin.GetVariant());
//           if IsDefined(mappinsGroup) {
//             stateName = mappinsGroup.WidgetState();
//           };
//         };
//       };
//     };
//   };
//   if Equals(stateName, n"None") {
//     stateName = n"Quest";
//   };
//   return stateName;
// }


// @wrapMethod(MinimapPreventionVehicleMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "MinimapPreventionVehicleMappinController " + NameToString(state));
//   return state;
// }
// protected func ComputeRootState() -> CName {
//   return this.m_mappinState;
// }

    // if this.m_isMaxTacAV || this.m_playerWanted && VehicleComponent.HasPassengersWithThreatOnPlayer(this.m_vehicle.GetGame(), this.m_vehicle.GetEntityID()) {
    //   this.m_mappinState = n"Prevention_Red";
    // } else {
    //   this.m_mappinState = n"Prevention_LightBlue";
    // };

// @wrapMethod(MinimapDynamicEventMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "MinimapDynamicEventMappinController " + NameToString(state));
//   return state;
// }
// protected func ComputeRootState() -> CName {
//   return Equals(this.m_mappin.GetVariant(), gamedataMappinVariant.Zzz09_CourierSandboxActivityVariant) ? n"Gigs" : n"Default";
// }

// @wrapMethod(MinimapStubMappinController)
// protected func ComputeRootState() -> CName {
//   let state = wrappedMethod();
//   LogChannel(n"DEBUG", "MinimapStubMappinController " + NameToString(state));
//   return state;
// }
// protected func ComputeRootState() -> CName {
//   return this.m_state;
// }

  // private final func SetupStubWidget() -> Void {
  //   let type: gameStubMappinType = this.m_stubMappin.GetStubMappinType();
  //   if Equals(type, gameStubMappinType.Police) {
  //     this.m_state = n"Prevention_LightBlue";
  //     inkImageRef.SetTexturePart(this.iconWidget, n"enemyMappin-1");
  //     this.PlayLibraryAnimation(n"Show");
  //   } else {
  //     if Equals(type, gameStubMappinType.PoliceVehicle) {
  //       this.m_state = n"Prevention_LightBlue";
  //       inkWidgetRef.SetVisible(this.m_regularIconContainer, false);
  //       inkWidgetRef.SetVisible(this.m_preventionVehicleIconContainer, true);
  //       this.m_aboveWidget.SetMargin(0.00, 0.00, 0.00, 48.00);
  //       this.m_belowWidget.SetMargin(0.00, 48.00, 0.00, 0.00);
  //       this.PlayLibraryAnimation(n"Show");
  //     } else {
  //       if Equals(type, gameStubMappinType.Vehicle) {
  //         this.m_state = n"Neutral_Aggressive";
  //         inkImageRef.SetTexturePart(this.iconWidget, n"enemyMappin-1");
  //         this.PlayLibraryAnimation(n"Show");
  //       } else {
  //         this.m_state = n"Neutral_Aggressive";
  //         inkImageRef.SetTexturePart(this.iconWidget, n"enemyMappin");
  //       };
  //     };
  //   };
  // }