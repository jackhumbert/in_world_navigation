// The minimap's world-to-widget mapping fitted from the game's own GPS points and line vertices (MapFit.hpp).
#include "Check.hpp"

#include "MapFit.hpp"

#include <cmath>
#include <vector>

using namespace MapFit;

namespace {

// a minimap-like projection: scale s, the map turned by angle a (radians), y down the screen, centred on (cx, cy)
struct Projection {
  float s, a, cx, cy, ox, oy;
  Point operator()(float aX, float aY) const {
    const float dx = aX - cx, dy = aY - cy;
    const float rx = std::cos(a) * dx - std::sin(a) * dy, ry = std::sin(a) * dx + std::cos(a) * dy;
    return {ox + s * rx, oy - s * ry};
  }
};

struct Pairs {
  std::vector<float> x, y, u, v;
  void Add(float aX, float aY, Point aW) {
    x.push_back(aX);
    y.push_back(aY);
    u.push_back(aW.u);
    v.push_back(aW.v);
  }
  uint32_t Size() const { return uint32_t(x.size()); }
};

// a winding GPS route
Pairs Route(const Projection &aP) {
  Pairs out;
  for (int i = 0; i < 40; ++i) {
    const float t = float(i) * 10.0f;
    const float x = -412.0f + t, y = 522.0f + 30.0f * std::sin(t / 60.0f) + 0.2f * t;
    out.Add(x, y, aP(x, y));
  }
  return out;
}

} // namespace

TEST(map_fit_finds_the_minimaps_projection) {
  const Projection p{1.6f, 0.7f, -400.0f, 530.0f, 275.0f, 200.0f};
  const Pairs pairs = Route(p);
  Mapping m;
  CHECK(Fit(pairs.x.data(), pairs.y.data(), pairs.u.data(), pairs.v.data(), pairs.Size(), false, m));
  CHECK(m.mirrored);
  CHECK(m.rms < 0.01f);
  CHECK_NEAR(m.Scale(), 1.6, 1e-3);
  // a point off the route maps where the projection puts it
  const Point want = p(-300.0f, 700.0f), got = m.Map(-300.0f, 700.0f);
  CHECK_NEAR(got.u, want.u, 0.01);
  CHECK_NEAR(got.v, want.v, 0.01);
}

TEST(map_fit_plain_when_not_mirrored) {
  Pairs pairs;
  for (int i = 0; i < 10; ++i) {
    const float x = float(i * 7 % 10), y = float(i * i % 13);
    pairs.Add(x, y, {2.0f * x + 5.0f, 2.0f * y - 3.0f});
  }
  Mapping m;
  CHECK(Fit(pairs.x.data(), pairs.y.data(), pairs.u.data(), pairs.v.data(), pairs.Size(), true, m));
  CHECK(!m.mirrored);
  CHECK(m.rms < 0.01f);
}

TEST(map_fit_straight_route_keeps_the_preference) {
  // on one line both fits are exact: the preferred one is kept
  const Projection p{1.0f, 0.3f, 0.0f, 0.0f, 0.0f, 0.0f};
  Pairs pairs;
  for (int i = 0; i < 10; ++i) {
    const float x = float(i) * 10.0f, y = float(i) * 5.0f;
    pairs.Add(x, y, p(x, y));
  }
  Mapping mirrored, plain;
  CHECK(Fit(pairs.x.data(), pairs.y.data(), pairs.u.data(), pairs.v.data(), pairs.Size(), true, mirrored));
  CHECK(Fit(pairs.x.data(), pairs.y.data(), pairs.u.data(), pairs.v.data(), pairs.Size(), false, plain));
  CHECK(mirrored.mirrored);
  CHECK(!plain.mirrored);
  CHECK(mirrored.rms < 0.01f && plain.rms < 0.01f);
}

TEST(map_fit_rejects_too_few_points) {
  float x[2] = {1.0f, 1.0f}, y[2] = {2.0f, 2.0f}, u[2] = {3.0f, 4.0f}, v[2] = {5.0f, 6.0f};
  Mapping m;
  CHECK(!Fit(x, y, u, v, 1, true, m));
  // two points in one place: no direction to fit
  CHECK(!Fit(x, y, u, v, 2, true, m));
}

TEST(map_fit_reports_a_poor_fit) {
  // vertices that are no projection of the points: a large error, which Redraw refuses
  Pairs pairs;
  for (int i = 0; i < 20; ++i) {
    pairs.Add(float(i), float(i % 3), {float((i * 37) % 11) * 20.0f, float((i * 17) % 7) * 20.0f});
  }
  Mapping m;
  CHECK(Fit(pairs.x.data(), pairs.y.data(), pairs.u.data(), pairs.v.data(), pairs.Size(), true, m));
  CHECK(m.rms > 2.0f);
}
