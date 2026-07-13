import http from 'node:http';
import fs from 'node:fs';
import pathModule from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import { getAdminRuntimeConfig, getPublicRuntimeConfig, updateRuntimeConfig } from './config/runtime-config.mjs';
import { getMapAdapter } from './providers/maps/index.mjs';
import { getPaymentAdapter } from './providers/payments/index.mjs';
import { getOtpAdapter } from './providers/otp/index.mjs';
import { withFallback } from './providers/common/with-fallback.mjs';
import { assertTransition } from './domain/booking-machine.mjs';
import { rankDrivers } from './domain/driver-matching.mjs';
import { estimateFare } from './domain/fare-engine.mjs';
import { createBooking, getBooking, updateBooking, acceptBooking, listBookingEvents, listBookingsForPassenger, upsertDriver, getDriver, getAvailableDrivers, listAllBookings, listAllRuntimeDrivers } from './store/memory-store.mjs';
import { createOtp, verifyOtp, createPassengerSession, authenticatePassengerToken, revokePassengerSession, upsertPassenger, getPassenger, listPlaces, addPlace, addRating, addComplaint, listAllComplaints, updateComplaint } from './store/passenger-store.mjs';
import { registerDriver, getDriverProfile, updateDriverProfile, addDriverDocument, listDriverDocuments, reviewDriver, setDriverOnline, getDriverWallet, creditDriver, requestSettlement, listSettlements, updateSettlement, listAllDriverProfiles, listAllSettlements, createDriverSession, authenticateDriverToken, revokeDriverSession, findDriverByMobile } from './store/driver-store.mjs';
import { onboardingReadiness, calculateDriverEarning } from './domain/driver-rules.mjs';
import { validateLocationSample } from './domain/location-rules.mjs';
import { createPayment, getPayment, getPaymentByBooking, updatePayment, addRefund, listRefunds, listPaymentLedger, listAllPayments, findPaymentByProviderOrder, findPaymentByProviderPayment, recordWebhookEvent, listWebhookEvents, addReconciliation, listReconciliations } from './store/payment-store.mjs';
import { getNotificationAdapter } from './providers/notifications/index.mjs';
import { putProviderCredential, listCredentialStatus, deleteProviderCredential, getPublicProviderClientConfig, providerVaultStatus } from './config/provider-vault.mjs';
import { registerDevice, deactivateDevice, listDevices, allDevices } from './store/device-store.mjs';
import { createSos, updateSos, listSos, getSos, addNotification, updateNotification, listNotifications, addRiskEvent, listRiskEvents, hitRateLimit } from './store/safety-store.mjs';
import { calculateFareQuote, calculateCommissionSplit, driverMatchesPayment, serviceAvailability, evaluateLateArrival } from './domain/astride-business-rules.mjs';
import { upsertPromoter, updatePromoterProfile, getPromoter, listPromoters, linkDriver, getDriverPartnerLink, scopedDriverIds, addCoachingLog, listCoachingLogs, addPromoterEarning, earningsSummary, promoterDashboard, driverPerformanceRows, releaseMonthlyEarnings, requestPromoterWithdrawal, listPartnerWithdrawals, partnerLogin, authenticatePartner, partnerLogout } from './store/promoter-store.mjs';
import { createStaffAccount, updateStaffAccount, listStaffAccounts, staffLogin, authenticateStaffToken, revokeStaffSession, changeStaffPassword, adminResetStaffPassword, createPasswordReset, verifyPasswordReset } from './store/staff-auth-store.mjs';
import { ensurePassengerWallet, walletSummary, listWalletTransactions, creditPassengerWallet, debitPassengerWallet, refundPassengerWallet, referralProfile, applyReferralCode, listReferralHistory, referralRewards, completeReferralFirstRide, adminReferralOverview } from './store/passenger-wallet-referral-store.mjs';
import { setProfileMedia, getProfileMedia, createSupportIssue, listSupportIssues, updateSupportIssue } from './store/profile-support-store.mjs';
import { evaluateBookingRisk, evaluateRouteDeviation } from './domain/safety-rules.mjs';
import { evaluateZoneContext, validateRideAgainstZone, haversineKm } from './domain/zone-engine.mjs';
import { upsertZone, listZones, getZone, removeZone } from './store/zone-store.mjs';
import { upsertShareRoute,listShareRoutes,getShareRoute,removeShareRoute,setDriverSharePermissions,getDriverSharePermissions,driverCanOperateShareRoute,findOpenShareSession,createShareSession,getShareSession,listShareSessions,addBookingToShareSession,updateShareBookingStatus,updateShareSession,getShareTimeline } from './store/share-pooling-store.mjs';
import { nearestRouteStop, canPoolBooking } from './domain/share-pooling-engine.mjs';
import { login as adminLogin, logout as adminLogout, authenticate as authenticateAdmin, can as adminCan, writeAudit, listAudit, adminSecurityStatus } from './store/admin-store.mjs';
import { databaseHealth, databaseMode } from './db/postgres.mjs';
import { initializePersistence, schedulePersistenceFlush, flushPersistence, persistenceStatus } from './db/persistence-coordinator.mjs';
import { attachRideWebSocket } from './realtime/websocket-gateway.mjs';
import { redisHealth } from './realtime/redis-client.mjs';
import { productionReadiness, assertProductionReady } from './config/production-readiness.mjs';
import { upsertCampaign,getCampaign,listCampaigns,removeCampaign,setCampaignStatus,validateOfferCode,listEligibleCampaigns,recordCampaignEvent,redeemOfferCode,listCampaignRedemptions,campaignSummary } from './store/campaign-store.mjs';
import { appendTrackingSample, listTrackingSamples, getLatestDriverLocation, queueOfflineSamples, flushOfflineSamples, trackingSnapshot } from './store/tracking-store.mjs';
const adminWebRoot=fileURLToPath(
  new URL('../../../apps/admin_control_console/',import.meta.url),
);
const uploadRoot=pathModule.resolve(
  process.env.PROFILE_UPLOAD_DIR ||
  pathModule.join(
    process.env.ASTRIDE_DATA_DIR || pathModule.join(process.cwd(),'data'),
    'uploads',
  ),
);
const allowedUploadMime={
  'image/jpeg':'.jpg',
  'image/png':'.png',
  'image/webp':'.webp',
};
const safeUploadSegment=(value)=>String(value||'')
  .replace(/[^A-Za-z0-9_.-]/g,'_')
  .slice(0,120);
