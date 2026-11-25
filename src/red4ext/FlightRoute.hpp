#pragma once

// Let There Be Flight's route, when it is installed: while the player flies with something tracked, LTBF publishes
// the route it plans to the destination (its native class FlightGuidance), and the arrows and the minimap's GPS line
// follow that in place of the road route. LTBF is looked up through RTTI each frame, so nothing here needs it to be
// built or installed: without it there is never a flight route.

#include <RED4ext/Common.hpp>
#include <RED4ext/Scripting/Natives/Generated/Vector4.hpp>

#include <cstdint>

namespace RED4ext::game::ui {
struct MinimapContainerController;
}
namespace RED4ext::ink {
struct LinePatternWidget;
}

namespace FlightRoute {

// Reads LTBF's route and decides which of the minimap's GPS paths it stands in for (0 the quest's, 1 the POI's): the
// one whose destination is nearest the route's end, the quest's when neither has a path. Called by the hook before
// each GPS path's update. Returns that path, or -1 when there is no flight route.
int32_t Refresh(RED4ext::game::ui::MinimapContainerController *aMinimap);
// as the last Refresh decided
int32_t Target();
// the route's world points, V's end first (as the minimap's GPS points are); empty without a route
const RED4ext::DynArray<RED4ext::Vector4> &Points();

// Draws the GPS line along the flight route, after the game drew it along aGpsPoints: the mapping is fitted to the
// game's points and the line's vertices this frame (MapFit.hpp). False, with the line left as the game drew it, when
// they cannot be paired (another count) or the fit is poor.
bool Redraw(RED4ext::ink::LinePatternWidget *aLine, const RED4ext::DynArray<RED4ext::Vector4> &aGpsPoints);
// what the last Redraw did, for the in-game check and the log: "drawn <n> (error <e>, scale <s>)", "vertices <v> for
// <p> points", "poor fit (error <e>)", or "none"
RED4ext::CString RedrawStatus();

} // namespace FlightRoute
