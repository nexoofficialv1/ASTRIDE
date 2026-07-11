const tracks = new Map();
const driverHeartbeats = new Map();
const offlineQueues = new Map();

export function appendTrackingSample(bookingId, actorType, actorId, sample) {
  const item = { bookingId, actorType, actorId, ...sample, receivedAt: Date.now() };
  const list = tracks.get(bookingId) ?? [];
  list.push(item);
  if (list.length > 10000) list.splice(0, list.length - 10000);
  tracks.set(bookingId, list);
  if (actorType === 'driver') driverHeartbeats.set(actorId, item);
  return item;
}
export const listTrackingSamples = (bookingId, limit = 200) => (tracks.get(bookingId) ?? []).slice(-Math.max(1, Math.min(limit, 1000)));
export const getLatestDriverLocation = (driverId) => driverHeartbeats.get(driverId) ?? null;
export function queueOfflineSamples(deviceId, samples) {
  const list = offlineQueues.get(deviceId) ?? [];
  list.push(...samples);
  offlineQueues.set(deviceId, list.slice(-2000));
  return { queued: samples.length, totalQueued: offlineQueues.get(deviceId).length };
}
export function flushOfflineSamples(deviceId) {
  const samples = offlineQueues.get(deviceId) ?? [];
  offlineQueues.delete(deviceId);
  return samples;
}
export function trackingSnapshot(bookingId) {
  const list = tracks.get(bookingId) ?? [];
  const latestDriver = [...list].reverse().find((x) => x.actorType === 'driver') ?? null;
  const latestPassenger = [...list].reverse().find((x) => x.actorType === 'passenger') ?? null;
  return { bookingId, latestDriver, latestPassenger, points: list.length, lastUpdatedAt: Math.max(latestDriver?.receivedAt ?? 0, latestPassenger?.receivedAt ?? 0) || null };
}

export function exportTrackingStoreState(){return {tracks:[...tracks.entries()],driverHeartbeats:[...driverHeartbeats.entries()],offlineQueues:[...offlineQueues.entries()]};}
export function restoreTrackingStoreState(state={}){tracks.clear();driverHeartbeats.clear();offlineQueues.clear();for(const [k,v] of state.tracks||[])tracks.set(k,v);for(const [k,v] of state.driverHeartbeats||[])driverHeartbeats.set(k,v);for(const [k,v] of state.offlineQueues||[])offlineQueues.set(k,v);}
