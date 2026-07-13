import crypto from 'node:crypto';
const drivers=new Map(); const documents=new Map(); const wallets=new Map(); const settlements=[]; const driverSessions=new Map();
const DRIVER_SESSION_TTL_MS=Number(process.env.DRIVER_SESSION_TTL_MS||24*3600_000);
const id=(p)=>`${p}_${crypto.randomUUID().slice(0,8)}`;
export function registerDriver(input){
  const createdAt=new Date().toISOString();
  const createdByType=String(input.createdByType||'ADMIN_ASSIGNED').toUpperCase();
  const promoterId=input.promoterId||null;
  const areaPromoterId=input.areaPromoterId||null;
  const promoterAssigned=Boolean(promoterId);
  const d={
    id:id('drv'),mobile:input.mobile,fullName:input.fullName||'',
    preferredLanguage:input.preferredLanguage||'en',status:'DRAFT',
    approved:false,suspended:false,online:false,location:null,rating:5,
    totalRides:0,createdAt,vehicle:input.vehicle||{},
    primaryZoneId:input.primaryZoneId||null,
    operatingMode:input.operatingMode||'BOTH',
    seatCapacity:Number(input.seatCapacity||4),bank:input.bank||{},
    upiId:input.upiId||null,address:input.address||null,
    emergencyContact:input.emergencyContact||null,
    photoUrl:input.photoUrl||null,
    onboardingStep:input.onboardingStep||'PROFILE',
    approvalFlow:{
      createdByType,createdById:input.createdById||null,
      promoterId,areaPromoterId,
      promoter:{status:promoterAssigned?'PENDING':'NOT_ASSIGNED',reviewedBy:null,reviewedAt:null,remarks:null},
      areaPromoter:{status:promoterAssigned?(areaPromoterId?'PENDING':'NOT_ASSIGNED'):'NOT_ASSIGNED',reviewedBy:null,reviewedAt:null,remarks:null},
      admin:{status:'PENDING',reviewedBy:null,reviewedAt:null,remarks:null,bypassedArea:false,bypassReason:null},
    },
  };
  drivers.set(d.id,d);
  wallets.set(d.id,{driverId:d.id,balancePaise:0,lifetimeEarningsPaise:0,commissionPaidPaise:0,transactions:[]});
  return structuredClone(d);
}
export const getDriverProfile=(id)=>drivers.get(id)||null;

export function createDriverSession(driverId){if(!drivers.has(driverId))throw new Error('Driver not found');const token=crypto.randomBytes(32).toString('base64url');driverSessions.set(token,{driverId,expiresAt:Date.now()+DRIVER_SESSION_TTL_MS});return {token,expiresInSeconds:Math.floor(DRIVER_SESSION_TTL_MS/1000)};}
export function authenticateDriverToken(tokenOrHeader){const token=String(tokenOrHeader||'').replace(/^Bearer\s+/i,'');const session=driverSessions.get(token);if(!session||session.expiresAt<=Date.now()){if(token)driverSessions.delete(token);return null;}const driver=drivers.get(session.driverId);return driver?{...structuredClone(driver),sessionExpiresAt:new Date(session.expiresAt).toISOString()}:null;}
export function revokeDriverSession(tokenOrHeader){const token=String(tokenOrHeader||'').replace(/^Bearer\s+/i,'');return driverSessions.delete(token);}
export function findDriverByMobile(mobile){const normalized=String(mobile||'').replace(/\D/g,'');return [...drivers.values()].find(d=>String(d.mobile||'').replace(/\D/g,'')===normalized)||null;}

export function updateDriverProfile(id,patch){const d=getDriverProfile(id);if(!d)return null;Object.assign(d,patch,{id:d.id,updatedAt:new Date().toISOString()});return d;}
export function addDriverDocument(driverId,input){const d=drivers.get(driverId);if(!d)return null;const createdAt=new Date().toISOString();const doc={id:id('doc'),driverId,type:input.type,fileUrl:input.fileUrl,number:input.number||null,expiresOn:input.expiresOn||null,status:'PENDING',remarks:null,createdAt};const list=documents.get(driverId)||[];list.push(doc);documents.set(driverId,list);const flow=ensureApprovalFlow(d);flow.promoter=stageRecord(flow.promoterId?'PENDING':'NOT_ASSIGNED');flow.areaPromoter=stageRecord(flow.areaPromoterId?'PENDING':'NOT_ASSIGNED');flow.admin={status:'PENDING',reviewedBy:null,reviewedAt:null,remarks:null,bypassedArea:false,bypassReason:null};d.approved=false;d.online=false;d.suspended=false;if(d.status==='APPROVED'||d.status==='REJECTED')d.status='DOCUMENTS_UPDATED';d.updatedAt=createdAt;return structuredClone(doc);}
export const listDriverDocuments=(driverId)=>documents.get(driverId)||[];

