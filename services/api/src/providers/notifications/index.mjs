import crypto from 'node:crypto';
import { getProviderCredential } from '../../config/provider-vault.mjs';

const tokenCache=new Map();
const b64=x=>Buffer.from(typeof x==='string'?x:JSON.stringify(x)).toString('base64url');
async function googleAccessToken(c){
 if(c.accessToken)return c.accessToken;
 if(!c.clientEmail||!c.privateKey)throw new Error('Firebase service-account credentials not configured');
 const cached=tokenCache.get(c.clientEmail); if(cached&&cached.expiresAt>Date.now()+60_000)return cached.token;
 const now=Math.floor(Date.now()/1000),header={alg:'RS256',typ:'JWT'},claims={iss:c.clientEmail,scope:'https://www.googleapis.com/auth/firebase.messaging',aud:'https://oauth2.googleapis.com/token',iat:now,exp:now+3600};
 const unsigned=`${b64(header)}.${b64(claims)}`;const signature=crypto.sign('RSA-SHA256',Buffer.from(unsigned),String(c.privateKey).replace(/\\n/g,'\n')).toString('base64url');
 const r=await fetch('https://oauth2.googleapis.com/token',{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion:`${unsigned}.${signature}`})});
 if(!r.ok)throw new Error(`Firebase OAuth HTTP ${r.status}`);const d=await r.json();tokenCache.set(c.clientEmail,{token:d.access_token,expiresAt:Date.now()+Number(d.expires_in||3600)*1000});return d.access_token;
}
async function firebaseSend(message,mode='test'){
 const c=getProviderCredential('notifications','firebase',mode)||{};if(mode==='test'&&!c.projectId)return {provider:'firebase',accepted:true,messageId:`fcm_test_${Date.now()}`};
 if(!c.projectId)throw new Error('Firebase projectId not configured');const accessToken=await googleAccessToken(c);
 const target=message.deviceToken?{token:message.deviceToken}:message.topic?{topic:message.topic}:null;if(!target)throw new Error('Firebase target not supplied');
 const r=await fetch(`https://fcm.googleapis.com/v1/projects/${c.projectId}/messages:send`,{method:'POST',headers:{authorization:`Bearer ${accessToken}`,'content-type':'application/json'},body:JSON.stringify({message:{...target,notification:{title:message.title||message.type,body:message.body||''},data:Object.fromEntries(Object.entries(message.payload||{}).map(([k,v])=>[k,String(v)])),android:{priority:'high',notification:{channel_id:message.channelId||'astride_rides',sound:'default'}}}})});
 if(!r.ok)throw new Error(`Firebase HTTP ${r.status}: ${await r.text()}`);const d=await r.json();return {provider:'firebase',accepted:true,messageId:d.name};
}
async function oneSignalSend(message,mode='test'){const c=getProviderCredential('notifications','onesignal',mode)||{};if(!c.appId||!c.apiKey)throw new Error('OneSignal credentials not configured');const r=await fetch('https://onesignal.com/api/v1/notifications',{method:'POST',headers:{authorization:`Basic ${c.apiKey}`,'content-type':'application/json'},body:JSON.stringify({app_id:c.appId,include_subscription_ids:[message.deviceToken],headings:{en:message.title||message.type},contents:{en:message.body||''},data:message.payload||{}})});if(!r.ok)throw new Error(`OneSignal HTTP ${r.status}`);const d=await r.json();return {provider:'onesignal',accepted:true,messageId:d.id};}
const adapters={firebase:{send:firebaseSend},onesignal:{send:oneSignalSend},mock:{async send(m){return {provider:'mock',accepted:true,messageId:`push_${m.id||Date.now()}`};}}};
export function getNotificationAdapter(name){const a=adapters[name];if(!a)throw new Error(`Unsupported notification provider: ${name}`);return a;}
