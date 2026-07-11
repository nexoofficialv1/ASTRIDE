import assert from 'node:assert/strict';
import { upsertCampaign,validateOfferCode,recordCampaignEvent,listCampaignRedemptions,campaignSummary,exportCampaignStoreState,restoreCampaignStoreState } from '../services/api/src/store/campaign-store.mjs';

const active={startDate:new Date(Date.now()-60000).toISOString(),endDate:new Date(Date.now()+86400000).toISOString(),status:'ACTIVE'};
const first=upsertCampaign({...active,offerName:'Flat 20 Off',offerCode:'FIRST20',targetUser:'PASSENGER',rewardType:'FLAT_DISCOUNT',rewardValue:20,metric:'PROMO_CODE',perUserLimit:1,maximumPayout:100,areaIds:['KALNA'],rideTypes:['FULL_TOTO']});
let check=validateOfferCode({code:'FIRST20',actorType:'PASSENGER',actorId:'p1',amount:50,areaId:'KALNA',rideType:'FULL_TOTO',isNewUser:true});
assert.equal(check.valid,true);assert.equal(check.rewardAmount,20);
check=validateOfferCode({code:'FIRST20',actorType:'PASSENGER',actorId:'p1',amount:50,areaId:'OTHER',rideType:'FULL_TOTO'});assert.equal(check.valid,false);

const driver=upsertCampaign({...active,offerName:'Complete 3 Rides Get 50',targetUser:'DRIVER',rewardType:'TARGET_BONUS',rewardValue:50,metric:'RIDE_COMPLETED',requiredCount:3,perUserLimit:2,maximumPayout:100});
assert.equal(recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r1',amount:50}).length,0);
assert.equal(recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r2',amount:50}).length,0);
let awards=recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r3',amount:50});assert.equal(awards.length,1);assert.equal(awards[0].amount,50);
assert.equal(recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r3',amount:50}).length,0,'duplicate event must not pay twice');
recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r4',amount:50});recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r5',amount:50});awards=recordCampaignEvent({actorType:'DRIVER',actorId:'d1',metric:'RIDE_COMPLETED',eventId:'r6',amount:50});assert.equal(awards.length,1);assert.equal(campaignSummary().totalPayout,100);
assert.equal(listCampaignRedemptions({actorId:'d1'}).length,2);
const state=exportCampaignStoreState();restoreCampaignStoreState(state);assert.equal(campaignSummary().total,2);assert.equal(first.offerCode,'FIRST20');assert.equal(driver.targetUser,'DRIVER');
console.log('v3.11 offer campaign tests passed');
