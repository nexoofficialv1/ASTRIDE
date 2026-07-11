import crypto from 'node:crypto';

const campaigns=new Map();
const redemptions=[];
const eventCounters=new Map();
const clone=x=>structuredClone(x);
const now=()=>new Date().toISOString();
const allowedTargets=new Set(['DRIVER','PASSENGER','PROMOTER','AREA_PROMOTER']);
const allowedStates=new Set(['DRAFT','SCHEDULED','ACTIVE','PAUSED','EXPIRED']);
const allowedRewards=new Set(['FLAT_DISCOUNT','PERCENT_DISCOUNT','CASHBACK','FIXED_BONUS','ZERO_COMMISSION','TARGET_BONUS','REFERRAL_BONUS']);

function computedStatus(item,at=new Date()){
  if(item.status==='DRAFT'||item.status==='PAUSED')return item.status;
  const start=item.startDate?new Date(item.startDate):null,end=item.endDate?new Date(item.endDate):null;
  if(end&&at>end)return 'EXPIRED';
  if(start&&at<start)return 'SCHEDULED';
  return item.status==='EXPIRED'?'EXPIRED':'ACTIVE';
}
function sanitize(input,previous={}){
  const targetUser=String(input.targetUser||previous.targetUser||'PASSENGER').toUpperCase();
  if(!allowedTargets.has(targetUser))throw new Error('Invalid campaign targetUser');
  const rewardType=String(input.rewardType||previous.rewardType||'FIXED_BONUS').toUpperCase();
  if(!allowedRewards.has(rewardType))throw new Error('Invalid rewardType');
  const status=String(input.status||previous.status||'DRAFT').toUpperCase();
  if(!allowedStates.has(status))throw new Error('Invalid campaign status');
  const item={
    id:input.id||previous.id||crypto.randomUUID(),
    offerName:String(input.offerName||previous.offerName||'').trim(),
    offerCode:String(input.offerCode??previous.offerCode??'').trim().toUpperCase()||null,
    description:String(input.description??previous.description??''),
    targetUser,status,startDate:input.startDate??previous.startDate??null,endDate:input.endDate??previous.endDate??null,
    areaIds:[...new Set((input.areaIds??previous.areaIds??[]).map(String))],
    cityIds:[...new Set((input.cityIds??previous.cityIds??[]).map(String))],
    rideTypes:[...new Set((input.rideTypes??previous.rideTypes??[]).map(x=>String(x).toUpperCase()))],
    termsAndConditions:String(input.termsAndConditions??previous.termsAndConditions??''),
    rewardType,
    rewardValue:Number(input.rewardValue??previous.rewardValue??0),
    maximumReward:Number(input.maximumReward??previous.maximumReward??0)||null,
    requiredCount:Number(input.requiredCount??previous.requiredCount??1),
    metric:String(input.metric??previous.metric??'RIDE_COMPLETED').toUpperCase(),
    perUserLimit:Number(input.perUserLimit??previous.perUserLimit??1),
    minimumAmount:Number(input.minimumAmount??previous.minimumAmount??0),
    maximumPayout:Number(input.maximumPayout??previous.maximumPayout??0)||null,
    payoutAmount:Number(previous.payoutAmount||0),
    redemptionCount:Number(previous.redemptionCount||0),
    newUsersOnly:Boolean(input.newUsersOnly??previous.newUsersOnly??false),
    metadata:{...(previous.metadata||{}),...(input.metadata||{})},
    createdBy:input.createdBy||previous.createdBy||null,
    createdAt:previous.createdAt||now(),updatedAt:now()
  };
  if(!item.offerName)throw new Error('Offer Name is required');
  if(item.endDate&&item.startDate&&new Date(item.endDate)<=new Date(item.startDate))throw new Error('End Date must be after Start Date');
  if(item.rewardValue<0||item.requiredCount<1||item.perUserLimit<1)throw new Error('Invalid reward configuration');
  return item;
}
function codeConflict(item){return item.offerCode&&[...campaigns.values()].some(x=>x.id!==item.id&&x.offerCode===item.offerCode);}
export function upsertCampaign(input){const previous=input.id?campaigns.get(input.id):null;const item=sanitize(input,previous||{});if(codeConflict(item))throw new Error('Offer Code already exists');campaigns.set(item.id,item);return getCampaign(item.id);}
export function getCampaign(id){const x=campaigns.get(id);return x?{...clone(x),effectiveStatus:computedStatus(x)}:null;}
export function listCampaigns(filter={}){return [...campaigns.values()].filter(x=>(!filter.targetUser||x.targetUser===filter.targetUser)&&(!filter.status||computedStatus(x)===filter.status)).map(x=>({...clone(x),effectiveStatus:computedStatus(x)}));}
export function removeCampaign(id){return campaigns.delete(id);}
export function setCampaignStatus(id,status){const x=campaigns.get(id);if(!x)return null;const next=String(status).toUpperCase();if(!allowedStates.has(next))throw new Error('Invalid campaign status');x.status=next;x.updatedAt=now();return getCampaign(id);}
function matches(c,ctx){if(computedStatus(c)!=='ACTIVE'||c.targetUser!==ctx.actorType)return false;if(c.areaIds.length&&(!ctx.areaId||!c.areaIds.includes(String(ctx.areaId))))return false;if(c.cityIds.length&&(!ctx.cityId||!c.cityIds.includes(String(ctx.cityId))))return false;if(c.rideTypes.length&&(!ctx.rideType||!c.rideTypes.includes(String(ctx.rideType).toUpperCase())))return false;if(Number(ctx.amount||0)<c.minimumAmount)return false;if(c.newUsersOnly&&!ctx.isNewUser)return false;return true;}
function userRedemptions(campaignId,actorId){return redemptions.filter(x=>x.campaignId===campaignId&&x.actorId===actorId&&x.status!=='REVERSED');}
function calculateReward(c,ctx){const base=Number(ctx.amount||0),commission=Number(ctx.commissionAmount||0);let amount=0;if(c.rewardType==='PERCENT_DISCOUNT')amount=base*c.rewardValue/100;else if(c.rewardType==='ZERO_COMMISSION')amount=commission;else amount=c.rewardValue;if(c.maximumReward)amount=Math.min(amount,c.maximumReward);return Number(Math.max(0,amount).toFixed(2));}
export function validateOfferCode({code,actorType='PASSENGER',actorId,amount=0,areaId=null,cityId=null,rideType=null,isNewUser=false}){const normalized=String(code||'').trim().toUpperCase(),c=[...campaigns.values()].find(x=>x.offerCode===normalized);if(!c)return {valid:false,reason:'offer_not_found'};const ctx={actorType,actorId,amount,areaId,cityId,rideType,isNewUser};if(!matches(c,ctx))return {valid:false,reason:'offer_not_eligible',campaign:getCampaign(c.id)};if(userRedemptions(c.id,actorId).length>=c.perUserLimit)return {valid:false,reason:'user_limit_reached'};const rewardAmount=calculateReward(c,ctx);if(c.maximumPayout&&c.payoutAmount+rewardAmount>c.maximumPayout)return {valid:false,reason:'budget_exhausted'};return {valid:true,campaign:getCampaign(c.id),rewardAmount};}
export function listEligibleCampaigns(ctx){return [...campaigns.values()].filter(c=>matches(c,ctx)&&userRedemptions(c.id,ctx.actorId).length<c.perUserLimit).map(c=>({...getCampaign(c.id),estimatedReward:calculateReward(c,ctx)}));}
export function recordCampaignEvent(ctx){const eventId=ctx.eventId||ctx.bookingId||crypto.randomUUID(),awards=[];for(const c of campaigns.values()){
  if(!matches(c,ctx)||c.metric!==String(ctx.metric||ctx.eventType||'').toUpperCase())continue;
  if(redemptions.some(x=>x.campaignId===c.id&&x.eventId===eventId&&x.actorId===ctx.actorId))continue;
  if(userRedemptions(c.id,ctx.actorId).length>=c.perUserLimit)continue;
  const counterKey=`${c.id}:${ctx.actorId}:${c.metric}`;const count=(eventCounters.get(counterKey)||0)+Number(ctx.increment||1);eventCounters.set(counterKey,count);
  if(count<c.requiredCount||count%c.requiredCount!==0)continue;
  const amount=calculateReward(c,ctx);if(amount<=0)continue;if(c.maximumPayout&&c.payoutAmount+amount>c.maximumPayout)continue;
  const item={id:crypto.randomUUID(),campaignId:c.id,campaignName:c.offerName,actorType:ctx.actorType,actorId:ctx.actorId,eventId,bookingId:ctx.bookingId||null,amount,status:'APPROVED',metric:c.metric,progress:count,createdAt:now(),metadata:ctx.metadata||{}};
  redemptions.unshift(item);c.payoutAmount=Number((c.payoutAmount+amount).toFixed(2));c.redemptionCount++;c.updatedAt=now();awards.push(clone(item));
 }return awards;
}
export function redeemOfferCode({code,eventId,actorId,amount,areaId,cityId,rideType,isNewUser=false,bookingId=null}){const result=validateOfferCode({code,actorType:'PASSENGER',actorId,amount,areaId,cityId,rideType,isNewUser});if(!result.valid)return result;const c=campaigns.get(result.campaign.id);if(redemptions.some(x=>x.campaignId===c.id&&x.eventId===eventId&&x.actorId===actorId))return {valid:true,duplicate:true,rewardAmount:result.rewardAmount,campaign:getCampaign(c.id)};const item={id:crypto.randomUUID(),campaignId:c.id,campaignName:c.offerName,actorType:'PASSENGER',actorId,eventId,bookingId,amount:result.rewardAmount,status:'APPROVED',metric:'PROMO_CODE',progress:1,createdAt:now(),metadata:{code:c.offerCode}};redemptions.unshift(item);c.payoutAmount=Number((c.payoutAmount+item.amount).toFixed(2));c.redemptionCount++;return {valid:true,rewardAmount:item.amount,campaign:getCampaign(c.id),redemption:clone(item)};}
export function listCampaignRedemptions(filter={}){return redemptions.filter(x=>(!filter.campaignId||x.campaignId===filter.campaignId)&&(!filter.actorId||x.actorId===filter.actorId)&&(!filter.actorType||x.actorType===filter.actorType)).map(clone);}
export function campaignSummary(){const items=listCampaigns();return {total:items.length,active:items.filter(x=>x.effectiveStatus==='ACTIVE').length,scheduled:items.filter(x=>x.effectiveStatus==='SCHEDULED').length,expired:items.filter(x=>x.effectiveStatus==='EXPIRED').length,totalPayout:Number(items.reduce((s,x)=>s+x.payoutAmount,0).toFixed(2)),redemptions:redemptions.length};}
export function exportCampaignStoreState(){return {campaigns:[...campaigns.entries()],redemptions:clone(redemptions),eventCounters:[...eventCounters.entries()]};}
export function restoreCampaignStoreState(s={}){campaigns.clear();redemptions.length=0;eventCounters.clear();for(const x of s.campaigns||[])campaigns.set(...x);redemptions.push(...(s.redemptions||[]));for(const x of s.eventCounters||[])eventCounters.set(...x);}
