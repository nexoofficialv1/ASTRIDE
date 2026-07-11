const toRad = (value) => value * Math.PI / 180;
export const distanceKm = (a, b) => {
  const earthKm = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return earthKm * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
};
export const estimateFare = ({ pickup, destination, fare }) => {
  const km = Math.max(0.1, distanceKm(pickup, destination));
  const raw = fare.baseFare + (km * fare.perKm) + fare.bookingFee;
  const amount = Math.max(fare.minimumFare, Math.ceil(raw / fare.roundTo) * fare.roundTo);
  return { distanceKm: Number(km.toFixed(2)), estimatedMinutes: Math.max(3, Math.ceil(km / fare.averageSpeedKmph * 60)), amount, currency: fare.currency, breakdown: { baseFare: fare.baseFare, distanceCharge: Number((km * fare.perKm).toFixed(2)), bookingFee: fare.bookingFee, minimumFare: fare.minimumFare } };
};
