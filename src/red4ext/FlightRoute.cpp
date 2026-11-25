#include "FlightRoute.hpp"

#include "InWorldNavigation.hpp"
#include "MapFit.hpp"

#include <RED4ext/RTTISystem.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/ui/MinimapContainerController.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/LinePatternWidget.hpp>
#include <RED4ext/Scripting/Utils.hpp>
#include <spdlog/spdlog.h>

#include <cmath>
#include <format>
#include <string>
#include <vector>

namespace FlightRoute {

namespace {

RED4ext::DynArray<RED4ext::Vector4> points;
int32_t target = -1;
// the line's last fit was mirrored: kept when a straight route cannot tell (the minimap's y runs down the screen, so
// mirrored is the first guess)
bool lastMirrored = true;
bool warnedCount = false, warnedFit = false;
std::string status = "none";

// LTBF's FlightGuidance functions, found once the class is there
struct Guidance {
  RED4ext::CBaseFunction *hasRoute = nullptr;
  RED4ext::CBaseFunction *getRoute = nullptr;
};

const Guidance *FindGuidance() {
  static Guidance guidance;
  static bool found = false;
  if (!found) {
    auto *cls = RED4ext::CRTTISystem::Get()->GetClass("FlightGuidance");
    if (!cls) {
      return nullptr;
    }
    guidance.hasRoute = cls->GetFunction("HasRoute");
    guidance.getRoute = cls->GetFunction("GetRoute");
    found = true;
    if (guidance.hasRoute && guidance.getRoute) {
      spdlog::info("Let There Be Flight found: the arrows and the minimap follow its flight route while flying");
    } else {
      spdlog::warn("Let There Be Flight's FlightGuidance lacks HasRoute or GetRoute: its flight route is not used");
    }
  }
  return guidance.hasRoute && guidance.getRoute ? &guidance : nullptr;
}

// the "Follow flight route" setting (InWorldNavigation.followFlightRoute); on when the field is missing
bool Following() {
  static auto *prop = [] {
    auto *cls = RED4ext::CRTTISystem::Get()->GetClass("InWorldNavigation");
    return cls ? cls->GetProperty("followFlightRoute") : nullptr;
  }();
  auto instance = InWorldNavigation::GetInstance();
  return !prop || !instance || *prop->GetValuePtr<bool>(instance.GetPtr());
}

float Distance2DSquared(const RED4ext::Vector4 &aA, const RED4ext::Vector4 &aB) {
  const float dx = aA.X - aB.X, dy = aA.Y - aB.Y;
  return dx * dx + dy * dy;
}

} // namespace

int32_t Refresh(RED4ext::game::ui::MinimapContainerController *aMinimap) {
  target = -1;
  points.Clear();
  const Guidance *guidance = FindGuidance();
  bool has = false;
  RED4ext::DynArray<RED4ext::Vector4> route;
  // the status stays from the path that was redrawn until there is no route: the other path's update comes between
  if (!guidance || !Following() || !RED4ext::ExecuteFunction(nullptr, guidance->hasRoute, &has) || !has ||
      !RED4ext::ExecuteFunction(nullptr, guidance->getRoute, &route) || route.size < 2) {
    status = "none";
    return target;
  }
  points = std::move(route);
  const auto &end = points[points.size - 1];
  const auto &quest = aMinimap->questMappinPoints;
  const auto &poi = aMinimap->poiMappinPoints;
  const float questGap = quest.size >= 2 ? Distance2DSquared(quest[quest.size - 1], end) : 1e30f;
  const float poiGap = poi.size >= 2 ? Distance2DSquared(poi[poi.size - 1], end) : 1e30f;
  target = poiGap < questGap ? 1 : 0;
  return target;
}

int32_t Target() { return target; }

RED4ext::CString RedrawStatus() { return RED4ext::CString(status.c_str()); }

const RED4ext::DynArray<RED4ext::Vector4> &Points() { return points; }

bool Redraw(RED4ext::ink::LinePatternWidget *aLine, const RED4ext::DynArray<RED4ext::Vector4> &aGpsPoints) {
  if (!aLine || points.size < 2) {
    return false;
  }
  auto &vertices = aLine->vertexList;
  const uint32_t n = aGpsPoints.size;
  if (n < 2 || vertices.size != n) {
    status = std::format("vertices {} for {} points", vertices.size, n);
    if (!warnedCount && n >= 2) {
      warnedCount = true;
      spdlog::warn("The minimap's GPS line has {} vertices for {} points: the flight route is not drawn on it",
                   vertices.size, n);
    }
    return false;
  }
  std::vector<float> x(n), y(n), u(n), v(n);
  for (uint32_t i = 0; i < n; ++i) {
    x[i] = aGpsPoints[i].X;
    y[i] = aGpsPoints[i].Y;
    u[i] = vertices[i].int_.X;
    v[i] = vertices[i].int_.Y;
  }
  MapFit::Mapping mapping;
  if (!MapFit::Fit(x.data(), y.data(), u.data(), v.data(), n, lastMirrored, mapping)) {
    return false;
  }
  // a mapping the game's own vertices do not follow to within a couple of widget units is not the minimap's
  if (mapping.rms > 2.0f) {
    status = std::format("poor fit (error {:.2f})", mapping.rms);
    if (!warnedFit) {
      warnedFit = true;
      spdlog::warn(
          "The minimap's GPS line does not fit a map projection (error {:.2f}, scale {:.4f}): the flight route "
          "is not drawn on it",
          mapping.rms, mapping.Scale());
    }
    return false;
  }
  lastMirrored = mapping.mirrored;
  status = std::format("drawn {} (error {:.3f}, scale {:.4f}{})", points.size, mapping.rms, mapping.Scale(),
                       mapping.mirrored ? ", mirrored" : "");
  const auto kind = vertices[0].neType;
  vertices.Clear();
  vertices.Reserve(points.size);
  for (const auto &p : points) {
    RED4ext::ink::LineVertex vertex{};
    const MapFit::Point w = mapping.Map(p.X, p.Y);
    vertex.int_ = {w.u, w.v};
    vertex.neType = kind;
    vertices.PushBack(vertex);
  }
  return true;
}

} // namespace FlightRoute