const staticContentTypes={
  '.html':'text/html; charset=utf-8',
  '.css':'text/css; charset=utf-8',
  '.js':'application/javascript; charset=utf-8',
  '.json':'application/json; charset=utf-8',
  '.svg':'image/svg+xml',
  '.png':'image/png',
  '.jpg':'image/jpeg',
  '.jpeg':'image/jpeg',
  '.ico':'image/x-icon',
  '.webp':'image/webp',
};
const sendStaticFile=(res,filePath)=>{
  try{
    const resolved=pathModule.resolve(filePath);
    const root=pathModule.resolve(adminWebRoot);
    if(!resolved.startsWith(root))return false;
    if(!fs.existsSync(resolved)||!fs.statSync(resolved).isFile())return false;
    const ext=pathModule.extname(resolved).toLowerCase();
    res.writeHead(200,{
      'content-type':staticContentTypes[ext]||'application/octet-stream',
      'cache-control':ext==='.html'?'no-store':'public, max-age=300',
    });
    fs.createReadStream(resolved).pipe(res);
    return true;
  }catch{return false;}
};
const json=(res,status,body)=>{res.writeHead(status,{'content-type':'application/json; charset=utf-8','cache-control':'no-store'});res.end(JSON.stringify(body));};
const readRawBody=async(req)=>{const chunks=[];for await(const chunk of req)chunks.push(chunk);return Buffer.concat(chunks).toString('utf8');};
const readBody=async(req)=>{const raw=await readRawBody(req);return raw?JSON.parse(raw):{};};
const requireFields=(p,fields)=>{for(const f of fields)if(p[f]===undefined||p[f]===null)throw new Error(`Missing field: ${f}`);};
const validPoint=(p)=>p&&typeof p.lat==='number'&&typeof p.lng==='number';
export const server=http.createServer(async(req,res)=>{res.once('finish',schedulePersistenceFlush);try{const url=new URL(req.url,'http://localhost');const path=url.pathname;
if(req.method==='GET'&&(path==='/'||path==='/admin'||path==='/admin/')){
  if(sendStaticFile(res,pathModule.join(adminWebRoot,'index.html')))return;
  return json(res,503,{error:'admin_console_not_deployed'});
}
if(req.method==='GET'&&path.startsWith('/admin/')){
  const relative=path.slice('/admin/'.length);
  if(relative&&!relative.includes('..')){
    if(sendStaticFile(res,pathModule.join(adminWebRoot,relative)))return;
  }
}

const passengerUser=authenticatePassengerToken(req.headers.authorization);
const staffUser=authenticateStaffToken(req.headers.authorization);
const staffDriverProfile=staffUser?.role==='DRIVER'&&staffUser.linkedEntityId?getDriverProfile(staffUser.linkedEntityId):null;
const driverUser=authenticateDriverToken(req.headers.authorization)||staffDriverProfile;
const requirePassenger=(id=null)=>{if(!passengerUser){json(res,401,{error:'passenger_auth_required'});return false;}if(id&&passengerUser.id!==id){json(res,403,{error:'passenger_scope_denied'});return false;}return true;};
const requireDriver=(id=null)=>{if(!driverUser){json(res,401,{error:'driver_auth_required'});return false;}if(id&&driverUser.id!==id){json(res,403,{error:'driver_scope_denied'});return false;}return true;};
const canAccessBooking=(b)=>Boolean(b&&(adminUser&&adminCan(adminUser,'rides.read')||passengerUser&&b.passengerId===passengerUser.id||driverUser&&b.driverId===driverUser.id));
if(req.method==='GET'&&path==='/health')return json(res,200,{ok:true,service:'local-ride-api',version:'3.15.0-final-market-test',architecture:'mobile-first'});if(req.method==='GET'&&/^\/v1\/uploads\/[^/]+\/[^/]+\/[^/]+$/.test(path)){
  const parts=path.split('/');
  const actorType=safeUploadSegment(parts[3]).toLowerCase();
  const actorId=safeUploadSegment(parts[4]);
  const fileName=safeUploadSegment(parts[5]);
  const base=pathModule.resolve(uploadRoot,actorType,actorId);
  const target=pathModule.resolve(base,fileName);
  if(!target.startsWith(base)||!fs.existsSync(target)){
    return json(res,404,{error:'upload_not_found'});
  }
  const ext=pathModule.extname(target).toLowerCase();
  res.writeHead(200,{
    'content-type':staticContentTypes[ext]||'application/octet-stream',
    'cache-control':'public, max-age=86400',
  });
  fs.createReadStream(target).pipe(res);
  return;
}

if(req.method==='GET'&&path==='/ready'){const readiness=productionReadiness();const database=await databaseHealth(),realtime=await redisHealth();const ok=readiness.ready&&database.ok!==false&&realtime.ok!==false;return json(res,ok?200:503,{ok,service:'local-ride-api',version:'3.15.0-final-market-test',readiness,database,realtime,adminSecurity:adminSecurityStatus()});}
if(req.method==='POST'&&/^\/v1\/payments\/webhooks\/[^/]+$/.test(path)){const provider=path.split('/')[4],cfg=getAdminRuntimeConfig();if(!['razorpay','bharatpe'].includes(provider))return json(res,404,{error:'unsupported_payment_provider'});const rawBody=await readRawBody(req);const result=await getPaymentAdapter(provider).verifyWebhook({headers:req.headers,rawBody,mode:cfg.providers.payments.mode});const payloadHash=crypto.createHash('sha256').update(rawBody).digest('hex');const recorded=recordWebhookEvent({provider,eventId:result.eventId,eventType:result.eventType,verified:result.verified,payloadHash,status:result.verified?'PROCESSED':'REJECTED'});if(recorded.duplicate)return json(res,200,{accepted:true,duplicate:true,eventId:result.eventId});if(!result.verified)return json(res,401,{error:'invalid_webhook_signature'});const entity=result.payload?.payload?.payment?.entity||result.payload?.payment||result.payload?.data||result.payload;const orderId=entity?.order_id||entity?.orderId||entity?.providerOrderId;const paymentId=entity?.id||entity?.payment_id||entity?.providerPaymentId;const payment=findPaymentByProviderOrder(provider,orderId)||findPaymentByProviderPayment(provider,paymentId);if(payment&&['payment.captured','PAYMENT_SUCCESS','payment.success'].includes(result.eventType)){updatePayment(payment.id,{status:'CAPTURED',providerPaymentId:paymentId||payment.providerPaymentId},'WEBHOOK_PAYMENT_CAPTURED');}return json(res,200,{accepted:true,duplicate:false,eventId:result.eventId});}
if(req.method==='GET'&&path==='/v1/staff-auth/me'){
  if(!staffUser)return json(res,401,{error:'staff_auth_required'});
  return json(res,200,{staff:staffUser});
}
if(req.method==='POST'&&path==='/v1/staff-auth/login'){
  const p=await readBody(req);requireFields(p,['identity','password']);
  const out=staffLogin(p);
  if(out?.error)return json(res,423,out);
  return out?json(res,200,out):json(res,401,{error:'invalid_staff_credentials'});
}
if(req.method==='POST'&&path==='/v1/staff-auth/logout'){
  return json(res,200,{ok:revokeStaffSession(req.headers.authorization)});
}
if(req.method==='POST'&&path==='/v1/staff-auth/change-password'){
  if(!staffUser)return json(res,401,{error:'staff_auth_required'});
  const p=await readBody(req);requireFields(p,['currentPassword','newPassword']);
  try{
    const staff=changeStaffPassword(
      staffUser.id,
      p.currentPassword,
      p.newPassword,
      req.headers.authorization,
    );
    return json(res,200,{ok:true,staff,mustChangePassword:false});
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='POST'&&path==='/v1/staff-auth/forgot-password/request'){
  const p=await readBody(req);requireFields(p,['identity']);
  const challenge=createPasswordReset(p.identity);
  if(!challenge)return json(res,200,{accepted:true});
  const cfg=getAdminRuntimeConfig();
  const sent=await getOtpAdapter(cfg.providers.otp.active).send(
    challenge.mobile,
    challenge.code,
    cfg.providers.otp.mode,
  );
  return json(res,200,{
    accepted:true,
    challengeId:challenge.challengeId,
    expiresInSeconds:challenge.expiresInSeconds,
    delivery:sent,
  });
}
if(req.method==='POST'&&path==='/v1/staff-auth/forgot-password/verify'){
  const p=await readBody(req);
  requireFields(p,['challengeId','code','newPassword']);
  try{
    const staff=verifyPasswordReset(
      p.challengeId,
      p.code,
      p.newPassword,
    );
    return staff
      ?json(res,200,{ok:true})
      :json(res,401,{error:'invalid_or_expired_reset_code'});
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='POST'&&path==='/v1/partner/auth/login'){const p=await readBody(req);requireFields(p,['mobile','password']);const out=partnerLogin(p);return out?json(res,200,out):json(res,401,{error:'invalid_partner_credentials'});}
if(req.method==='POST'&&path==='/v1/partner/auth/logout'){return json(res,200,{ok:partnerLogout(req.headers.authorization)});}
const legacyPartnerUser=path.startsWith('/v1/partner/')?authenticatePartner(req.headers.authorization):null;
const staffPartnerProfile=staffUser&&['PROMOTER','AREA_PROMOTER'].includes(staffUser.role)&&staffUser.linkedEntityId?getPromoter(staffUser.linkedEntityId):null;
const partnerUser=legacyPartnerUser||staffPartnerProfile;
const requirePartner=()=>{if(!partnerUser){json(res,401,{error:'partner_auth_required'});return false;}return true;};
if(req.method==='GET'&&path==='/v1/partner/me'){if(!requirePartner())return;return json(res,200,{partner:partnerUser});}if(req.method==='PATCH'&&path==='/v1/partner/me'){
  if(!requirePartner())return;
  const updated=updatePromoterProfile(partnerUser.id,await readBody(req));
  return updated
    ?json(res,200,{partner:updated})
    :json(res,404,{error:'partner_not_found'});
}
if(req.method==='POST'&&path==='/v1/uploads'){
  const actor=passengerUser
    ?{type:'passenger',id:passengerUser.id}
    :driverUser
      ?{type:'driver',id:driverUser.id}
      :partnerUser
        ?{type:'partner',id:partnerUser.id}
        :null;
  if(!actor)return json(res,401,{error:'authentication_required'});

  const p=await readBody(req);
  requireFields(p,['fileName','mimeType','base64']);
  const extension=allowedUploadMime[String(p.mimeType||'').toLowerCase()];
  if(!extension)return json(res,422,{error:'unsupported_upload_type'});

  let bytes;
  try{bytes=Buffer.from(String(p.base64),'base64');}
  catch{return json(res,422,{error:'invalid_upload_data'});}
  if(!bytes.length||bytes.length>3*1024*1024){
    return json(res,422,{error:'upload_size_limit_exceeded'});
  }

  const category=safeUploadSegment(p.category||'file').toLowerCase();
  const actorId=safeUploadSegment(actor.id);
  const directory=pathModule.resolve(uploadRoot,actor.type,actorId);
  fs.mkdirSync(directory,{recursive:true});
  const fileName=`${category}_${Date.now()}_${crypto.randomUUID().slice(0,8)}${extension}`;
  const target=pathModule.resolve(directory,fileName);
  if(!target.startsWith(directory)){
    return json(res,422,{error:'invalid_upload_path'});
  }
  fs.writeFileSync(target,bytes);
  return json(res,201,{
    url:`/v1/uploads/${actor.type}/${encodeURIComponent(actorId)}/${encodeURIComponent(fileName)}`,
    mimeType:p.mimeType,
    sizeBytes:bytes.length,
  });
}

if(req.method==='GET'&&path==='/v1/partner/dashboard'){if(!requirePartner())return;const out=promoterDashboard(partnerUser.id,{bookings:listAllBookings(),runtimeDrivers:listAllRuntimeDrivers(),from:url.searchParams.get('from'),to:url.searchParams.get('to')});return json(res,200,out);}
if(req.method==='GET'&&path==='/v1/partner/drivers'){if(!requirePartner())return;const items=driverPerformanceRows(partnerUser.id,{bookings:listAllBookings(),runtimeDrivers:listAllRuntimeDrivers(),profiles:listAllDriverProfiles(),from:url.searchParams.get('from'),to:url.searchParams.get('to')});return json(res,200,{items});}
if(req.method==='POST'&&path==='/v1/partner/coaching'){if(!requirePartner())return;const p=await readBody(req);requireFields(p,['driverId','type','message']);if(!scopedDriverIds(partnerUser.id).includes(p.driverId))return json(res,403,{error:'driver_outside_scope'});return json(res,201,addCoachingLog({promoterId:partnerUser.id,areaPromoterId:partnerUser.role==='AREA_PROMOTER'?partnerUser.id:null,...p}));}
if(req.method==='GET'&&path==='/v1/partner/coaching'){if(!requirePartner())return;return json(res,200,{items:listCoachingLogs(partnerUser.id)});}
if(req.method==='GET'&&path==='/v1/partner/earnings'){if(!requirePartner())return;return json(res,200,earningsSummary(partnerUser.id,url.searchParams.get('month')));}
if(req.method==='GET'&&path==='/v1/partner/withdrawals'){if(!requirePartner())return;return json(res,200,{items:listPartnerWithdrawals(partnerUser.id)});}
if(req.method==='POST'&&path==='/v1/partner/withdrawals'){if(!requirePartner())return;const p=await readBody(req);requireFields(p,['amount']);const out=requestPromoterWithdrawal(partnerUser.id,Number(p.amount));return out.error?json(res,422,out):json(res,201,out);}
if(req.method==='POST'&&path==='/v1/admin/auth/login'){const p=await readBody(req);requireFields(p,['username','password']);const clientId=req.headers['x-forwarded-for']||req.socket.remoteAddress||'unknown';const result=adminLogin(p.username,p.password,String(clientId));if(result?.error)return json(res,503,result);return result?json(res,200,result):json(res,401,{error:'invalid_admin_credentials'});}
if(req.method==='POST'&&path==='/v1/admin/auth/logout'){const ok=adminLogout(req.headers.authorization);return json(res,200,{ok});}
const adminUser=path.startsWith('/v1/admin/')?authenticateAdmin(req.headers.authorization):null;
const requireAdmin=(permission)=>{if(!adminUser){json(res,401,{error:'admin_auth_required'});return false;}if(!adminCan(adminUser,permission)){json(res,403,{error:'admin_permission_denied'});return false;}return true;};
if(req.method==='GET'&&path==='/v1/admin/referrals'){
  if(!requireAdmin('dashboard.read')&&!adminCan(adminUser,'*'))return;
  return json(res,200,adminReferralOverview());
}
if(req.method==='GET'&&path==='/v1/admin/staff'){
  if(!requireAdmin('drivers.read')&&!adminCan(adminUser,'*'))return;
  return json(res,200,{items:listStaffAccounts()});
}
if(req.method==='POST'&&path==='/v1/admin/drivers/create'){
  if(!requireAdmin('drivers.manage')&&!adminCan(adminUser,'*'))return;
  const p=await readBody(req);
  requireFields(p,['mobile','fullName','temporaryPassword']);
  try{
    const driver=registerDriver({
      mobile:p.mobile,
      fullName:p.fullName,
      preferredLanguage:p.preferredLanguage||'en',
      vehicle:p.vehicle||{},
      primaryZoneId:p.primaryZoneId||null,
      bank:p.bank||{},
      emergencyContact:p.emergencyContact||null,
    });
    const staff=createStaffAccount({
      role:'DRIVER',
      mobile:p.mobile,
      loginId:p.loginId||driver.id,
      name:p.fullName,
      password:p.temporaryPassword,
      linkedEntityId:driver.id,
      areaId:p.areaId||null,
      createdBy:adminUser.id,
      mustChangePassword:true,
    });
    if(p.promoterId)linkDriver({
      promoterId:p.promoterId,
      areaPromoterId:p.areaPromoterId||null,
      driverId:driver.id,
    });
    writeAudit(adminUser.id,'DRIVER_STAFF_CREATED',{
      driverId:driver.id,
      staffId:staff.id,
    });
    return json(res,201,{driver,staff});
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='POST'&&path==='/v1/admin/partners/create'){
  if(!requireAdmin('dashboard.read')&&!adminCan(adminUser,'*'))return;
  const p=await readBody(req);
  requireFields(p,['mobile','name','role','temporaryPassword']);
  try{
    const partner=upsertPromoter({
      role:p.role,
      mobile:p.mobile,
      name:p.name,
      status:'ACTIVE',
      areaPromoterId:p.areaPromoterId||null,
    });
    const staff=createStaffAccount({
      role:p.role,
      mobile:p.mobile,
      loginId:p.loginId||partner.id,
      name:p.name,
      password:p.temporaryPassword,
      linkedEntityId:partner.id,
      areaId:p.areaId||null,
      createdBy:adminUser.id,
      mustChangePassword:true,
    });
    writeAudit(adminUser.id,'PARTNER_STAFF_CREATED',{
      partnerId:partner.id,
      staffId:staff.id,
    });
    return json(res,201,{partner,staff});
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='POST'&&/^\/v1\/admin\/staff\/[^/]+\/reset-password$/.test(path)){
  if(!requireAdmin('drivers.manage')&&!adminCan(adminUser,'*'))return;
  const p=await readBody(req);requireFields(p,['temporaryPassword']);
  try{
    const staff=adminResetStaffPassword(path.split('/')[4],p.temporaryPassword);
    if(!staff)return json(res,404,{error:'staff_not_found'});
    writeAudit(adminUser.id,'STAFF_PASSWORD_RESET',{staffId:staff.id});
    return json(res,200,{staff});
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='PATCH'&&/^\/v1\/admin\/staff\/[^/]+$/.test(path)){
  if(!requireAdmin('drivers.manage')&&!adminCan(adminUser,'*'))return;
  const p=await readBody(req);
  const staff=updateStaffAccount(path.split('/')[4],p);
  return staff?json(res,200,{staff}):json(res,404,{error:'staff_not_found'});
}


if(req.method==='POST'&&path==='/v1/safety/sos'){if(!passengerUser&&!driverUser)return json(res,401,{error:'authentication_required'});const cfg=getAdminRuntimeConfig(),p=await readBody(req);if(!cfg.safety.sosEnabled||!cfg.features.sos)return json(res,503,{error:'sos_disabled'});requireFields(p,['actorType','actorId','location']);if(p.actorType==='passenger'&&(!passengerUser||passengerUser.id!==p.actorId))return json(res,403,{error:'sos_actor_mismatch'});if(p.actorType==='driver'&&(!driverUser||driverUser.id!==p.actorId))return json(res,403,{error:'sos_actor_mismatch'});if(!validPoint(p.location))throw new Error('Invalid SOS location');const item=createSos({...p,bookingId:p.bookingId||null,emergencyNumber:cfg.safety.emergencyNumber});const n=addNotification({audience:'SAFETY_TEAM',type:'SOS_ALERT',payload:{incidentId:item.id,location:item.location}});const sent=await getNotificationAdapter(cfg.providers.notifications.active).send(n,cfg.providers.notifications.mode);updateNotification(n.id,{status:sent.accepted?'SENT':'FAILED',attempts:1,provider:sent.provider});addRiskEvent({type:'SOS_TRIGGERED',severity:'CRITICAL',actorId:p.actorId,bookingId:p.bookingId||null,metadata:{incidentId:item.id}});return json(res,201,item);}
if(req.method==='GET'&&/^\/v1\/safety\/sos\/[^/]+$/.test(path)){if(!passengerUser&&!driverUser&&!adminUser)return json(res,401,{error:'authentication_required'});const item=getSos(path.split('/')[4]);return item?json(res,200,item):json(res,404,{error:'sos_not_found'});}
if(req.method==='POST'&&path==='/v1/safety/route-deviation'){if(!driverUser&&!adminUser)return json(res,401,{error:'authentication_required'});const cfg=getAdminRuntimeConfig(),p=await readBody(req);requireFields(p,['bookingId','expectedDistanceM','actualDistanceM']);const result=evaluateRouteDeviation({...p,thresholdM:cfg.safety.routeDeviationThresholdM});if(result.alert)addRiskEvent({type:'ROUTE_DEVIATION',severity:'HIGH',bookingId:p.bookingId,metadata:result});return json(res,200,result);}
if(req.method==='POST'&&path==='/v1/notifications/send'){if(!requireAdmin('dashboard.read'))return;const p=await readBody(req);requireFields(p,['audience','type','payload']);const cfg=getAdminRuntimeConfig();const item=addNotification(p);const sent=await getNotificationAdapter(cfg.providers.notifications.active).send(item,cfg.providers.notifications.mode);return json(res,201,updateNotification(item.id,{status:sent.accepted?'SENT':'FAILED',attempts:1,provider:sent.provider}));}


if(req.method==='POST'&&path==='/v1/fares/quote-v3'){const p=await readBody(req);requireFields(p,['rideType','distanceKm','paymentPreference']);const cfg=getAdminRuntimeConfig();const availability=serviceAvailability({rideType:p.rideType,isOutsideArea:Boolean(p.isOutsideArea),isNight:Boolean(p.isNight),motorcycleAvailable:p.motorcycleAvailable!==false});if(!availability.available)return json(res,422,{error:availability.reason});const quote=calculateFareQuote(p,cfg.businessRules);const split=calculateCommissionSplit({fareAmount:quote.total,rideType:p.rideType,hasPromoter:Boolean(p.promoterId),hasAreaPromoter:Boolean(p.areaPromoterId)},cfg.businessRules);return json(res,200,{quote,split,availability,paymentPreference:p.paymentPreference,saferide:{enabled:Boolean(p.saferideEnabled),recommended:Boolean(p.isNight||p.highRiskZone)}});}
if(req.method==='POST'&&path==='/v1/service/availability'){const p=await readBody(req);requireFields(p,['rideType']);return json(res,200,serviceAvailability(p));}
if(req.method==='PATCH'&&/^\/v1\/drivers\/[^/]+\/service-preferences$/.test(path)){const id=path.split('/')[3],profile=getDriverProfile(id);if(!profile)return json(res,404,{error:'driver_not_found'});const p=await readBody(req);const updated=updateDriverProfile(id,{servicePreferences:{...(profile.servicePreferences||{}),...p}});if(updated?.status==='COMPLETED'&&updated.passengerId){completeReferralFirstRide({referredPassengerId:updated.passengerId,bookingId:updated.id});}
return json(res,200,updated);}
if(req.method==='POST'&&path==='/v1/late-arrival/evaluate'){const p=await readBody(req);const cfg=getAdminRuntimeConfig();requireFields(p,['committedArrivalAt','actualArrivalAt']);return json(res,200,evaluateLateArrival({...cfg.businessRules.lateArrival,...p}));}
if(req.method==='POST'&&path==='/v1/promoters'){if(!requireAdmin('dashboard.read'))return;const p=await readBody(req);requireFields(p,['name','role']);return json(res,201,upsertPromoter(p));}
if(req.method==='POST'&&path==='/v1/promoters/link-driver'){if(!requireAdmin('dashboard.read'))return;const p=await readBody(req);requireFields(p,['promoterId','driverId']);if(!getPromoter(p.promoterId))return json(res,404,{error:'promoter_not_found'});return json(res,201,linkDriver(p));}
if(req.method==='GET'&&/^\/v1\/promoters\/[^/]+\/dashboard$/.test(path)){if(!requireAdmin('dashboard.read'))return;const actorId=path.split('/')[3];const out=promoterDashboard(actorId,{bookings:listAllBookings(),runtimeDrivers:listAllRuntimeDrivers(),from:url.searchParams.get('from'),to:url.searchParams.get('to')});return out?json(res,200,out):json(res,404,{error:'promoter_not_found'});}
if(req.method==='GET'&&/^\/v1\/promoters\/[^/]+\/drivers$/.test(path)){if(!requireAdmin('dashboard.read'))return;const actorId=path.split('/')[3];const ids=scopedDriverIds(actorId);return json(res,200,{items:ids.map(id=>({profile:getDriverProfile(id),runtime:getDriver(id)})).filter(x=>x.profile)});}
if(req.method==='POST'&&/^\/v1\/promoters\/[^/]+\/coaching$/.test(path)){if(!requireAdmin('dashboard.read'))return;const actorId=path.split('/')[3],p=await readBody(req);requireFields(p,['driverId','type','message']);if(!scopedDriverIds(actorId).includes(p.driverId))return json(res,403,{error:'driver_outside_scope'});return json(res,201,addCoachingLog({promoterId:actorId,...p}));}
if(req.method==='GET'&&/^\/v1\/promoters\/[^/]+\/coaching$/.test(path)){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listCoachingLogs(path.split('/')[3])});}
if(req.method==='GET'&&/^\/v1\/promoters\/[^/]+\/earnings$/.test(path)){if(!requireAdmin('dashboard.read'))return;return json(res,200,earningsSummary(path.split('/')[3],url.searchParams.get('month')));}
if(req.method==='POST'&&/^\/v1\/promoters\/[^/]+\/withdrawals$/.test(path)){if(!requireAdmin('dashboard.read'))return;const actorId=path.split('/')[3],p=await readBody(req);requireFields(p,['amount']);const out=requestPromoterWithdrawal(actorId,Number(p.amount));return out.error?json(res,422,out):json(res,201,out);}

if(req.method==='GET'&&path==='/v1/mobile/config')return json(res,200,getPublicRuntimeConfig(url.searchParams.get('app')||'passenger'));
if(req.method==='GET'&&path==='/v1/admin/config'){if(!requireAdmin('config.read'))return;return json(res,200,getAdminRuntimeConfig());}
if(req.method==='PATCH'&&path==='/v1/admin/config'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;const patch=await readBody(req);const out=updateRuntimeConfig(patch);writeAudit(adminUser.id,'CONFIG_UPDATED',patch);return json(res,200,out);}
if(req.method==='POST'&&path==='/v1/devices/register'){const p=await readBody(req);requireFields(p,['actorType','actorId','deviceId','platform','pushToken']);if(p.actorType==='passenger'&&!requirePassenger(p.actorId))return;if(p.actorType==='driver'&&!requireDriver(p.actorId))return;if(!['passenger','driver'].includes(p.actorType))return json(res,403,{error:'device_actor_forbidden'});return json(res,201,registerDevice(p));}
if(req.method==='POST'&&path==='/v1/devices/unregister'){const p=await readBody(req);requireFields(p,['actorType','actorId','deviceId']);if(p.actorType==='passenger'&&!requirePassenger(p.actorId))return;if(p.actorType==='driver'&&!requireDriver(p.actorId))return;const x=deactivateDevice(p.actorType,p.actorId,p.deviceId);return x?json(res,200,x):json(res,404,{error:'device_not_found'});}
if(req.method==='GET'&&/^\/v1\/devices\/[^/]+\/[^/]+$/.test(path)){const [, , ,actorType,actorId]=path.split('/');if(actorType==='passenger'&&!requirePassenger(actorId))return;if(actorType==='driver'&&!requireDriver(actorId))return;return json(res,200,{items:listDevices(actorType,actorId)});}
if(req.method==='POST'&&path==='/v1/auth/otp/request'){const p=await readBody(req);requireFields(p,['mobile']);const cfg=getAdminRuntimeConfig();const otp=createOtp(p.mobile);const sent=await getOtpAdapter(cfg.providers.otp.active).send(p.mobile,otp.code,cfg.providers.otp.mode);return json(res,201,{sessionId:otp.sessionId,expiresInSeconds:300,delivery:sent});}
if(req.method==='POST'&&path==='/v1/auth/otp/verify'){const p=await readBody(req);requireFields(p,['sessionId','code']);const profile=verifyOtp(p.sessionId,p.code);if(!profile)return json(res,401,{error:'invalid_or_expired_otp'});const session=createPassengerSession(profile.id);return json(res,200,{accessToken:session.token,expiresInSeconds:session.expiresInSeconds,passenger:profile});}if(req.method==='POST'&&path==='/v1/auth/logout'){return json(res,200,{ok:revokePassengerSession(req.headers.authorization)});}
if(req.method==='POST'&&path==='/v1/driver/auth/exchange'){if(!requirePassenger())return;const p=await readBody(req);requireFields(p,['driverId']);const d=getDriverProfile(p.driverId);if(!d)return json(res,404,{error:'driver_not_found'});if(String(d.mobile||'').replace(/\D/g,'')!==String(passengerUser.mobile||'').replace(/\D/g,''))return json(res,403,{error:'driver_mobile_mismatch'});const session=createDriverSession(d.id);return json(res,200,{accessToken:session.token,expiresInSeconds:session.expiresInSeconds,driver:d});}
if(req.method==='POST'&&path==='/v1/driver/auth/logout'){return json(res,200,{ok:revokeDriverSession(req.headers.authorization)});}
if(req.method==='GET'&&/^\/v1\/passengers\/[^/]+$/.test(path)){const pid=path.split('/')[3];if(!requirePassenger(pid))return;const profile=getPassenger(pid);return profile?json(res,200,profile):json(res,404,{error:'passenger_not_found'});}if(req.method==='PATCH'&&/^\/v1\/passengers\/[^/]+$/.test(path)){
  const pid=path.split('/')[3];
  if(!requirePassenger(pid))return;
  const p=await readBody(req),safe={};
  for(const key of ['fullName','preferredLanguage','address','emergencyContact','photoUrl']){
    if(p[key]!==undefined)safe[key]=p[key];
  }
  return json(res,200,upsertPassenger(pid,safe));
}

if(req.method==='PATCH'&&/^\/v1\/passengers\/[^/]+$/.test(path)){const id=path.split('/')[3];if(!requirePassenger(id))return;return json(res,200,upsertPassenger(id,await readBody(req)));}
if(req.method==='GET'&&/^\/v1\/passengers\/[^/]+\/places$/.test(path)){const id=path.split('/')[3];if(!requirePassenger(id))return;return json(res,200,{items:listPlaces(id)});}
if(req.method==='POST'&&/^\/v1\/passengers\/[^/]+\/places$/.test(path)){const id=path.split('/')[3];if(!requirePassenger(id))return;const p=await readBody(req);requireFields(p,['label','address','location']);return json(res,201,addPlace(id,p));}
if(req.method==='GET'&&path==='/v1/passenger/wallet'){
  if(!requirePassenger())return;
  return json(res,200,{wallet:walletSummary(passengerUser.id)});
}
if(req.method==='GET'&&path==='/v1/passenger/wallet/transactions'){
  if(!requirePassenger())return;
  return json(res,200,{
    items:listWalletTransactions(passengerUser.id,{
      limit:Number(url.searchParams.get('limit')||50),
      offset:Number(url.searchParams.get('offset')||0),
    }),
  });
}
if(req.method==='POST'&&path==='/v1/passenger/wallet/add-money'){
  if(!requirePassenger())return;
  const p=await readBody(req);requireFields(p,['amountPaise']);
  const cfg=getAdminRuntimeConfig();
  const amountPaise=Number(p.amountPaise);
  if(!Number.isInteger(amountPaise)||amountPaise<1000||amountPaise>5000000){
    return json(res,422,{error:'invalid_topup_amount'});
  }
  const reference=`wallet_${passengerUser.id}_${Date.now()}`;
  const order=await getPaymentAdapter(
    cfg.providers.payments.active,
  ).createOrder(
    amountPaise,
    reference,
    cfg.providers.payments.mode,
  );
  return json(res,201,{
    topupReference:reference,
    amountPaise,
    provider:cfg.providers.payments.active,
    order,
  });
}
if(req.method==='POST'&&path==='/v1/passenger/wallet/payment/verify'){
  if(!requirePassenger())return;
  const p=await readBody(req);
  requireFields(p,[
    'topupReference',
    'amountPaise',
    'providerOrderId',
    'providerPaymentId',
    'signature',
  ]);
  const cfg=getAdminRuntimeConfig();
  const verified=await getPaymentAdapter(
    cfg.providers.payments.active,
  ).verifyPayment(p,cfg.providers.payments.mode);
  if(!verified.verified)return json(res,401,{error:'wallet_topup_verification_failed'});
  try{
    const result=creditPassengerWallet(passengerUser.id,{
      amountPaise:Number(p.amountPaise),
      type:'WALLET_TOPUP',
      referenceType:'PAYMENT',
      referenceId:verified.providerPaymentId,
      description:'Wallet top-up',
      idempotencyKey:`wallet-topup:${verified.providerPaymentId}`,
    });
    return json(res,200,result);
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='POST'&&path==='/v1/passenger/wallet/pay-ride'){
  if(!requirePassenger())return;
  const p=await readBody(req);requireFields(p,['bookingId','amountPaise']);
  const booking=getBooking(p.bookingId);
  if(!booking||booking.passengerId!==passengerUser.id){
    return json(res,404,{error:'booking_not_found'});
  }
  try{
    const result=debitPassengerWallet(passengerUser.id,{
      amountPaise:Number(p.amountPaise),
      referenceId:booking.id,
      idempotencyKey:`ride-wallet:${booking.id}`,
      description:'Ride payment',
    });
    return json(res,200,result);
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='GET'&&path==='/v1/passenger/referral'){
  if(!requirePassenger())return;
  return json(res,200,{referral:referralProfile(passengerUser.id)});
}
if(req.method==='POST'&&path==='/v1/passenger/referral/apply'){
  if(!requirePassenger())return;
  const p=await readBody(req);requireFields(p,['code']);
  try{
    const referral=applyReferralCode({
      passengerId:passengerUser.id,
      code:p.code,
      mobile:passengerUser.mobile,
    });
    return json(res,201,{referral});
  }catch(error){return json(res,422,{error:error.message});}
}
if(req.method==='GET'&&path==='/v1/passenger/referral/history'){
  if(!requirePassenger())return;
  return json(res,200,{items:listReferralHistory(passengerUser.id)});
}
if(req.method==='GET'&&path==='/v1/passenger/referral/rewards'){
  if(!requirePassenger())return;
  return json(res,200,referralRewards(passengerUser.id));
}
if(req.method==='PATCH'&&path==='/v1/passenger/profile/media'){
  if(!requirePassenger())return;
  return json(res,200,setProfileMedia(
    'PASSENGER',
    passengerUser.id,
    await readBody(req),
  ));
}
if(req.method==='GET'&&path==='/v1/passenger/profile/media'){
  if(!requirePassenger())return;
  return json(res,200,{
    media:getProfileMedia('PASSENGER',passengerUser.id),
  });
}
if(req.method==='POST'&&path==='/v1/support/issues'){
  const actor=passengerUser
    ?{actorType:'PASSENGER',actorId:passengerUser.id}
    :driverUser
      ?{actorType:'DRIVER',actorId:driverUser.id}
      :partnerUser
        ?{actorType:'PARTNER',actorId:partnerUser.id}
        :null;
  if(!actor)return json(res,401,{error:'authentication_required'});
  const p=await readBody(req);
  requireFields(p,['category','description']);
  return json(res,201,createSupportIssue({...actor,...p}));
}
if(req.method==='GET'&&path==='/v1/support/issues'){
  const actor=passengerUser
    ?{actorType:'PASSENGER',actorId:passengerUser.id}
    :driverUser
      ?{actorType:'DRIVER',actorId:driverUser.id}
      :partnerUser
        ?{actorType:'PARTNER',actorId:partnerUser.id}
        :null;
  if(!actor)return json(res,401,{error:'authentication_required'});
  return json(res,200,{items:listSupportIssues(actor)});
}
if(req.method==='GET'&&path==='/v1/share/routes')return json(res,200,{items:listShareRoutes().filter(x=>x.enabled!==false)});
if(req.method==='GET'&&/^\/v1\/share\/routes\/[^/]+$/.test(path)){const item=getShareRoute(path.split('/')[4]);return item?json(res,200,item):json(res,404,{error:'share_route_not_found'});}
if(req.method==='GET'&&/^\/v1\/drivers\/[^/]+\/share-permissions$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id)&&!adminUser)return;return json(res,200,getDriverSharePermissions(id)||{driverId:id,routeIds:[],zoneIds:[],serviceTypes:[]});}
if(req.method==='GET'&&/^\/v1\/drivers\/[^/]+\/share-timeline$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const active=listShareSessions().find(x=>x.driverId===id&&['BOARDING','IN_PROGRESS'].includes(x.status));return active?json(res,200,getShareTimeline(active.id)):json(res,404,{error:'active_share_session_not_found'});}
if(req.method==='POST'&&path==='/v1/share/quote'){if(!requirePassenger())return;const p=await readBody(req);requireFields(p,['routeId','pickup','destination','seats']);const route=getShareRoute(p.routeId);if(!route)return json(res,404,{error:'share_route_not_found'});const pickupStop=p.pickupStopId?route.stops.find(x=>x.id===p.pickupStopId):nearestRouteStop(route,p.pickup,Number(p.maxStopDistanceM||500));const dropStop=p.dropStopId?route.stops.find(x=>x.id===p.dropStopId):nearestRouteStop(route,p.destination,Number(p.maxStopDistanceM||500));if(!pickupStop||!dropStop)return json(res,422,{error:'share_stop_not_found'});const direction=p.direction||'FORWARD';const session=p.sessionId?getShareSession(p.sessionId):{bookings:[],capacity:Number(p.capacity||4),direction};const check=canPoolBooking({route,session,pickupStopId:pickupStop.id,dropStopId:dropStop.id,seats:Number(p.seats),direction,capacity:session.capacity});return json(res,check.valid?200:422,{...check,routeId:route.id,pickupStop,dropStop});}
if(req.method==='GET'&&path==='/v1/admin/share/routes'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listShareRoutes()});}
if(req.method==='POST'&&path==='/v1/admin/share/routes'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;const item=upsertShareRoute(await readBody(req));writeAudit(adminUser.id,'SHARE_ROUTE_UPSERTED',{routeId:item.id});return json(res,201,item);}
if(req.method==='DELETE'&&/^\/v1\/admin\/share\/routes\/[^/]+$/.test(path)){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;const id=path.split('/')[5];return json(res,removeShareRoute(id)?200:404,{ok:true});}
if(req.method==='PUT'&&/^\/v1\/admin\/drivers\/[^/]+\/share-permissions$/.test(path)){if(!requireAdmin('drivers.read')&&!adminCan(adminUser,'*'))return;const id=path.split('/')[4],item=setDriverSharePermissions(id,await readBody(req));writeAudit(adminUser.id,'DRIVER_SHARE_PERMISSION_UPDATED',{driverId:id,routeIds:item.routeIds});return json(res,200,item);}
if(req.method==='GET'&&path==='/v1/zones')return json(res,200,{items:listZones()});
if(req.method==='POST'&&path==='/v1/maps/context'){const p=await readBody(req);requireFields(p,['pickup','destination']);if(!validPoint(p.pickup)||!validPoint(p.destination))throw new Error('Invalid map context coordinates');const context=evaluateZoneContext({pickup:p.pickup,destination:p.destination,zones:listZones()});const distanceKm=Number(p.distanceKm||haversineKm(p.pickup,p.destination));const validation=validateRideAgainstZone({rideType:p.rideType||'FULL_TOTO',distanceKm,zoneContext:context,maximumTotoDistanceKm:getAdminRuntimeConfig().businessRules.maximumTotoDistanceKm});return json(res,200,{context,distanceKm,validation});}
if(req.method==='GET'&&path==='/v1/admin/zones'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listZones()});}
if(req.method==='POST'&&path==='/v1/admin/zones'){if(!requireAdmin('*')&&!adminCan(adminUser,'dashboard.read'))return;const p=await readBody(req);const item=upsertZone(p);writeAudit(adminUser.id,'ZONE_UPSERTED',{code:item.code,type:item.type});return json(res,201,item);}
if(req.method==='DELETE'&&/^\/v1\/admin\/zones\/[^/]+$/.test(path)){if(!requireAdmin('*')&&!adminCan(adminUser,'dashboard.read'))return;const code=decodeURIComponent(path.split('/')[4]);const ok=removeZone(code);if(ok)writeAudit(adminUser.id,'ZONE_DELETED',{code});return json(res,ok?200:404,{ok});}
if(req.method==='POST'&&path==='/v1/maps/geocode'){const cfg=getAdminRuntimeConfig(),p=await readBody(req);requireFields(p,['query']);const primary={code:cfg.providers.maps.active,adapter:getMapAdapter(cfg.providers.maps.active)};const fallback=cfg.providers.maps.fallback?{code:cfg.providers.maps.fallback,adapter:getMapAdapter(cfg.providers.maps.fallback)}:null;const options={lat:Number(p.lat),lng:Number(p.lng),limit:Number(p.limit||10),language:p.language||'bn,en'};return json(res,200,await withFallback({primary,fallback,service:'maps',operation:(a)=>a.geocode(p.query,cfg.providers.maps.mode,options)}));}

if(req.method==='GET'&&path==='/v1/maps/geocode'){const cfg=getAdminRuntimeConfig(),query=url.searchParams.get('q')||'';if(query.trim().length<2)throw new Error('Search query too short');const primary={code:cfg.providers.maps.active,adapter:getMapAdapter(cfg.providers.maps.active)};const fallback=cfg.providers.maps.fallback?{code:cfg.providers.maps.fallback,adapter:getMapAdapter(cfg.providers.maps.fallback)}:null;const options={lat:Number(url.searchParams.get('lat')),lng:Number(url.searchParams.get('lng')),limit:Number(url.searchParams.get('limit')||10),language:url.searchParams.get('language')||'bn,en'};return json(res,200,await withFallback({primary,fallback,service:'maps',operation:(a)=>a.geocode(query,cfg.providers.maps.mode,options)}));}if(req.method==='GET'&&path==='/v1/maps/reverse'){const cfg=getAdminRuntimeConfig(),lat=Number(url.searchParams.get('lat')),lng=Number(url.searchParams.get('lng'));if(!Number.isFinite(lat)||!Number.isFinite(lng))throw new Error('Invalid reverse geocode coordinates');const primary={code:cfg.providers.maps.active,adapter:getMapAdapter(cfg.providers.maps.active)};const fallback=cfg.providers.maps.fallback?{code:cfg.providers.maps.fallback,adapter:getMapAdapter(cfg.providers.maps.fallback)}:null;const options={language:url.searchParams.get('language')||'bn,en'};return json(res,200,await withFallback({primary,fallback,service:'maps',operation:(a)=>a.reverse({lat,lng},cfg.providers.maps.mode,options)}));}
if(req.method==='POST'&&path==='/v1/maps/route'){const cfg=getAdminRuntimeConfig(),p=await readBody(req);requireFields(p,['origin','destination']);if(!validPoint(p.origin)||!validPoint(p.destination))throw new Error('Invalid route coordinates');const primary={code:cfg.providers.maps.active,adapter:getMapAdapter(cfg.providers.maps.active)};const fallback=cfg.providers.maps.fallback?{code:cfg.providers.maps.fallback,adapter:getMapAdapter(cfg.providers.maps.fallback)}:null;return json(res,200,await withFallback({primary,fallback,service:'maps',operation:(a)=>a.route(p.origin,p.destination,cfg.providers.maps.mode)}));}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/tracking$/.test(path)){const bookingId=path.split('/')[3],b=getBooking(bookingId);if(!b)return json(res,404,{error:'booking_not_found'});if(!canAccessBooking(b))return json(res,403,{error:'booking_scope_denied'});const p=await readBody(req);requireFields(p,['actorType','actorId','samples']);if(!['driver','passenger'].includes(p.actorType))throw new Error('Invalid tracking actor');if(p.actorType==='passenger'&&(!passengerUser||p.actorId!==passengerUser.id||b.passengerId!==p.actorId))return json(res,403,{error:'tracking_actor_mismatch'});if(p.actorType==='driver'&&(!driverUser||p.actorId!==driverUser.id||b.driverId!==p.actorId))return json(res,403,{error:'tracking_actor_mismatch'});if(!Array.isArray(p.samples)||!p.samples.length)throw new Error('Tracking samples required');const cfg=getAdminRuntimeConfig();if(p.samples.length>cfg.tracking.maxBatchSize)throw new Error('Tracking batch too large');let previous=listTrackingSamples(bookingId,1).at(-1)||null;const accepted=[];for(const raw of p.samples){const sample=validateLocationSample(raw,previous,cfg.tracking);const item=appendTrackingSample(bookingId,p.actorType,p.actorId,sample);accepted.push(item);previous=item;}return json(res,201,{accepted:accepted.length,last:accepted.at(-1),snapshot:trackingSnapshot(bookingId)});}
if(req.method==='GET'&&/^\/v1\/bookings\/[^/]+\/tracking$/.test(path)){const bookingId=path.split('/')[3],b=getBooking(bookingId);if(!b)return json(res,404,{error:'booking_not_found'});if(!canAccessBooking(b))return json(res,403,{error:'booking_scope_denied'});return json(res,200,{snapshot:trackingSnapshot(bookingId),items:listTrackingSamples(bookingId,Number(url.searchParams.get('limit')||200))});}
if(req.method==='GET'&&/^\/v1\/drivers\/[^/]+\/live-location$/.test(path)){const id=path.split('/')[3];if(!(driverUser&&driverUser.id===id)&&!(adminUser&&adminCan(adminUser,'rides.read')))return json(res,403,{error:'driver_location_scope_denied'});const item=getLatestDriverLocation(id);if(!item)return json(res,404,{error:'driver_location_not_found'});const cfg=getAdminRuntimeConfig();return json(res,200,{...item,stale:Date.now()-item.receivedAt>cfg.tracking.staleAfterSeconds*1000});}
if(req.method==='POST'&&path==='/v1/tracking/offline-queue'){if(!driverUser)return json(res,401,{error:'driver_auth_required'});const p=await readBody(req);requireFields(p,['deviceId','samples']);if(!Array.isArray(p.samples))throw new Error('Samples must be an array');return json(res,201,queueOfflineSamples(p.deviceId,p.samples));}
if(req.method==='POST'&&path==='/v1/tracking/offline-flush'){if(!driverUser)return json(res,401,{error:'driver_auth_required'});const p=await readBody(req);requireFields(p,['deviceId']);return json(res,200,{deviceId:p.deviceId,samples:flushOfflineSamples(p.deviceId)});}

if(req.method==='POST'&&path==='/v1/fares/estimate'){const p=await readBody(req);requireFields(p,['pickup','destination']);if(!validPoint(p.pickup)||!validPoint(p.destination))throw new Error('Invalid pickup or destination');return json(res,200,estimateFare({pickup:p.pickup,destination:p.destination,fare:getAdminRuntimeConfig().fare}));}
if(req.method==='POST'&&path==='/v1/payments/orders'){if(!requirePassenger())return;const cfg=getAdminRuntimeConfig(),p=await readBody(req);requireFields(p,['bookingId','passengerId','method','idempotencyKey']);const booking=getBooking(p.bookingId);if(!booking)return json(res,404,{error:'booking_not_found'});if(booking.passengerId!==p.passengerId||passengerUser.id!==p.passengerId)return json(res,403,{error:'passenger_mismatch'});const existing=getPaymentByBooking(p.bookingId);if(existing)return json(res,200,existing);const amountPaise=Math.round(Number(p.amountPaise??booking.fareEstimate?.amount??0)*100);if(!Number.isInteger(amountPaise)||amountPaise<=0)throw new Error('Invalid payment amount');const requested=p.method==='cash'?'cash':cfg.providers.payments.active;const primary={code:requested,adapter:getPaymentAdapter(requested)};const fallback=requested==='cash'?null:(cfg.providers.payments.fallback?{code:cfg.providers.payments.fallback,adapter:getPaymentAdapter(cfg.providers.payments.fallback)}:null);const order=await withFallback({primary,fallback,service:'payments',operation:(a)=>a.createOrder(amountPaise,p.bookingId,cfg.providers.payments.mode)});const payment=createPayment({bookingId:p.bookingId,passengerId:p.passengerId,driverId:booking.driverId,method:p.method,provider:order.provider,providerOrderId:order.result.providerOrderId,amountPaise,currency:cfg.payments.currency,status:order.result.status,idempotencyKey:p.idempotencyKey});return json(res,201,payment);}
if(req.method==='POST'&&/^\/v1\/payments\/[^/]+\/verify$/.test(path)){if(!passengerUser&&!adminUser)return json(res,401,{error:'authentication_required'});const paymentId=path.split('/')[3],payment=getPayment(paymentId);if(!payment)return json(res,404,{error:'payment_not_found'});if(passengerUser&&payment.passengerId!==passengerUser.id&&!adminUser)return json(res,403,{error:'payment_scope_denied'});const payload=await readBody(req);const result=await getPaymentAdapter(payment.provider).verifyPayment({...payload,providerOrderId:payment.providerOrderId},getAdminRuntimeConfig().providers.payments.mode);const updated=updatePayment(paymentId,{status:result.status,providerPaymentId:result.providerPaymentId||null},result.verified?'PAYMENT_VERIFIED':'PAYMENT_FAILED');return json(res,result.verified?200:402,{payment:updated,verification:result});}
if(req.method==='GET'&&/^\/v1\/payments\/[^/]+$/.test(path)){if(!passengerUser&&!adminUser)return json(res,401,{error:'authentication_required'});const payment=getPayment(path.split('/')[3]);if(payment&&passengerUser&&payment.passengerId!==passengerUser.id&&!adminUser)return json(res,403,{error:'payment_scope_denied'});return payment?json(res,200,{...payment,refunds:listRefunds(payment.id),ledger:listPaymentLedger(payment.id)}):json(res,404,{error:'payment_not_found'});}
if(req.method==='POST'&&/^\/v1\/payments\/[^/]+\/refunds$/.test(path)){if(!requireAdmin('payments.read'))return;const paymentId=path.split('/')[3],payment=getPayment(paymentId);if(!payment)return json(res,404,{error:'payment_not_found'});const p=await readBody(req);requireFields(p,['amountPaise']);const cfg=getAdminRuntimeConfig();if(!cfg.payments.allowPartialRefund&&p.amountPaise!==payment.amountPaise)throw new Error('Partial refunds are disabled');await getPaymentAdapter(payment.provider).refund(payment.providerPaymentId,p.amountPaise,getAdminRuntimeConfig().providers.payments.mode);return json(res,201,addRefund(paymentId,p.amountPaise,p.reason));}
if(req.method==='GET'&&/^\/v1\/bookings\/[^/]+\/payment$/.test(path)){if(!passengerUser&&!adminUser)return json(res,401,{error:'authentication_required'});const payment=getPaymentByBooking(path.split('/')[3]);if(payment&&passengerUser&&payment.passengerId!==passengerUser.id&&!adminUser)return json(res,403,{error:'payment_scope_denied'});return payment?json(res,200,payment):json(res,404,{error:'payment_not_found'});}

if(req.method==='POST'&&path==='/v1/drivers/register'){if(!requirePassenger())return;const p=await readBody(req);requireFields(p,['mobile']);if(String(p.mobile).replace(/\D/g,'')!==String(passengerUser.mobile).replace(/\D/g,''))return json(res,403,{error:'driver_mobile_mismatch'});const existing=findDriverByMobile(p.mobile);const d=existing||registerDriver(p);const session=createDriverSession(d.id);return json(res,existing?200:201,{driver:d,accessToken:session.token,expiresInSeconds:session.expiresInSeconds});}
if(req.method==='GET'&&/^\/v1\/driver-profiles\/[^/]+$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const d=getDriverProfile(id);return d?json(res,200,d):json(res,404,{error:'driver_not_found'});}
if(req.method==='PATCH'&&/^\/v1\/driver-profiles\/[^/]+$/.test(path)){
  const id=path.split('/')[3];
  if(!requireDriver(id))return;
  const p=await readBody(req),safe={};
  for(const key of ['fullName','address','upiId','emergencyContact','preferredLanguage','photoUrl','onboardingStep','operatingMode','seatCapacity']){
    if(p[key]!==undefined)safe[key]=p[key];
  }
  if(p.vehicle&&typeof p.vehicle==='object')safe.vehicle=p.vehicle;
  if(p.bank&&typeof p.bank==='object')safe.bank=p.bank;
  const d=updateDriverProfile(id,safe);
  return d?json(res,200,d):json(res,404,{error:'driver_not_found'});
}
if(req.method==='POST'&&/^\/v1\/driver-profiles\/[^/]+\/documents$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const p=await readBody(req);requireFields(p,['type','fileUrl']);const d=addDriverDocument(id,p);return d?json(res,201,d):json(res,404,{error:'driver_not_found'});}
if(req.method==='GET'&&/^\/v1\/driver-profiles\/[^/]+\/documents$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;return json(res,200,{items:listDriverDocuments(id)});}
if(req.method==='GET'&&/^\/v1\/driver-profiles\/[^/]+\/readiness$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const d=getDriverProfile(id);return d?json(res,200,onboardingReadiness(d,listDriverDocuments(id))):json(res,404,{error:'driver_not_found'});}
if(req.method==='POST'&&/^\/v1\/admin\/drivers\/[^/]+\/review$/.test(path)){if(!requireAdmin('drivers.read'))return;const p=await readBody(req);requireFields(p,['status']);const d=reviewDriver(path.split('/')[4],p);return d?json(res,200,d):json(res,404,{error:'driver_not_found'});}
if(req.method==='PUT'&&/^\/v1\/driver-profiles\/[^/]+\/online$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const p=await readBody(req);requireFields(p,['online']);if(p.online&&!validPoint(p.location))throw new Error('Location required when driver goes online');const d=setDriverOnline(id,p);if(!d)return json(res,404,{error:'driver_not_found'});upsertDriver(d.id,{online:d.online,location:d.location,rating:d.rating,approved:d.approved});return json(res,200,d);}if(req.method==='GET'&&path==='/v1/driver/requests'){
  if(!driverUser)return json(res,401,{error:'driver_auth_required'});
  if(!driverUser.approved||driverUser.suspended||!driverUser.online||!validPoint(driverUser.location)){
    return json(res,200,{items:[]});
  }
  const cfg=getAdminRuntimeConfig();
  const radius=Number(cfg.booking.searchRadiusKm||8);
  const items=listAllBookings()
    .filter((booking)=>booking.status==='SEARCHING'&&!booking.driverId&&validPoint(booking.pickup))
    .map((booking)=>({
      ...booking,
      distanceToPickupKm:Number(
        haversineKm(driverUser.location,booking.pickup).toFixed(2),
      ),
    }))
    .filter((booking)=>booking.distanceToPickupKm<=radius)
    .sort((a,b)=>a.distanceToPickupKm-b.distanceToPickupKm)
    .slice(0,10);
  return json(res,200,{items});
}

if(req.method==='GET'&&/^\/v1\/driver-profiles\/[^/]+\/wallet$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const w=getDriverWallet(id);return w?json(res,200,w):json(res,404,{error:'wallet_not_found'});}
if(req.method==='POST'&&/^\/v1\/driver-profiles\/[^/]+\/settlements$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const p=await readBody(req);requireFields(p,['amountPaise']);const cfg=getAdminRuntimeConfig();if(p.amountPaise<cfg.payments.settlementMinimumPaise)throw new Error('Settlement amount below minimum');return json(res,201,requestSettlement(id,p.amountPaise));}
if(req.method==='GET'&&/^\/v1\/driver-profiles\/[^/]+\/settlements$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;return json(res,200,{items:listSettlements(id)});}
if(req.method==='PATCH'&&/^\/v1\/admin\/settlements\/[^/]+$/.test(path)){if(!requireAdmin('settlements.read'))return;const p=await readBody(req);requireFields(p,['status']);const item=updateSettlement(path.split('/')[4],p.status,p.reference||null);return item?json(res,200,item):json(res,404,{error:'settlement_not_found'});}

if(req.method==='PUT'&&/^\/v1\/drivers\/[^/]+\/availability$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const p=await readBody(req);requireFields(p,['online']);if(p.online&&!validPoint(p.location))throw new Error('Location required when driver goes online');return json(res,200,upsertDriver(id,{online:Boolean(p.online),location:p.location||null,rating:p.rating||5,approved:p.approved!==false}));}
if(req.method==='GET'&&/^\/v1\/drivers\/[^/]+$/.test(path)){const id=path.split('/')[3];if(!requireDriver(id))return;const d=getDriver(id);return d?json(res,200,d):json(res,404,{error:'driver_not_found'});}
if(req.method==='POST'&&path==='/v1/bookings'){if(!requirePassenger())return;const cfg=getAdminRuntimeConfig();const p=await readBody(req);requireFields(p,['passengerId','pickup','destination']);if(p.passengerId!==passengerUser.id)return json(res,403,{error:'passenger_scope_denied'});const rl=hitRateLimit(`booking:${p.passengerId}`,cfg.safety.maxBookingsPerPassengerPerHour,3600_000);if(!rl.allowed)return json(res,429,{error:'booking_rate_limited',retryAfterMs:rl.retryAfterMs});if(!cfg.operations.serviceEnabled||!cfg.operations.newBookingsEnabled)return json(res,503,{error:'booking_service_disabled'});if(cfg.maintenanceMode)return json(res,503,{error:'maintenance_mode'});if(!validPoint(p.pickup)||!validPoint(p.destination))throw new Error('Invalid pickup or destination');const risk=evaluateBookingRisk({passengerId:p.passengerId,pickup:p.pickup,destination:p.destination,recentBookingCount:rl.count-1});if(risk.level==='HIGH')addRiskEvent({type:'BOOKING_RISK',severity:'HIGH',actorId:p.passengerId,metadata:risk});const fareEstimate=p.rideType&&p.distanceKm?calculateFareQuote(p,cfg.businessRules):estimateFare({pickup:p.pickup,destination:p.destination,fare:cfg.fare});if(p.rideType){const availability=serviceAvailability({rideType:p.rideType,isOutsideArea:Boolean(p.isOutsideArea),isNight:Boolean(p.isNight),motorcycleAvailable:p.motorcycleAvailable!==false});if(!availability.available)return json(res,422,{error:availability.reason});}let shareMeta={};if(p.rideType==='SHARE_TOTO'){requireFields(p,['shareRouteId','pickupStopId','dropStopId','seats']);const route=getShareRoute(p.shareRouteId);if(!route||route.enabled===false)return json(res,422,{error:'share_route_unavailable'});const direction=p.routeDirection||'FORWARD';const probe=canPoolBooking({route,session:{bookings:[],capacity:Number(p.capacity||4),direction},pickupStopId:p.pickupStopId,dropStopId:p.dropStopId,seats:Number(p.seats),direction,capacity:Number(p.capacity||4)});if(!probe.valid)return json(res,422,{error:probe.reason,details:probe});shareMeta={shareRouteId:route.id,pickupStopId:p.pickupStopId,dropStopId:p.dropStopId,seats:Number(p.seats),routeDirection:direction};}let appliedOffer=null;const fareAmount=Number(fareEstimate.amount??fareEstimate.total??0);if(p.offerCode){const preview=validateOfferCode({code:p.offerCode,actorType:'PASSENGER',actorId:p.passengerId,amount:fareAmount,areaId:p.pickupZoneId||p.areaId||null,cityId:p.cityId||null,rideType:p.rideType||null,isNewUser:Boolean(p.isNewUser)});if(!preview.valid)return json(res,422,{error:preview.reason,offer:preview.campaign||null});appliedOffer={campaignId:preview.campaign.id,offerCode:p.offerCode,rewardAmount:preview.rewardAmount};fareEstimate.originalAmount=fareAmount;fareEstimate.discount=preview.rewardAmount;if('amount' in fareEstimate)fareEstimate.amount=Math.max(0,fareAmount-preview.rewardAmount);if('total' in fareEstimate)fareEstimate.total=Math.max(0,fareAmount-preview.rewardAmount);}const booking=createBooking({...p,...shareMeta,paymentPreference:p.paymentPreference||'BOTH',saferideEnabled:Boolean(p.saferideEnabled),fareEstimate,appliedOffer,risk});if(appliedOffer)redeemOfferCode({code:p.offerCode,eventId:`booking:${booking.id}`,actorId:p.passengerId,amount:fareAmount,areaId:p.pickupZoneId||p.areaId||null,cityId:p.cityId||null,rideType:p.rideType||null,isNewUser:Boolean(p.isNewUser),bookingId:booking.id});return json(res,201,updateBooking(booking.id,{status:'SEARCHING'},'DRIVER_SEARCH_STARTED'));}
if(req.method==='GET'&&/^\/v1\/passengers\/[^/]+\/bookings$/.test(path)){const id=path.split('/')[3];if(!requirePassenger(id))return;return json(res,200,{items:listBookingsForPassenger(id)});}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/match$/.test(path)){if(!requireAdmin('rides.read'))return;const id=path.split('/')[3],b=getBooking(id);if(!b)return json(res,404,{error:'booking_not_found'});if(b.status!=='SEARCHING')throw new Error('Booking is not searching');const cfg=getAdminRuntimeConfig(),ranked=rankDrivers(getAvailableDrivers(),b.pickup,cfg.booking.searchRadiusKm);if(!ranked.length){assertTransition(b.status,'NO_DRIVER_FOUND');return json(res,200,{booking:updateBooking(id,{status:'NO_DRIVER_FOUND'},'NO_DRIVER_FOUND'),candidates:[]});}let candidates=ranked;if(b.rideType==='SHARE_TOTO'){candidates=ranked.filter(d=>driverCanOperateShareRoute(d.id,b.shareRouteId));if(!candidates.length){assertTransition(b.status,'NO_DRIVER_FOUND');return json(res,200,{booking:updateBooking(id,{status:'NO_DRIVER_FOUND'},'NO_PERMITTED_SHARE_DRIVER'),candidates:[]});}let chosen=null,session=null;for(const d of candidates){session=findOpenShareSession({driverId:d.id,routeId:b.shareRouteId,direction:b.routeDirection||'FORWARD'});if(!session)session=createShareSession({driverId:d.id,routeId:b.shareRouteId,direction:b.routeDirection||'FORWARD',capacity:getDriverSharePermissions(d.id)?.capacity||d.seatCapacity||4});const route=getShareRoute(b.shareRouteId);const check=canPoolBooking({route,session,pickupStopId:b.pickupStopId,dropStopId:b.dropStopId,seats:b.seats,direction:session.direction,capacity:session.capacity});if(check.valid){chosen=d;break;}}if(!chosen)return json(res,200,{booking:updateBooking(id,{status:'NO_DRIVER_FOUND'},'NO_SHARE_SEAT_AVAILABLE'),candidates:[]});addBookingToShareSession(session.id,{route:getShareRoute(b.shareRouteId),bookingId:b.id,passengerId:b.passengerId,pickupStopId:b.pickupStopId,dropStopId:b.dropStopId,seats:b.seats});assertTransition(b.status,'DRIVER_ASSIGNED');return json(res,200,{booking:updateBooking(id,{status:'DRIVER_ASSIGNED',driverId:chosen.id,shareSessionId:session.id},'SHARE_DRIVER_ASSIGNED'),shareSession:getShareTimeline(session.id),candidates:candidates.slice(0,cfg.booking.maxDriverAttempts)});}const selected=candidates[0];assertTransition(b.status,'DRIVER_ASSIGNED');return json(res,200,{booking:updateBooking(id,{status:'DRIVER_ASSIGNED',driverId:selected.id},'DRIVER_ASSIGNED'),candidates:candidates.slice(0,cfg.booking.maxDriverAttempts)});}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/accept$/.test(path)){
  if(!driverUser)return json(res,401,{error:'driver_auth_required'});
  if(!driverUser.approved||driverUser.suspended){
    return json(res,403,{error:'driver_not_eligible'});
  }
  const id=path.split('/')[3];
  const out=acceptBooking(id,driverUser.id);
  if(out.error){
    return json(res,out.error==='booking_not_found'?404:409,out);
  }
  return json(res,200,out);
}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/transition$/.test(path)){const id=path.split('/')[3],b=getBooking(id);if(!b)return json(res,404,{error:'booking_not_found'});if(!canAccessBooking(b))return json(res,403,{error:'booking_scope_denied'});const p=await readBody(req);requireFields(p,['status']);assertTransition(b.status,p.status);const updated=updateBooking(id,{status:p.status},`STATUS_${p.status}`);if(p.status==='COMPLETED'&&b.driverId&&getDriverWallet(b.driverId)){const cfg=getAdminRuntimeConfig();const fareAmount=Number(b.fareEstimate.amount??b.fareEstimate.total??0);const earning=calculateDriverEarning({fareAmount,commissionPercent:cfg.fare.driverCommissionPercent||15});creditDriver(b.driverId,{bookingId:id,...earning});recordCampaignEvent({eventType:'RIDE_COMPLETED',metric:'RIDE_COMPLETED',actorType:'DRIVER',actorId:b.driverId,eventId:`driver:${id}`,bookingId:id,amount:fareAmount,commissionAmount:Number(earning.commissionAmount||earning.commission||0),areaId:b.pickupZoneId||b.areaId||null,cityId:b.cityId||null,rideType:b.rideType||null});recordCampaignEvent({eventType:'RIDE_COMPLETED',metric:'RIDE_COMPLETED',actorType:'PASSENGER',actorId:b.passengerId,eventId:`passenger:${id}`,bookingId:id,amount:fareAmount,areaId:b.pickupZoneId||b.areaId||null,cityId:b.cityId||null,rideType:b.rideType||null});const link=getDriverPartnerLink(b.driverId);if(link?.promoterId)recordCampaignEvent({eventType:'RIDE_COMPLETED',metric:'RIDE_COMPLETED',actorType:'PROMOTER',actorId:link.promoterId,eventId:`promoter:${id}`,bookingId:id,amount:fareAmount,areaId:b.pickupZoneId||b.areaId||null,cityId:b.cityId||null,rideType:b.rideType||null});if(link?.areaPromoterId)recordCampaignEvent({eventType:'RIDE_COMPLETED',metric:'RIDE_COMPLETED',actorType:'AREA_PROMOTER',actorId:link.areaPromoterId,eventId:`area:${id}`,bookingId:id,amount:fareAmount,areaId:b.pickupZoneId||b.areaId||null,cityId:b.cityId||null,rideType:b.rideType||null});}return json(res,200,updated);}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/cancel$/.test(path)){const id=path.split('/')[3],b=getBooking(id);if(!b)return json(res,404,{error:'booking_not_found'});if(!passengerUser||b.passengerId!==passengerUser.id)return json(res,403,{error:'booking_scope_denied'});const p=await readBody(req);assertTransition(b.status,'CANCELLED_BY_PASSENGER');return json(res,200,updateBooking(id,{status:'CANCELLED_BY_PASSENGER',cancellationReason:p.reason||'PASSENGER_REQUEST'},'PASSENGER_CANCELLED'));}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/rating$/.test(path)){const id=path.split('/')[3],b=getBooking(id);if(!b)return json(res,404,{error:'booking_not_found'});if(!passengerUser||b.passengerId!==passengerUser.id)return json(res,403,{error:'booking_scope_denied'});const p=await readBody(req);requireFields(p,['passengerId','score']);if(p.score<1||p.score>5)throw new Error('Rating score must be 1 to 5');return json(res,201,addRating({bookingId:id,...p}));}
if(req.method==='POST'&&/^\/v1\/bookings\/[^/]+\/complaints$/.test(path)){const id=path.split('/')[3],b=getBooking(id);if(!b)return json(res,404,{error:'booking_not_found'});if(!passengerUser||b.passengerId!==passengerUser.id)return json(res,403,{error:'booking_scope_denied'});const p=await readBody(req);requireFields(p,['passengerId','category','description']);return json(res,201,addComplaint({bookingId:id,...p}));}
if(req.method==='GET'&&/^\/v1\/bookings\/[^/]+\/events$/.test(path)){const id=path.split('/')[3],b=getBooking(id);if(!b)return json(res,404,{error:'booking_not_found'});if(!canAccessBooking(b))return json(res,403,{error:'booking_scope_denied'});return json(res,200,{events:listBookingEvents(id)});}
if(req.method==='GET'&&/^\/v1\/bookings\/[^/]+$/.test(path)){const b=getBooking(path.split('/')[3]);if(b&&!canAccessBooking(b))return json(res,403,{error:'booking_scope_denied'});return b?json(res,200,b):json(res,404,{error:'booking_not_found'});}


