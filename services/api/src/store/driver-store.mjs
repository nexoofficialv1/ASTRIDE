import crypto from 'node:crypto';
const drivers=new Map(); const documents=new Map(); const wallets=new Map(); const settlements=[]; const driverSessions=new Map();
const DRIVER_SESSION_TTL_MS=Number(process.env.DRIVER_SESSION_TTL_MS||24*3600_000);
const id=(p)=>`${p}_${crypto.randomUUID().slice(0,8)}`;
export function registerDriver(input){const d={id:id('drv'),mobile:input.mobile,fullName:input.fullName||'',preferredLanguage:input.preferredLanguage||'en',status:'DRAFT',approved:false,suspended:false,online:false,location:null,rating:5,totalRides:0,createdAt:new Date().toISOString(),vehicle:input.vehicle||{},primaryZoneId:input.primaryZoneId||null,operatingMode:input.operatingMode||'BOTH',seatCapacity:Number(input.seatCapacity||4),bank:input.bank||{},upiId:input.upiId||null,address:input.address||null,emergencyContact:input.emergencyContact||null,photoUrl:input.photoUrl||null,onboardingStep:input.onboardingStep||'PROFILE'};drivers.set(d.id,d);wallets.set(d.id,{driverId:d.id,balancePaise:0,lifetimeEarningsPaise:0,commissionPaidPaise:0,transactions:[]});return d;}
export const getDriverProfile=(id)=>drivers.get(id)||null;

export function createDriverSession(driverId){if(!drivers.has(driverId))throw new Error('Driver not found');const token=crypto.randomBytes(32).toString('base64url');driverSessions.set(token,{driverId,expiresAt:Date.now()+DRIVER_SESSION_TTL_MS});return {token,expiresInSeconds:Math.floor(DRIVER_SESSION_TTL_MS/1000)};}
export function authenticateDriverToken(tokenOrHeader){const token=String(tokenOrHeader||'').replace(/^Bearer\s+/i,'');const session=driverSessions.get(token);if(!session||session.expiresAt<=Date.now()){if(token)driverSessions.delete(token);return null;}const driver=drivers.get(session.driverId);return driver?{...structuredClone(driver),sessionExpiresAt:new Date(session.expiresAt).toISOString()}:null;}
export function revokeDriverSession(tokenOrHeader){const token=String(tokenOrHeader||'').replace(/^Bearer\s+/i,'');return driverSessions.delete(token);}
export function findDriverByMobile(mobile){const normalized=String(mobile||'').replace(/\D/g,'');return [...drivers.values()].find(d=>String(d.mobile||'').replace(/\D/g,'')===normalized)||null;}

export function updateDriverProfile(id,patch){const d=getDriverProfile(id);if(!d)return null;Object.assign(d,patch,{id:d.id,updatedAt:new Date().toISOString()});return d;}
export function addDriverDocument(driverId,input){if(!drivers.has(driverId))return null;const doc={id:id('doc'),driverId,type:input.type,fileUrl:input.fileUrl,number:input.number||null,expiresOn:input.expiresOn||null,status:'PENDING',remarks:null,createdAt:new Date().toISOString()};const list=documents.get(driverId)||[];list.push(doc);documents.set(driverId,list);return doc;}
export const listDriverDocuments=(driverId)=>documents.get(driverId)||[];
export function reviewDriver(driverId,{status,remarks}){const d=getDriverProfile(driverId);if(!d)return null;d.status=status;d.approved=status==='APPROVED';d.suspended=status==='SUSPENDED';d.reviewRemarks=remarks||null;d.updatedAt=new Date().toISOString();return d;}
export function setDriverOnline(driverId,{online,location}){const d=getDriverProfile(driverId);if(!d)return null;if(online&&(!d.approved||d.suspended))throw new Error('Driver is not eligible to go online');d.online=Boolean(online);d.location=location||d.location;d.lastSeenAt=new Date().toISOString();return d;}
export function creditDriver(driverId,{bookingId,grossPaise,commissionPaise}){const w=wallets.get(driverId);if(!w)throw new Error('Driver wallet not found');const netPaise=grossPaise-commissionPaise;const tx={id:id('wtx'),bookingId,type:'RIDE_EARNING',grossPaise,commissionPaise,netPaise,createdAt:new Date().toISOString()};w.balancePaise+=netPaise;w.lifetimeEarningsPaise+=netPaise;w.commissionPaidPaise+=commissionPaise;w.transactions.unshift(tx);const d=getDriverProfile(driverId);if(d)d.totalRides+=1;return tx;}
export const getDriverWallet=(driverId)=>wallets.get(driverId)||null;
export function requestSettlement(driverId,amountPaise){const w=getDriverWallet(driverId);if(!w)throw new Error('Driver wallet not found');if(amountPaise<=0||amountPaise>w.balancePaise)throw new Error('Invalid settlement amount');w.balancePaise-=amountPaise;const s={id:id('set'),driverId,amountPaise,status:'REQUESTED',createdAt:new Date().toISOString()};settlements.unshift(s);return s;}
export const listSettlements=(driverId)=>settlements.filter(x=>x.driverId===driverId);

export function updateSettlement(settlementId,status,reference=null){const s=settlements.find(x=>x.id===settlementId);if(!s)return null;if(!['APPROVED','PROCESSING','PAID','REJECTED'].includes(status))throw new Error('Invalid settlement status');s.status=status;s.reference=reference;s.updatedAt=new Date().toISOString();if(status==='REJECTED'){const w=getDriverWallet(s.driverId);if(w&&!s.reversed){w.balancePaise+=s.amountPaise;s.reversed=true;}}return s;}

export const listAllDriverProfiles=()=>[...drivers.values()].map(x=>structuredClone(x));
export const listAllSettlements=()=>settlements.map(x=>structuredClone(x));

export function exportDriverStoreState(){return {drivers:[...drivers.entries()],documents:[...documents.entries()],wallets:[...wallets.entries()],settlements:structuredClone(settlements),driverSessions:[...driverSessions.entries()]};}
export function restoreDriverStoreState(state={}){drivers.clear();documents.clear();wallets.clear();settlements.length=0;driverSessions.clear();for(const [k,v] of state.drivers||[])drivers.set(k,v);for(const [k,v] of state.documents||[])documents.set(k,v);for(const [k,v] of state.wallets||[])wallets.set(k,v);settlements.push(...(state.settlements||[]));for(const [k,v] of state.driverSessions||[])driverSessions.set(k,v);}
