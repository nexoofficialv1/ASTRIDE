const ceilStep=(value,step)=>Math.ceil(Math.max(0,value)/step)*step;
export const rideTypes=['FULL_TOTO','SHARE_TOTO','MOTORCYCLE'];
export const paymentPreferences=['CASH','UPI','BOTH'];
export function serviceAvailability({rideType,isOutsideArea,isNight,motorcycleAvailable=true}){
  if(!rideTypes.includes(rideType))throw new Error('Unsupported ride type');
  if(isOutsideArea&&rideType!=='FULL_TOTO')return {available:false,reason:'OUTSIDE_AREA_FULL_TOTO_ONLY'};
  if(isNight&&rideType==='SHARE_TOTO')return {available:false,reason:'SHARE_TOTO_UNAVAILABLE_AT_NIGHT'};
  if(isNight&&rideType==='MOTORCYCLE'&&!motorcycleAvailable)return {available:false,reason:'NO_ELIGIBLE_MOTORCYCLE_DRIVER'};
  return {available:true,reason:null};
}
export function calculateFareQuote(input,rules){
  const {rideType,distanceKm,isOutsideArea=false,isNight=false,dynamicMultiplier=1,waitingMinutes=0}=input;
  if(distanceKm<=0)throw new Error('Distance must be positive');
  if(rideType==='FULL_TOTO'&&distanceKm>rules.maximumTotoDistanceKm)throw new Error('TOTO_DISTANCE_LIMIT_EXCEEDED');
  const r=rules.rideTypes[rideType]; if(!r)throw new Error('Fare rule missing');
  const base=r.minimumFare;
  const excess=Math.max(0,distanceKm-r.includedKm);
  const distanceCharge=ceilStep(excess,r.additionalStepKm)/r.additionalStepKm*r.additionalStepFare;
  let outsideCharge=0,returnCompensation=0;
  if(isOutsideArea){outsideCharge=ceilStep(input.outsideDistanceKm||0,rules.outsideArea.stepKm)/rules.outsideArea.stepKm*rules.outsideArea.stepFare;returnCompensation=Math.round(outsideCharge*rules.outsideArea.returnCompensationPercent/100);}
  const subtotal=base+distanceCharge+outsideCharge+returnCompensation;
  const nightCharge=isNight?Math.round(subtotal*(r.nightSurchargePercent||0)/100):0;
  const dynamicCharge=Math.max(0,Math.round(subtotal*(Math.min(dynamicMultiplier,rules.dynamicPricing.maxMultiplier)-1)));
  const billableWaiting=Math.max(0,waitingMinutes-rules.waiting.freeMinutes);
  const waitingCharge=Math.min(rules.waiting.maxCharge,Math.ceil(billableWaiting)*rules.waiting.perMinute);
  const total=subtotal+nightCharge+dynamicCharge+waitingCharge;
  return {rideType,distanceKm,total,currency:rules.currency,breakdown:{baseFare:base,distanceCharge,outsideAreaCharge:outsideCharge,returnCompensation,nightCharge,dynamicCharge,waitingCharge}};
}
export function calculateCommissionSplit({fareAmount,rideType,hasPromoter=true,hasAreaPromoter=true},rules){
  const r=rules.rideTypes[rideType]; if(!r)throw new Error('Commission rule missing');
  const gross=Math.min(Math.round(fareAmount*r.companyCommissionPercent/100),r.companyCommissionMaximum);
  const promoter=hasPromoter?Math.round(gross*r.promoterShareOfCompanyCommissionPercent)/100:0;
  const areaPromoter=hasAreaPromoter?Math.round(gross*r.areaPromoterShareOfCompanyCommissionPercent)/100:0;
  const companyNet=Number((gross-promoter-areaPromoter).toFixed(2));
  return {fareAmount,driverShare:Number((fareAmount-gross).toFixed(2)),companyGross:gross,promoterShare:promoter,areaPromoterShare:areaPromoter,companyNet};
}
export function driverMatchesPayment(driverPreference,passengerPreference){
  if(!paymentPreferences.includes(passengerPreference))throw new Error('Invalid passenger payment preference');
  const acceptsCash=Boolean(driverPreference.acceptsCash),acceptsUpi=Boolean(driverPreference.acceptsUpi);
  return passengerPreference==='CASH'?acceptsCash:passengerPreference==='UPI'?acceptsUpi:(acceptsCash||acceptsUpi);
}
export function evaluateLateArrival({committedArrivalAt,actualArrivalAt,graceMinutes,flatPenalty=0,perMinutePenalty=0,maxPenalty=0,waived=false}){
  const lateMinutes=Math.max(0,Math.ceil((new Date(actualArrivalAt)-new Date(committedArrivalAt))/60000)-graceMinutes);
  const penalty=waived?0:Math.min(maxPenalty||Infinity,lateMinutes>0?flatPenalty+lateMinutes*perMinutePenalty:0);
  return {lateMinutes,penalty,passengerWalletCredit:penalty,driverPenalty:penalty,status:waived?'WAIVED':penalty>0?'APPLIED':'NOT_APPLICABLE'};
}
