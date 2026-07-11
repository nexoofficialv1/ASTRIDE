function toRadians(value) { return (value * Math.PI) / 180; }
function distanceKm(a, b) {
  const earth = 6371;
  const dLat = toRadians(b.lat - a.lat);
  const dLng = toRadians(b.lng - a.lng);
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(toRadians(a.lat)) * Math.cos(toRadians(b.lat)) * Math.sin(dLng / 2) ** 2;
  return earth * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

export function rankDrivers(drivers, pickup, maxRadiusKm = 8) {
  return drivers
    .map((driver) => ({ ...driver, distanceKm: Number(distanceKm(driver.location, pickup).toFixed(3)) }))
    .filter((driver) => driver.distanceKm <= maxRadiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm || (b.rating || 0) - (a.rating || 0));
}
