#include "MapFit.hpp"

#include <algorithm>
#include <cmath>

namespace MapFit {

namespace {

// The complex least squares fit w = a z + b, with z mirrored (x - iy) when aMirror.
bool FitOne(const float *aX, const float *aY, const float *aU, const float *aV, uint32_t aCount, bool aMirror,
            Mapping &aOut) {
  double zx = 0, zy = 0, wx = 0, wy = 0;
  for (uint32_t i = 0; i < aCount; ++i) {
    zx += aX[i];
    zy += aMirror ? -aY[i] : aY[i];
    wx += aU[i];
    wy += aV[i];
  }
  zx /= aCount;
  zy /= aCount;
  wx /= aCount;
  wy /= aCount;
  double nre = 0, nim = 0, den = 0;
  for (uint32_t i = 0; i < aCount; ++i) {
    const double dzx = aX[i] - zx, dzy = (aMirror ? -aY[i] : aY[i]) - zy;
    const double dwx = aU[i] - wx, dwy = aV[i] - wy;
    nre += dwx * dzx + dwy * dzy;
    nim += dwy * dzx - dwx * dzy;
    den += dzx * dzx + dzy * dzy;
  }
  if (den < 1e-6) {
    return false;
  }
  const double ax = nre / den, ay = nim / den;
  aOut.ax = float(ax);
  aOut.ay = float(ay);
  aOut.bx = float(wx - (ax * zx - ay * zy));
  aOut.by = float(wy - (ax * zy + ay * zx));
  aOut.mirrored = aMirror;
  double err = 0;
  for (uint32_t i = 0; i < aCount; ++i) {
    const Point w = aOut.Map(aX[i], aY[i]);
    err += double(w.u - aU[i]) * (w.u - aU[i]) + double(w.v - aV[i]) * (w.v - aV[i]);
  }
  aOut.rms = float(std::sqrt(err / aCount));
  return true;
}

} // namespace

Point Mapping::Map(float aX, float aY) const {
  const float y = mirrored ? -aY : aY;
  return {ax * aX - ay * y + bx, ax * y + ay * aX + by};
}

float Mapping::Scale() const { return std::hypot(ax, ay); }

bool Fit(const float *aX, const float *aY, const float *aU, const float *aV, uint32_t aCount, bool aPreferMirrored,
         Mapping &aOut) {
  if (aCount < 2) {
    return false;
  }
  Mapping plain, mirrored;
  if (!FitOne(aX, aY, aU, aV, aCount, false, plain) || !FitOne(aX, aY, aU, aV, aCount, true, mirrored)) {
    return false;
  }
  // on one line both fit alike: keep the preferred one unless the other is clearly better
  const float tie = 0.1f * std::min(plain.rms, mirrored.rms) + 0.05f;
  if (std::abs(plain.rms - mirrored.rms) <= tie) {
    aOut = aPreferMirrored ? mirrored : plain;
  } else {
    aOut = plain.rms < mirrored.rms ? plain : mirrored;
  }
  return true;
}

} // namespace MapFit