if(req.method==='POST'&&path==='/v1/offers/validate-code'){if(!requirePassenger())return;const p=await readBody(req);requireFields(p,['code']);return json(res,200,validateOfferCode({code:p.code,actorType:'PASSENGER',actorId:passengerUser.id,amount:Number(p.amount||0),areaId:p.areaId||null,cityId:p.cityId||null,rideType:p.rideType||null,isNewUser:Boolean(p.isNewUser)}));}
if(req.method==='GET'&&path==='/v1/passenger/offers'){if(!requirePassenger())return;return json(res,200,{items:listEligibleCampaigns({actorType:'PASSENGER',actorId:passengerUser.id,amount:Number(url.searchParams.get('amount')||0),areaId:url.searchParams.get('areaId'),cityId:url.searchParams.get('cityId'),rideType:url.searchParams.get('rideType'),isNewUser:url.searchParams.get('isNewUser')==='true'})});}
if(req.method==='GET'&&path==='/v1/driver/offers'){if(!requireDriver())return;return json(res,200,{items:listEligibleCampaigns({actorType:'DRIVER',actorId:driverUser.id,areaId:url.searchParams.get('areaId'),cityId:url.searchParams.get('cityId'),rideType:url.searchParams.get('rideType')})});}
if(req.method==='GET'&&path==='/v1/partner/offers'){if(!requirePartner())return;return json(res,200,{items:listEligibleCampaigns({actorType:partnerUser.role,actorId:partnerUser.id,areaId:partnerUser.areaId||url.searchParams.get('areaId'),cityId:url.searchParams.get('cityId')})});}
if(req.method==='GET'&&path==='/v1/partner/offer-earnings'){if(!requirePartner())return;return json(res,200,{items:listCampaignRedemptions({actorType:partnerUser.role,actorId:partnerUser.id})});}
if(req.method==='GET'&&path==='/v1/admin/campaigns'){if(!requireAdmin('campaigns.read'))return;return json(res,200,{items:listCampaigns({targetUser:url.searchParams.get('targetUser')||undefined,status:url.searchParams.get('status')||undefined}),summary:campaignSummary()});}
if(req.method==='POST'&&path==='/v1/admin/campaigns'){if(!requireAdmin('campaigns.manage'))return;const item=upsertCampaign({...await readBody(req),createdBy:adminUser.id});writeAudit(adminUser.id,'CAMPAIGN_UPSERTED',{campaignId:item.id,offerName:item.offerName});return json(res,201,item);}
if(req.method==='GET'&&/^\/v1\/admin\/campaigns\/[^/]+$/.test(path)){if(!requireAdmin('campaigns.read'))return;const item=getCampaign(path.split('/')[4]);return item?json(res,200,item):json(res,404,{error:'campaign_not_found'});}
if(req.method==='PATCH'&&/^\/v1\/admin\/campaigns\/[^/]+$/.test(path)){if(!requireAdmin('campaigns.manage'))return;const id=path.split('/')[4],item=upsertCampaign({id,...await readBody(req)});writeAudit(adminUser.id,'CAMPAIGN_UPDATED',{campaignId:id});return json(res,200,item);}
if(req.method==='DELETE'&&/^\/v1\/admin\/campaigns\/[^/]+$/.test(path)){if(!requireAdmin('campaigns.manage'))return;const id=path.split('/')[4],ok=removeCampaign(id);if(ok)writeAudit(adminUser.id,'CAMPAIGN_DELETED',{campaignId:id});return json(res,ok?200:404,{ok});}
if(req.method==='POST'&&/^\/v1\/admin\/campaigns\/[^/]+\/status$/.test(path)){if(!requireAdmin('campaigns.manage'))return;const id=path.split('/')[4],p=await readBody(req),item=setCampaignStatus(id,p.status);if(!item)return json(res,404,{error:'campaign_not_found'});writeAudit(adminUser.id,'CAMPAIGN_STATUS_CHANGED',{campaignId:id,status:p.status});return json(res,200,item);}
if(req.method==='GET'&&path==='/v1/admin/campaign-redemptions'){if(!requireAdmin('campaigns.read'))return;return json(res,200,{items:listCampaignRedemptions({campaignId:url.searchParams.get('campaignId')||undefined,actorType:url.searchParams.get('actorType')||undefined})});}
if(req.method==='POST'&&path==='/v1/admin/campaign-events'){if(!requireAdmin('campaigns.manage'))return;const p=await readBody(req);requireFields(p,['actorType','actorId','metric']);const awards=recordCampaignEvent({...p,eventType:p.eventType||p.metric,eventId:p.eventId||crypto.randomUUID()});writeAudit(adminUser.id,'CAMPAIGN_EVENT_EVALUATED',{metric:p.metric,actorType:p.actorType,actorId:p.actorId,awardCount:awards.length});return json(res,200,{awards});}


