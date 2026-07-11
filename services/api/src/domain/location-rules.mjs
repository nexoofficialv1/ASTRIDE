export const isValidCoordinate = ({ lat, lng } = {}) =>
  Number.isFinite(lat) && Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

export function validateLocationSample(sample, previous = null, config = {}) {
  if (!isValidCoordinate(sample)) throw new Error('Invalid GPS coordinates');
  const accuracyM = Number(sample.accuracyM ?? 9999);
  if (!Number.isFinite(accuracyM) || accuracyM < 0) throw new Error('Invalid GPS accuracy');
  const recordedAt = Number(sample.recordedAt ?? Date.now());
  if (!Number.isFinite(recordedAt)) throw new Error('Invalid GPS timestamp');
  if (accuracyM > Number(config.maxAcceptedAccuracyM ?? 100)) throw new Error('GPS accuracy is too low');
  if (previous && recordedAt <= previous.recordedAt) throw new Error('Out-of-order GPS sample');
  return { lat: sample.lat, lng: sample.lng, accuracyM, heading: Number(sample.heading ?? 0), speedMps: Number(sample.speedMps ?? 0), recordedAt };
}