const REQUIRED_DRIVER_DOCUMENT_TYPES=[
  'IDENTITY_DOCUMENT',
  'VEHICLE_REGISTRATION',
  'VEHICLE_PHOTO',
  'PROFILE_PHOTO',
  'BANK_DETAILS',
];


const stageRecord=(status='PENDING')=>({
  status,
  reviewedBy:null,
  reviewedAt:null,
  remarks:null,
});

function ensureApprovalFlow(driver){
  if(driver.approvalFlow)return driver.approvalFlow;
  driver.approvalFlow={
    createdByType:'ADMIN_ASSIGNED',
    createdById:null,
    promoterId:null,
    areaPromoterId:null,
    promoter:stageRecord('NOT_ASSIGNED'),
    areaPromoter:stageRecord('NOT_ASSIGNED'),
    admin:{
      ...stageRecord('PENDING'),
      bypassedArea:false,
      bypassReason:null,
    },
  };
  return driver.approvalFlow;
}

export function setDriverApprovalContext(driverId,context={}){
  const driver=getDriverProfile(driverId);
  if(!driver)return null;
  const createdByType=String(context.createdByType||'ADMIN_ASSIGNED').toUpperCase();
  const promoterId=context.promoterId||null;
  const areaPromoterId=context.areaPromoterId||null;
  driver.approvalFlow={
    createdByType,createdById:context.createdById||null,
    promoterId,areaPromoterId,
    promoter:stageRecord(promoterId?'PENDING':'NOT_ASSIGNED'),
    areaPromoter:stageRecord(promoterId?(areaPromoterId?'PENDING':'NOT_ASSIGNED'):'NOT_ASSIGNED'),
    admin:{...stageRecord('PENDING'),bypassedArea:false,bypassReason:null},
  };
  driver.approved=false;driver.online=false;driver.suspended=false;
  driver.status='DRAFT';driver.updatedAt=new Date().toISOString();
  return structuredClone(driver.approvalFlow);
}

export function reviewDriverDocument(
  driverId,
  documentId,
  {status,remarks,reviewedBy=null},
){
  const allowed=new Set(['APPROVED','REJECTED']);
  if(!allowed.has(status))throw new Error('Invalid document review status');
  const driver=getDriverProfile(driverId);
  if(!driver)return null;
  const list=documents.get(driverId)||[];
  const document=list.find(item=>item.id===documentId);
  if(!document)return null;

  document.status=status;
  document.remarks=remarks||null;
  document.reviewedBy=reviewedBy;
  document.reviewedAt=new Date().toISOString();
  document.updatedAt=document.reviewedAt;

  const flow=ensureApprovalFlow(driver);
  flow.admin={
    status:status==='REJECTED'?'REJECTED':'PENDING',
    reviewedBy:status==='REJECTED'?reviewedBy:null,
    reviewedAt:status==='REJECTED'?document.reviewedAt:null,
    remarks:status==='REJECTED'?(remarks||`Document rejected: ${document.type}`):null,
    bypassedArea:false,
    bypassReason:null,
  };
  driver.approved=false;
  driver.online=false;
  if(status==='REJECTED'){
    driver.status='REJECTED';
    driver.reviewRemarks=remarks||`Document rejected: ${document.type}`;
  }else if(driver.status==='APPROVED'){
    driver.status='DOCUMENT_REVIEW_PENDING';
  }
  driver.updatedAt=document.reviewedAt;

  return structuredClone(document);
}

function latestDocumentsByType(driverId){
  const latest=new Map();
  for(const document of documents.get(driverId)||[]){
    latest.set(document.type,document);
  }
  return latest;
}

export function getDriverVerificationSummary(driverId){
  const latest=latestDocumentsByType(driverId);
  const required=REQUIRED_DRIVER_DOCUMENT_TYPES.map(type=>{
    const document=latest.get(type)||null;
    return {
      type,
      uploaded:Boolean(document),
      status:document?.status||'MISSING',
      documentId:document?.id||null,
    };
  });
  const approvedCount=required.filter(item=>item.status==='APPROVED').length;
  const rejectedCount=required.filter(item=>item.status==='REJECTED').length;
  const pendingCount=required.filter(item=>item.status==='PENDING').length;
  const missingCount=required.filter(item=>item.status==='MISSING').length;
  return {
    required,
    requiredCount:required.length,
    approvedCount,
    rejectedCount,
    pendingCount,
    missingCount,
    readyForApproval:
      approvedCount===required.length &&
      rejectedCount===0 &&
      pendingCount===0 &&
      missingCount===0,
  };
}


