#pragma once

// The world-to-widget mapping of the minimap's GPS line (FlightRoute.hpp), fitted to pairs of world points (x, y)
// and the line's vertices the game made of them: a rotation, a uniform scale and an offset, mirrored or not. Pure
// code, tested offline (tests/map_fit_tests.cpp).

#include <cstdint>

namespace MapFit {

struct Point {
  float u = 0.0f, v = 0.0f;
};

struct Mapping {
  float ax = 0.0f, ay = 0.0f; // the complex factor: rotation and scale
  float bx = 0.0f, by = 0.0f; // the offset, widget units
  bool mirrored = false;      // the world's y runs the other way on the widget
  float rms = 0.0f;           // the fit's error, widget units

  // the widget point of world (x, y)
  Point Map(float aX, float aY) const;
  // widget units per world metre
  float Scale() const;
};

// Fits a mapping to aCount pairs (x, y) -> (u, v): the least squares fit, plain and mirrored, the better one, or
// aPreferMirrored's when the points cannot tell them apart (all on one line). False for fewer than two distinct
// points.
bool Fit(const float *aX, const float *aY, const float *aU, const float *aV, uint32_t aCount, bool aPreferMirrored,
         Mapping &aOut);

} // namespace MapFit
