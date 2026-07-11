import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const vaultFile = process.env.PROVIDER_VAULT_FILE || path.resolve(process.env.ASTRIDE_DATA_DIR || 'data', 'provider-vault.json');
const master = process.env.PROVIDER_CREDENTIALS_MASTER_KEY || process.env.PROVIDER_CREDENTIAL_KEY || 'development-only-key';
const key = crypto.createHash('sha256').update(master).digest();
const secrets = new Map();
const id=(type,name,mode='test')=>`${type}:${name}:${mode}`;

function loadVault(){
  try{if(!fs.existsSync(vaultFile))return;const rows=JSON.parse(fs.readFileSync(vaultFile,'utf8'));for(const [k,v] of Object.entries(rows||{}))secrets.set(k,v);}catch(error){throw new Error(`Provider vault could not be loaded: ${error.message}`);}
}
function persistVault(){
  const dir=path.dirname(vaultFile);fs.mkdirSync(dir,{recursive:true});const temp=`${vaultFile}.tmp`;
  fs.writeFileSync(temp,JSON.stringify(Object.fromEntries(secrets),null,2),{mode:0o600});fs.renameSync(temp,vaultFile);try{fs.chmodSync(vaultFile,0o600);}catch{}
}
loadVault();
export function putProviderCredential(type,name,mode,payload){
  const iv=crypto.randomBytes(12);const cipher=crypto.createCipheriv('aes-256-gcm',key,iv);
  const encrypted=Buffer.concat([cipher.update(JSON.stringify(payload),'utf8'),cipher.final()]);
  const value={iv:iv.toString('base64'),tag:cipher.getAuthTag().toString('base64'),data:encrypted.toString('base64'),updatedAt:new Date().toISOString()};
  secrets.set(id(type,name,mode),value);persistVault();return {type,name,mode,configured:true,updatedAt:value.updatedAt};
}
export function getProviderCredential(type,name,mode='test'){
  const x=secrets.get(id(type,name,mode));if(!x)return null;
  const decipher=crypto.createDecipheriv('aes-256-gcm',key,Buffer.from(x.iv,'base64'));decipher.setAuthTag(Buffer.from(x.tag,'base64'));
  return JSON.parse(Buffer.concat([decipher.update(Buffer.from(x.data,'base64')),decipher.final()]).toString('utf8'));
}
export function getPublicProviderClientConfig(appType='passenger'){
  const firebase=getProviderCredential('notifications','firebase','live')||getProviderCredential('notifications','firebase','test');
  if(!firebase)return {firebase:null};
  const perApp=firebase.clients?.[appType]||firebase.client||firebase;
  const allowed=['apiKey','appId','messagingSenderId','projectId','authDomain','storageBucket','measurementId'];
  const clean={};for(const key of allowed)if(perApp?.[key])clean[key]=perApp[key];
  return {firebase:Object.keys(clean).length>=4?clean:null};
}
export function listCredentialStatus(){return [...secrets.entries()].map(([k,v])=>{const [type,name,mode]=k.split(':');return {type,name,mode,configured:true,updatedAt:v.updatedAt};});}
export function deleteProviderCredential(type,name,mode='test'){const deleted=secrets.delete(id(type,name,mode));if(deleted)persistVault();return deleted;}
export function providerVaultStatus(){return {file:vaultFile,persistent:true,count:secrets.size};}