export function getDriverApprovalSummary(driverId){
  const driver=getDriverProfile(driverId);if(!driver)return null;
  const flow=ensureApprovalFlow(driver);
  const verification=getDriverVerificationSummary(driverId);
  const allDocumentsUploaded=verification.missingCount===0;
  const promoterAssigned=Boolean(flow.promoterId);
  const areaPromoterAssigned=Boolean(flow.areaPromoterId);
  const promoterApproved=promoterAssigned&&flow.promoter?.status==='APPROVED';
  const areaApproved=areaPromoterAssigned&&flow.areaPromoter?.status==='APPROVED';
  const documentsFinalApproved=verification.readyForApproval;
  return {
    createdByType:flow.createdByType,createdById:flow.createdById,
    promoterId:flow.promoterId,areaPromoterId:flow.areaPromoterId,
    promoterAssigned,areaPromoterAssigned,
    promoter:structuredClone(flow.promoter),
    areaPromoter:structuredClone(flow.areaPromoter),
    admin:structuredClone(flow.admin),allDocumentsUploaded,
    documentsFinalApproved,promoterApproved,areaApproved,
    canPromoterApprove:promoterAssigned&&flow.promoter?.status!=='APPROVED'&&allDocumentsUploaded,
    canAreaApprove:areaPromoterAssigned&&flow.areaPromoter?.status!=='APPROVED'&&promoterApproved&&allDocumentsUploaded,
    canAdminApprove:promoterApproved&&areaApproved&&documentsFinalApproved,
    canAdminApproveWithBypass:promoterApproved&&!areaApproved&&documentsFinalApproved,
    suspended:Boolean(driver.suspended||driver.status==='SUSPENDED'),
    canLiftSuspension:Boolean((driver.suspended||driver.status==='SUSPENDED')&&flow.admin?.status==='APPROVED'&&documentsFinalApproved),
    stage:!promoterAssigned?'PROMOTER_ASSIGNMENT_REQUIRED':driver.approved?'ADMIN_APPROVED':flow.areaPromoter?.status==='APPROVED'?'AREA_APPROVED':flow.promoter?.status==='APPROVED'?'PROMOTER_APPROVED':allDocumentsUploaded?'DOCUMENTS_COMPLETE':'DOCUMENTS_PENDING',
  };
}

export function reviewDriverStage(
  driverId,
  {stage,status,actorId,remarks=null,bypassArea=false},
){
  const driver=getDriverProfile(driverId);
  if(!driver)return null;
  const normalizedStage=String(stage||'').toUpperCase();
  const normalizedStatus=String(status||'').toUpperCase();
  if(!['PROMOTER','AREA_PROMOTER','ADMIN'].includes(normalizedStage)){
    throw new Error('Invalid approval stage');
  }
  if(!['APPROVED','REJECTED'].includes(normalizedStatus)){
    throw new Error('Invalid approval status');
  }

  const flow=ensureApprovalFlow(driver);
  const summary=getDriverApprovalSummary(driverId);
  const reviewedAt=new Date().toISOString();
  const record={
    status:normalizedStatus,
    reviewedBy:actorId||null,
    reviewedAt,
    remarks:remarks||null,
  };

  if(normalizedStage==='PROMOTER'){
    if(!flow.promoterId||flow.promoter?.status==='NOT_ASSIGNED'){
      throw new Error('A Promoter must be assigned first');
    }
    if(!summary.allDocumentsUploaded && normalizedStatus==='APPROVED'){
      throw new Error('All mandatory documents must be uploaded first');
    }
    flow.promoter=record;
    if(normalizedStatus==='APPROVED'){
      if(flow.areaPromoter?.status==='REJECTED'){
        flow.areaPromoter=stageRecord(
          flow.areaPromoterId?'PENDING':'NOT_ASSIGNED',
        );
      }
      flow.admin={
        ...stageRecord('PENDING'),
        bypassedArea:false,
        bypassReason:null,
      };
      driver.status='PROMOTER_APPROVED';
    }
  }

  if(normalizedStage==='AREA_PROMOTER'){
    if(!summary.promoterApproved){
      throw new Error('Promoter partial approval is required first');
    }
    if(!flow.areaPromoterId||flow.areaPromoter?.status==='NOT_ASSIGNED'){
      throw new Error('No Area Promoter is assigned');
    }
    flow.areaPromoter=record;
    flow.admin={
      ...stageRecord('PENDING'),
      bypassedArea:false,
      bypassReason:null,
    };
    if(normalizedStatus==='APPROVED'){
      driver.status='AREA_APPROVED';
    }
  }

  if(normalizedStage==='ADMIN'){
    if(normalizedStatus==='APPROVED'){
      if(!summary.promoterApproved){
        throw new Error('Promoter partial approval is required first');
      }
      if(!summary.documentsFinalApproved){
        throw new Error('Admin must approve all mandatory documents first');
      }
      if(!summary.areaApproved && !bypassArea){
        throw new Error('Area Promoter approval is pending');
      }
      if(!summary.areaApproved && bypassArea && !String(remarks||'').trim()){
        throw new Error('A bypass reason is required');
      }
      flow.admin={
        ...record,
        bypassedArea:!summary.areaApproved && Boolean(bypassArea),
        bypassReason:!summary.areaApproved && bypassArea?String(remarks).trim():null,
      };
      driver.status='APPROVED';
      driver.approved=true;
      driver.suspended=false;
    }else{
      flow.admin={
        ...record,
        bypassedArea:false,
        bypassReason:null,
      };
    }
  }

  if(normalizedStatus==='REJECTED'){
    driver.status='REJECTED';
    driver.approved=false;
    driver.suspended=false;
    driver.online=false;
    driver.reviewRemarks=remarks||`${normalizedStage} rejected the driver`;
  }else if(normalizedStage!=='ADMIN'){
    driver.approved=false;
    driver.online=false;
  }

  driver.reviewedAt=reviewedAt;
  driver.updatedAt=reviewedAt;
  return structuredClone(driver);
}