if(req.method==='GET'&&path==='/v1/admin/promoters'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listPromoters()});}
if(req.method==='POST'&&path==='/v1/admin/promoter-earnings/release'){if(!requireAdmin('settlements.read')&&!adminCan(adminUser,'*'))return;const p=await readBody(req);requireFields(p,['month']);const out=releaseMonthlyEarnings(p);writeAudit(adminUser.id,'PROMOTER_EARNINGS_RELEASED',out);return json(res,200,out);}

if(req.method==='GET'&&path==='/v1/admin/dashboard'){if(!requireAdmin('dashboard.read'))return;const bookings=listAllBookings(),drivers=listAllDriverProfiles(),runtimeDrivers=listAllRuntimeDrivers(),payments=listAllPayments(),complaints=listAllComplaints(),settlements=listAllSettlements();const activeStatuses=new Set(['SEARCHING','DRIVER_ASSIGNED','DRIVER_ARRIVING','DRIVER_ARRIVED','OTP_VERIFIED','IN_PROGRESS']);return json(res,200,{generatedAt:new Date().toISOString(),cards:{totalBookings:bookings.length,liveRides:bookings.filter(b=>activeStatuses.has(b.status)).length,completedRides:bookings.filter(b=>b.status==='COMPLETED').length,driversRegistered:drivers.length,driversOnline:runtimeDrivers.filter(d=>d.online).length,openComplaints:complaints.filter(c=>c.status!=='CLOSED').length,paymentsCaptured:payments.filter(p=>['CAPTURED','CASH_COLLECTED'].includes(p.status)).length,pendingSettlements:settlements.filter(x=>['REQUESTED','PROCESSING'].includes(x.status)).length,openSos:listSos().filter(x=>x.status!=='RESOLVED').length,openRiskEvents:listRiskEvents().filter(x=>x.status==='OPEN').length},providers:getAdminRuntimeConfig().providers,operations:getAdminRuntimeConfig().operations});}
if(req.method==='GET'&&path==='/v1/admin/rides'){if(!requireAdmin('rides.read'))return;return json(res,200,{items:listAllBookings()});}
if(req.method==='GET'&&path==='/v1/admin/drivers'){if(!requireAdmin('drivers.read'))return;return json(res,200,{profiles:listAllDriverProfiles(),availability:listAllRuntimeDrivers()});}
if(req.method==='GET'&&path==='/v1/admin/payments'){if(!requireAdmin('payments.read'))return;return json(res,200,{items:listAllPayments()});}
if(req.method==='GET'&&path==='/v1/admin/settlements'){if(!requireAdmin('settlements.read'))return;return json(res,200,{items:listAllSettlements()});}
if(req.method==='GET'&&path==='/v1/admin/complaints'){if(!requireAdmin('complaints.read'))return;return json(res,200,{items:listAllComplaints()});}
if(req.method==='PATCH'&&/^\/v1\/admin\/complaints\/[^/]+$/.test(path)){if(!requireAdmin('complaints.manage'))return;const patch=await readBody(req),item=updateComplaint(path.split('/')[4],patch);if(!item)return json(res,404,{error:'complaint_not_found'});writeAudit(adminUser.id,'COMPLAINT_UPDATED',{id:item.id,...patch});return json(res,200,item);}

