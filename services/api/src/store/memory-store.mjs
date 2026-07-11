import { randomUUID } from 'node:crypto';

const bookings = new Map();
const drivers = new Map();
const rideEvents = [];


export function createBooking(payload) {
  const id = randomUUID();
  const booking = {
    id,
    status: 'DRAFT',
    passengerId: payload.passengerId,
    pickup: payload.pickup,
    destination: payload.destination,
    paymentMethod: payload.paymentMethod || 'cash',
    language: payload.language || 'en',
    driverId: payload.driverId || null,
    rideType: payload.rideType || 'FULL_TOTO',
    shareRouteId: payload.shareRouteId || null,
    shareSessionId: payload.shareSessionId || null,
    pickupStopId: payload.pickupStopId || null,
    dropStopId: payload.dropStopId || null,
    seats: Number(payload.seats || 1),
    routeDirection: payload.routeDirection || null,
    pickupZoneId: payload.pickupZoneId || null,
    dropZoneId: payload.dropZoneId || null,
    fareEstimate: payload.fareEstimate || null,
    pickupAddress: payload.pickupAddress || null,
    destinationAddress: payload.destinationAddress || null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  bookings.set(id, booking);
  addRideEvent(id, 'BOOKING_CREATED', { status: booking.status });
  return structuredClone(booking);
}

export function listBookingsForPassenger(passengerId) { return [...bookings.values()].filter((b) => b.passengerId === passengerId).sort((a,b) => b.createdAt.localeCompare(a.createdAt)).map((value) => structuredClone(value)); }

export function getBooking(id) {
  const value = bookings.get(id);
  return value ? structuredClone(value) : null;
}

export function updateBooking(id, patch, eventType = 'BOOKING_UPDATED') {
  const current = bookings.get(id);
  if (!current) return null;
  const next = { ...current, ...patch, updatedAt: new Date().toISOString() };
  bookings.set(id, next);
  addRideEvent(id, eventType, patch);
  return structuredClone(next);
}

export function listBookingEvents(id) {
  return rideEvents.filter((event) => event.bookingId === id).map((value) => structuredClone(value));
}

export function addRideEvent(bookingId, eventType, payload = {}) {
  rideEvents.push({ id: randomUUID(), bookingId, eventType, payload, createdAt: new Date().toISOString() });
}

export function upsertDriver(id, patch) {
  const current = drivers.get(id) || { id, approved: true, online: false, location: null, updatedAt: null };
  const next = { ...current, ...patch, updatedAt: new Date().toISOString() };
  drivers.set(id, next);
  return structuredClone(next);
}

export function getDriver(id) {
  const driver = drivers.get(id);
  return driver ? structuredClone(driver) : null;
}

export function getAvailableDrivers() {
  return [...drivers.values()].filter((d) => d.approved && d.online && d.location).map((value) => structuredClone(value));
}

export function listAllBookings(){return [...bookings.values()].sort((a,b)=>b.createdAt.localeCompare(a.createdAt)).map(v=>structuredClone(v));}
export function listAllRuntimeDrivers(){return [...drivers.values()].map(v=>structuredClone(v));}

export function exportMemoryStoreState(){return {bookings:[...bookings.entries()],drivers:[...drivers.entries()],rideEvents:structuredClone(rideEvents)};}
export function restoreMemoryStoreState(state={}){bookings.clear();drivers.clear();rideEvents.length=0;for(const [k,v] of state.bookings||[])bookings.set(k,v);for(const [k,v] of state.drivers||[])drivers.set(k,v);rideEvents.push(...(state.rideEvents||[]));}
