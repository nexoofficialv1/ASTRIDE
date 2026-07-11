import crypto from 'node:crypto';

const sessions = new Map();
const audit = [];
const failed = new Map();
const TOKEN_TTL_MS = Number(process.env.ADMIN_SESSION_TTL_MS || 8 * 3600_000);
const MAX_FAILURES = Number(process.env.ADMIN_MAX_LOGIN_FAILURES || 5);
const LOCK_MS = Number(process.env.ADMIN_LOCK_MS || 15 * 60_000);
const pepper = process.env.ADMIN_PASSWORD_PEPPER || 'development-only-pepper-change-me';

const permissions = {
  SUPER_ADMIN:['*'],
  OPERATIONS:['dashboard.read','rides.read','drivers.read','drivers.manage','complaints.read','complaints.manage','config.read','campaigns.read','campaigns.manage'],
  FINANCE:['dashboard.read','payments.read','settlements.read','settlements.manage','config.read','campaigns.read'],
  AUDITOR:['dashboard.read','rides.read','drivers.read','payments.read','settlements.read','complaints.read','config.read','audit.read','campaigns.read']
};

const hashPassword=(password,salt)=>crypto.scryptSync(`${password}${pepper}`,salt,64).toString('hex');
const safeEqual=(a,b)=>{try{return crypto.timingSafeEqual(Buffer.from(a,'hex'),Buffer.from(b,'hex'));}catch{return false;}};

function developmentUsers(){
  const defs=[
    ['admin_super','Super Admin','SUPER_ADMIN',process.env.ADMIN_USERNAME || 'admin',process.env.ADMIN_PASSWORD || 'admin123'],
    ['admin_ops','Operations','OPERATIONS',process.env.OPS_USERNAME || 'ops',process.env.OPS_PASSWORD || 'ops123'],
    ['admin_finance','Finance','FINANCE',process.env.FINANCE_USERNAME || 'finance',process.env.FINANCE_PASSWORD || 'finance123']
  ];
  return defs.map(([id,name,role,username,password])=>{const salt=crypto.createHash('sha256').update(`${id}:${username}`).digest('hex').slice(0,32);return {id,name,role,username,salt,passwordHash:hashPassword(password,salt)};});
}
const users=developmentUsers();

function isProductionUnsafe(){
 if(process.env.NODE_ENV!=='production')return false;
 const passwords=[process.env.ADMIN_PASSWORD,process.env.OPS_PASSWORD,process.env.FINANCE_PASSWORD];
 return passwords.some(value=>!value||String(value).length<12||/^(admin123|ops123|finance123)$/i.test(String(value))||/change_me|password/i.test(String(value)))||!process.env.ADMIN_PASSWORD_PEPPER||String(process.env.ADMIN_PASSWORD_PEPPER).length<32||pepper.includes('development-only');
}
function clientKey(username,clientId='unknown'){return `${username}:${clientId}`;}

export function login(username,password,clientId='unknown'){
  if(isProductionUnsafe()) return {error:'production_admin_credentials_not_configured'};
  const key=clientKey(username,clientId), state=failed.get(key);
  if(state?.lockedUntil>Date.now()) return {error:'admin_temporarily_locked',retryAfterMs:state.lockedUntil-Date.now()};
  const u=users.find(x=>x.username===username);
  const valid=u && safeEqual(hashPassword(password,u.salt),u.passwordHash);
  if(!valid){const count=(state?.count||0)+1;failed.set(key,{count,lockedUntil:count>=MAX_FAILURES?Date.now()+LOCK_MS:0});return null;}
  failed.delete(key);
  const token=crypto.randomBytes(32).toString('base64url');
  sessions.set(token,{userId:u.id,role:u.role,expiresAt:Date.now()+TOKEN_TTL_MS});
  writeAudit(u.id,'ADMIN_LOGIN',{clientId});
  return {token,expiresInSeconds:Math.floor(TOKEN_TTL_MS/1000),user:{id:u.id,name:u.name,role:u.role}};
}
export function logout(header){const token=(header||'').replace(/^Bearer\s+/i,'');return sessions.delete(token);}
export function authenticate(header){const token=(header||'').replace(/^Bearer\s+/i,'');const s=sessions.get(token);if(!s||s.expiresAt<Date.now()){if(s)sessions.delete(token);return null;}return users.find(x=>x.id===s.userId)||null;}
export function can(user,permission){const p=permissions[user?.role]||[];return p.includes('*')||p.includes(permission);}
export function writeAudit(actorId,action,payload){const item={id:crypto.randomUUID(),actorId,action,payload,createdAt:new Date().toISOString()};audit.unshift(item);if(audit.length>10000)audit.length=10000;return structuredClone(item);}
export const listAudit=()=>audit.map(x=>structuredClone(x));
export const adminSecurityStatus=()=>({productionSafe:!isProductionUnsafe(),sessionTtlSeconds:Math.floor(TOKEN_TTL_MS/1000),maxLoginFailures:MAX_FAILURES,lockSeconds:Math.floor(LOCK_MS/1000)});
