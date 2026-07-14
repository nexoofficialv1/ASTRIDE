import { databaseMode } from './postgres.mjs';
import { loadState,saveState,repositoryStatus } from './state-repository.mjs';
import { exportMemoryStoreState,restoreMemoryStoreState } from '../store/memory-store.mjs';
import { exportPassengerStoreState,restorePassengerStoreState } from '../store/passenger-store.mjs';
import { exportDriverStoreState,restoreDriverStoreState } from '../store/driver-store.mjs';
import { exportPaymentStoreState,restorePaymentStoreState } from '../store/payment-store.mjs';
import { exportSafetyStoreState,restoreSafetyStoreState } from '../store/safety-store.mjs';
import { exportTrackingStoreState,restoreTrackingStoreState } from '../store/tracking-store.mjs';
import { exportSharePoolingState,restoreSharePoolingState } from '../store/share-pooling-store.mjs';
import { exportCampaignStoreState,restoreCampaignStoreState } from '../store/campaign-store.mjs';
import { exportPromoterStoreState,restorePromoterStoreState } from '../store/promoter-store.mjs';
import { exportStaffAuthState,restoreStaffAuthState } from '../store/staff-auth-store.mjs';
import { exportDeviceStoreState,restoreDeviceStoreState } from '../store/device-store.mjs';

const modules={
  operations:{exportState:exportMemoryStoreState,restoreState:restoreMemoryStoreState},
  passengers:{exportState:exportPassengerStoreState,restoreState:restorePassengerStoreState},
  drivers:{exportState:exportDriverStoreState,restoreState:restoreDriverStoreState},
  payments:{exportState:exportPaymentStoreState,restoreState:restorePaymentStoreState},
  safety:{exportState:exportSafetyStoreState,restoreState:restoreSafetyStoreState},
  tracking:{exportState:exportTrackingStoreState,restoreState:restoreTrackingStoreState},
  sharePooling:{exportState:exportSharePoolingState,restoreState:restoreSharePoolingState},
  campaigns:{exportState:exportCampaignStoreState,restoreState:restoreCampaignStoreState},
  promoters:{exportState:exportPromoterStoreState,restoreState:restorePromoterStoreState},
  staffAuth:{exportState:exportStaffAuthState,restoreState:restoreStaffAuthState},
  devices:{exportState:exportDeviceStoreState,restoreState:restoreDeviceStoreState},
};
let initialized=false,dirty=false,flushTimer=null,lastFlushAt=null,lastError=null,writeInFlight=null;

export async function initializePersistence(){
  if(initialized)return persistenceStatus();
  if(databaseMode()==='postgres'){
    for(const [namespace,module] of Object.entries(modules)){
      const state=await loadState(namespace);
      if(state)module.restoreState(state);
    }
  }
  initialized=true;
  return persistenceStatus();
}
export function schedulePersistenceFlush(){
  if(databaseMode()!=='postgres')return;
  dirty=true;
  clearTimeout(flushTimer);
  flushTimer=setTimeout(()=>{void flushPersistence();},Number(process.env.PERSISTENCE_FLUSH_MS||150));
}
export async function flushPersistence(){
  if(databaseMode()!=='postgres'||!dirty)return persistenceStatus();
  if(writeInFlight)return writeInFlight;
  writeInFlight=(async()=>{try{for(const [namespace,module] of Object.entries(modules))await saveState(namespace,module.exportState());dirty=false;lastFlushAt=new Date().toISOString();lastError=null;}catch(error){lastError=error.message;throw error;}finally{writeInFlight=null;}return persistenceStatus();})();
  return writeInFlight;
}
export async function persistenceStatus(){return {initialized,mode:databaseMode(),dirty,lastFlushAt,lastError,repository:await repositoryStatus()};}
