import crypto from 'node:crypto';
const otpSessions = new Map();
const otpRate = new Map();
const passengerProfiles = new Map();
const savedPlaces = new Map();
const ratings = [];
const complaints = [];
const passengerSessions = new Map();
const PASSENGER_SESSION_TTL_MS = Number(process.env.PASSENGER_SESSION_TTL_MS || 24 * 3600_000);
export const createOtp = (mobile) => { const normalized=String(mobile).replace(/\D/g,''); if(normalized.length<10||normalized.length>15)throw new Error('Invalid mobile number'); const now=Date.now(),windowMs=15*60*1000,current=(otpRate.get(normalized)||[]).filter(x=>x>now-windowMs); if(current.length>=5)throw new Error('OTP request limit exceeded; retry later'); if(current.length&&now-current.at(-1)<30*1000)throw new Error('Please wait before requesting another OTP'); current.push(now);otpRate.set(normalized,current); const sessionId = crypto.randomUUID(); const code = String(crypto.randomInt(100000,1000000)); otpSessions.set(sessionId, { mobile:normalized, codeHash:crypto.createHash('sha256').update(`${sessionId}:${code}`).digest('hex'), expiresAt: now + 5 * 60 * 1000, verified: false, attempts: 0, maxAttempts: 5, createdAt: now }); return { sessionId, code }; };
export const verifyOtp = (sessionId, code) => { const item = otpSessions.get(sessionId); if (!item || item.verified || item.expiresAt < Date.now() || item.attempts >= item.maxAttempts) return null; item.attempts += 1; const candidate=crypto.createHash('sha256').update(`${sessionId}:${String(code)}`).digest('hex'); if(item.codeHash !== candidate) return null; item.verified = true; const id = `passenger_${item.mobile.replace(/\D/g, '')}`; const profile = passengerProfiles.get(id) || { id, mobile: item.mobile, fullName: null, preferredLanguage: 'en', createdAt: new Date().toISOString() }; passengerProfiles.set(id, profile); return profile; };
export function createPassengerSession(passengerId){
  const token=crypto.randomBytes(32).toString('base64url');
  passengerSessions.set(token,{passengerId,expiresAt:Date.now()+PASSENGER_SESSION_TTL_MS});
  return {token,expiresInSeconds:Math.floor(PASSENGER_SESSION_TTL_MS/1000)};
}
export function authenticatePassengerToken(tokenOrHeader){
  const token=String(tokenOrHeader||'').replace(/^Bearer\s+/i,'');
  const session=passengerSessions.get(token);
  if(!session||session.expiresAt<=Date.now()){if(token)passengerSessions.delete(token);return null;}
  const passenger=passengerProfiles.get(session.passengerId);
  return passenger?{...structuredClone(passenger),sessionExpiresAt:new Date(session.expiresAt).toISOString()}:null;
}
export function revokePassengerSession(tokenOrHeader){const token=String(tokenOrHeader||'').replace(/^Bearer\s+/i,'');return passengerSessions.delete(token);}

export const upsertPassenger = (id, patch) => { const current = passengerProfiles.get(id) || { id, createdAt: new Date().toISOString() }; const next = { ...current, ...patch, updatedAt: new Date().toISOString() }; passengerProfiles.set(id, next); return next; };
export const getPassenger = (id) => passengerProfiles.get(id) || null;
export const listPlaces = (id) => savedPlaces.get(id) || [];
export const addPlace = (id, place) => { const list = savedPlaces.get(id) || []; const next = { id: crypto.randomUUID(), label: place.label, address: place.address, location: place.location, createdAt: new Date().toISOString() }; savedPlaces.set(id, [...list, next]); return next; };
export const addRating = (payload) => { const item = { id: crypto.randomUUID(), ...payload, createdAt: new Date().toISOString() }; ratings.push(item); return item; };
export const addComplaint = (payload) => { const item = { id: crypto.randomUUID(), status: 'OPEN', priority: payload.category === 'SAFETY' ? 'URGENT' : 'NORMAL', ...payload, createdAt: new Date().toISOString() }; complaints.push(item); return item; };

export const listAllComplaints=()=>complaints.map(x=>structuredClone(x));
export function updateComplaint(id,patch){const x=complaints.find(c=>c.id===id);if(!x)return null;Object.assign(x,patch,{updatedAt:new Date().toISOString()});return structuredClone(x);}

export function exportPassengerStoreState(){return {otpSessions:[...otpSessions.entries()],otpRate:[...otpRate.entries()],passengerProfiles:[...passengerProfiles.entries()],savedPlaces:[...savedPlaces.entries()],ratings:structuredClone(ratings),complaints:structuredClone(complaints),passengerSessions:[...passengerSessions.entries()]};}
export function restorePassengerStoreState(state={}){otpSessions.clear();otpRate.clear();passengerProfiles.clear();savedPlaces.clear();ratings.length=0;complaints.length=0;passengerSessions.clear();for(const [k,v] of state.otpSessions||[])otpSessions.set(k,v);for(const [k,v] of state.otpRate||[])otpRate.set(k,v);for(const [k,v] of state.passengerProfiles||[])passengerProfiles.set(k,v);for(const [k,v] of state.savedPlaces||[])savedPlaces.set(k,v);ratings.push(...(state.ratings||[]));complaints.push(...(state.complaints||[]));for(const [k,v] of state.passengerSessions||[])passengerSessions.set(k,v);}