if(req.method==='GET'&&path==='/v1/admin/sos'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listSos()});}
if(req.method==='PATCH'&&/^\/v1\/admin\/sos\/[^/]+$/.test(path)){if(!requireAdmin('complaints.manage')&&!adminCan(adminUser,'*'))return;const patch=await readBody(req),item=updateSos(path.split('/')[4],patch);if(!item)return json(res,404,{error:'sos_not_found'});writeAudit(adminUser.id,'SOS_UPDATED',{id:item.id,...patch});return json(res,200,item);}
if(req.method==='GET'&&path==='/v1/admin/risk-events'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listRiskEvents()});}
if(req.method==='GET'&&path==='/v1/admin/notifications'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:listNotifications()});}

if(req.method==='GET'&&path==='/v1/admin/payment-webhooks'){if(!requireAdmin('payments.read'))return;return json(res,200,{items:listWebhookEvents()});}
if(req.method==='GET'&&path==='/v1/admin/payment-reconciliations'){if(!requireAdmin('payments.read'))return;return json(res,200,{items:listReconciliations()});}
if(req.method==='POST'&&path==='/v1/admin/payments/reconcile'){if(!requireAdmin('payments.read'))return;const p=await readBody(req);const items=p.paymentId?[getPayment(p.paymentId)].filter(Boolean):listAllPayments();const cfg=getAdminRuntimeConfig(),results=[];for(const payment of items){if(payment.provider==='cash'||!payment.providerPaymentId)continue;const remote=await getPaymentAdapter(payment.provider).fetchPayment(payment.providerPaymentId,cfg.providers.payments.mode);const matched=remote.status===payment.status||(['CAPTURED','PARTIALLY_REFUNDED','REFUNDED'].includes(payment.status)&&remote.status==='CAPTURED');results.push(addReconciliation({paymentId:payment.id,provider:payment.provider,localStatus:payment.status,providerStatus:remote.status,matched,details:{providerPaymentId:payment.providerPaymentId}}));}writeAudit(adminUser.id,'PAYMENTS_RECONCILED',{count:results.length});return json(res,200,{items:results});}
if(req.method==='GET'&&path==='/v1/public/mobile-config'){const app=url.searchParams.get('app')||'passenger';return json(res,200,{...getPublicRuntimeConfig(app),clientProviders:getPublicProviderClientConfig(app)});}
if(req.method==='GET'&&path==='/v1/admin/providers/vault-status'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;return json(res,200,providerVaultStatus());}
if(req.method==='GET'&&path==='/v1/admin/providers/credentials'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;return json(res,200,{items:listCredentialStatus()});}
if(req.method==='PUT'&&path==='/v1/admin/providers/credentials'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;const p=await readBody(req);requireFields(p,['type','name','mode','credentials']);const status=putProviderCredential(p.type,p.name,p.mode,p.credentials);writeAudit(adminUser.id,'PROVIDER_CREDENTIAL_UPDATED',{type:p.type,name:p.name,mode:p.mode});return json(res,200,status);}
if(req.method==='DELETE'&&path==='/v1/admin/providers/credentials'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;const p=await readBody(req);requireFields(p,['type','name','mode']);const deleted=deleteProviderCredential(p.type,p.name,p.mode);writeAudit(adminUser.id,'PROVIDER_CREDENTIAL_DELETED',{type:p.type,name:p.name,mode:p.mode});return json(res,200,{deleted});}
if(req.method==='POST'&&path==='/v1/admin/providers/test'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;const p=await readBody(req);requireFields(p,['type','name']);const cfg=getAdminRuntimeConfig();let result;if(p.type==='otp')result=await getOtpAdapter(p.name).send(p.mobile||'919999999999',p.code||'123456',p.mode||'test');else if(p.type==='notifications')result=await getNotificationAdapter(p.name).send({id:'test',deviceToken:p.deviceToken||'test-token',type:'TEST',title:'Test notification',body:'Provider test',payload:{}},p.mode||'test');else if(p.type==='payments')result=await getPaymentAdapter(p.name).createOrder(100,'provider-test',p.mode||'test');else throw new Error('Unsupported provider test type');writeAudit(adminUser.id,'PROVIDER_TESTED',{type:p.type,name:p.name});return json(res,200,result);}
if(req.method==='GET'&&path==='/v1/admin/devices'){if(!requireAdmin('dashboard.read'))return;return json(res,200,{items:allDevices()});}
if(req.method==='GET'&&path==='/v1/admin/audit'){if(!requireAdmin('audit.read')&&!adminCan(adminUser,'*'))return;return json(res,200,{items:listAudit()});}
if(req.method==='GET'&&path==='/v1/admin/storage/status'){if(!requireAdmin('audit.read')&&!adminCan(adminUser,'*'))return;return json(res,200,await persistenceStatus());}
if(req.method==='POST'&&path==='/v1/admin/storage/flush'){if(!requireAdmin('config.write')&&!adminCan(adminUser,'*'))return;return json(res,200,await flushPersistence());}

return json(res,404,{error:'not_found'});}catch(error){return json(res,400,{error:'bad_request',message:error.message});}});
attachRideWebSocket(server,{authenticate:(req,url,bookingId)=>{
 const token=req.headers.authorization||url.searchParams.get('access_token')||url.searchParams.get('token');
 const booking=getBooking(bookingId);if(!booking||!token)return null;
 const admin=authenticateAdmin(token);if(admin&&adminCan(admin,'rides.read'))return {actorType:'admin',actorId:admin.id,bookingId};
 const passenger=authenticatePassengerToken(token);if(passenger&&booking.passengerId===passenger.id)return {actorType:'passenger',actorId:passenger.id,bookingId};
 const driver=authenticateDriverToken(token);if(driver&&booking.driverId===driver.id)return {actorType:'driver',actorId:driver.id,bookingId};
 return null;
}});
if(process.argv[1]===new URL(import.meta.url).pathname){assertProductionReady();const port=Number(process.env.PORT||3333);await initializePersistence();server.listen(port,()=>console.log(`API listening on ${port} (${databaseMode()})`));}