export function suspendDriver(
 driverId,
 {reason,actorId=null}={},
){
 const driver=getDriverProfile(driverId);
 if(!driver)return null;
 const clean=String(reason||'').trim();
 if(!clean)throw new Error('suspension_reason_required');
 const changedAt=new Date().toISOString();
 driver.suspension={
   active:true,
   reason:clean,
   suspendedBy:actorId,
   suspendedAt:changedAt,
   previousStatus:driver.status,
   previouslyApproved:Boolean(driver.approved),
 };
 driver.status='SUSPENDED';
 driver.approved=false;
 driver.suspended=true;
 driver.online=false;
 driver.reviewRemarks=clean;
 driver.updatedAt=changedAt;
 return structuredClone(driver);
}

export function liftDriverSuspension(
 driverId,
 {reason=null,actorId=null}={},
){
 const driver=getDriverProfile(driverId);
 if(!driver)return null;
 if(!driver.suspended&&driver.status!=='SUSPENDED'){
   throw new Error('driver_is_not_suspended');
 }
 const flow=ensureApprovalFlow(driver);
 const verification=getDriverVerificationSummary(driverId);
 const summary=getDriverApprovalSummary(driverId);
 const changedAt=new Date().toISOString();
 const restoreApproved=
   flow.admin?.status==='APPROVED' &&
   verification.readyForApproval;

 driver.suspended=false;
 driver.online=false;
 driver.approved=restoreApproved;
 driver.status=restoreApproved
   ?'APPROVED'
   :summary.areaApproved
     ?'AREA_APPROVED'
     :summary.promoterApproved
       ?'PROMOTER_APPROVED'
       :summary.allDocumentsUploaded
         ?'DOCUMENTS_COMPLETE'
         :'DRAFT';
 driver.suspension={
   ...(driver.suspension||{}),
   active:false,
   liftedAt:changedAt,
   liftedBy:actorId,
   liftReason:String(reason||'').trim()||null,
 };
 driver.updatedAt=changedAt;
 return structuredClone(driver);
}

export function reviewDriver(driverId,{status,remarks}){
  const allowed=new Set([
    'PENDING',
    'APPROVED',
    'REJECTED',
    'SUSPENDED',
  ]);
  if(!allowed.has(status))throw new Error('Invalid driver review status');
  const d=getDriverProfile(driverId);
  if(!d)return null;

  if(status==='APPROVED'){
    const verification=getDriverVerificationSummary(driverId);
    if(!verification.readyForApproval){
      const incomplete=verification.required
        .filter(item=>item.status!=='APPROVED')
        .map(item=>`${item.type}:${item.status}`)
        .join(', ');
      throw new Error(
        `All mandatory documents must be approved first: ${incomplete}`,
      );
    }
  }

  d.status=status;
  d.approved=status==='APPROVED';
  d.suspended=status==='SUSPENDED';
  if(status!=='APPROVED')d.online=false;
  d.reviewRemarks=remarks||null;
  d.reviewedAt=new Date().toISOString();
  d.updatedAt=d.reviewedAt;
  return structuredClone(d);
}
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
