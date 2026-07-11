import fs from 'node:fs';
import path from 'node:path';
const allowedProviders = {
  maps: ['mappls', 'google', 'osm'],
  payments: ['razorpay', 'bharatpe', 'cash'],
  otp: ['mock', 'msg91', 'twilio'],
  notifications: ['firebase', 'onesignal', 'mock'],
};
const config = {
  version: 11,
  localeContentVersion: 1,
  maintenanceMode: false,
  minimumAppVersions: { passenger: '3.0.0', driver: '3.0.0', promoter: '3.0.0' },
  operations: { serviceEnabled: false, newBookingsEnabled: false, driverOnlineEnabled: false, emergencyMode: false },
  features: { cashPayment: true, onlinePayment: true, scheduledRide: false, sharedRide: false, sos: true, driverMatching: true, liveTracking: true, savedPlaces: true, ratings: true, complaints: true, tripSharing: true, routeDeviationAlerts: true, fraudDetection: true },
  businessRules: {
    currency: 'INR', maximumTotoDistanceKm: 29,
    rideTypes: {
      FULL_TOTO: { minimumFare: 50, includedKm: 4, additionalStepKm: 2, additionalStepFare: 20, companyCommissionPercent: 10, companyCommissionMaximum: 5, promoterShareOfCompanyCommissionPercent: 30, areaPromoterShareOfCompanyCommissionPercent: 15, nightSurchargePercent: 15 },
      SHARE_TOTO: { minimumFare: 10, includedKm: 4, additionalStepKm: 2, additionalStepFare: 5, companyCommissionPercent: 10, companyCommissionMaximum: 2, promoterShareOfCompanyCommissionPercent: 25, areaPromoterShareOfCompanyCommissionPercent: 10, nightSurchargePercent: 0 },
      MOTORCYCLE: { minimumFare: 25, includedKm: 4, additionalStepKm: 2, additionalStepFare: 10, companyCommissionPercent: 12, companyCommissionMaximum: 4, promoterShareOfCompanyCommissionPercent: 25, areaPromoterShareOfCompanyCommissionPercent: 10, nightSurchargePercent: 10 }
    },
    outsideArea: { enabled: true, fullTotoOnly: true, stepKm: 2, stepFare: 25, returnCompensationPercent: 50 },
    waiting: { freeMinutes: 3, perMinute: 2, maxCharge: 20 },
    dynamicPricing: { enabled: true, maxMultiplier: 1.25, zones: ['RAILWAY_STATION','BUS_STAND'], peakWindows: [{ start: '07:30', end: '10:30' }, { start: '16:30', end: '20:30' }] },
    nightService: { enabled: true, start: '22:00', end: '05:00', shareTotoAllowed: false, motorcycleRequiresAvailability: true },
    paymentPreferences: { enabled: ['CASH','UPI','BOTH'] },
    saferide: { enabled: true, alwaysVisible: true, nightSuggest: true, highRiskZonePrompt: true, trustedDriverPriority: true },
    lateArrival: { enabled: true, graceMinutes: 3, flatPenalty: 0, perMinutePenalty: 2, maxPenalty: 20 },
    promoterSettlement: { cycle: 'MONTHLY', withdrawalOpenDay: 1 }
  },
  booking: { searchRadiusKm: 8, requestTimeoutSeconds: 20, maxDriverAttempts: 5, passengerCancellationWindowSeconds: 120 },
  payments: { enabled: true, currency: 'INR', captureMode: 'automatic', allowPartialRefund: true, settlementMinimumPaise: 100, settlementHoldHours: 0, idempotencyWindowMinutes: 1440, webhookToleranceSeconds: 300, reconciliationEnabled: true, reconciliationIntervalMinutes: 15 },
  tracking: { enabled: true, updateIntervalSeconds: 5, backgroundIntervalSeconds: 15, maxAcceptedAccuracyM: 100, staleAfterSeconds: 30, maxBatchSize: 100, retainPointsPerRide: 10000 },
  safety: { sosEnabled: true, emergencyNumber: '112', routeDeviationThresholdM: 500, suspiciousStopSeconds: 300, maxOtpRequestsPerHour: 5, maxBookingsPerPassengerPerHour: 8, maxFailedPaymentsPerHour: 4, notificationRetryLimit: 3 },
  fare: { currency: 'INR', baseFare: 20, perKm: 12,
    driverCommissionPercent: 15, bookingFee: 0, minimumFare: 30, roundTo: 1, averageSpeedKmph: 18 },
  providers: {
    maps: { active: 'osm', fallback: null, mode: 'test', enabled: true },
    payments: { active: 'razorpay', fallback: 'cash', mode: 'test', enabled: true },
    otp: { active: 'mock', fallback: null, mode: 'test', enabled: true },
    notifications: { active: 'mock', fallback: 'firebase', mode: 'test', enabled: true },
  },
};
const runtimeConfigFile=process.env.RUNTIME_CONFIG_FILE||path.resolve(process.env.ASTRIDE_DATA_DIR||'data','runtime-config.json');
function persistRuntimeConfig(){const dir=path.dirname(runtimeConfigFile);fs.mkdirSync(dir,{recursive:true});const tmp=`${runtimeConfigFile}.tmp`;fs.writeFileSync(tmp,JSON.stringify(config,null,2),{mode:0o600});fs.renameSync(tmp,runtimeConfigFile);}
try{if(fs.existsSync(runtimeConfigFile)){const saved=JSON.parse(fs.readFileSync(runtimeConfigFile,'utf8'));Object.assign(config,saved);}}catch(error){throw new Error(`Runtime configuration could not be loaded: ${error.message}`);}
export function getPublicRuntimeConfig(appType = 'passenger') {
  return { version: config.version, operations: structuredClone(config.operations), localeContentVersion: config.localeContentVersion, maintenanceMode: config.maintenanceMode, minimumAppVersion: config.minimumAppVersions[appType] ?? '0.1.0', features: structuredClone(config.features), booking: structuredClone(config.booking), tracking: structuredClone(config.tracking), safety: structuredClone(config.safety), payments: structuredClone(config.payments), fare: structuredClone(config.fare), businessRules: structuredClone(config.businessRules), capabilities: { mapProvider: config.providers.maps.active, paymentMethods: [...(config.features.cashPayment ? ['cash'] : []), ...(config.features.onlinePayment ? ['online'] : [])] } };
}
export function getAdminRuntimeConfig() { return structuredClone(config); }
const deepMerge=(target,patch)=>{const out=structuredClone(target);for(const [k,v] of Object.entries(patch||{})){out[k]=(v&&typeof v==='object'&&!Array.isArray(v)&&out[k]&&typeof out[k]==='object'&&!Array.isArray(out[k]))?deepMerge(out[k],v):structuredClone(v);}return out;};
export function updateRuntimeConfig(patch) {
  if (!patch || typeof patch !== 'object' || Array.isArray(patch)) throw new Error('Invalid configuration patch');
  if (patch.maintenanceMode !== undefined) config.maintenanceMode = Boolean(patch.maintenanceMode);
  if (patch.localeContentVersion !== undefined) config.localeContentVersion = Number(patch.localeContentVersion);
  if (patch.operations) Object.assign(config.operations, patch.operations);
  if (patch.features) Object.assign(config.features, patch.features);
  if (patch.booking) Object.assign(config.booking, patch.booking);
  if (patch.tracking) Object.assign(config.tracking, patch.tracking);
  if (patch.safety) Object.assign(config.safety, patch.safety);
  if (patch.payments) Object.assign(config.payments, patch.payments);
  if (patch.fare) Object.assign(config.fare, patch.fare);
  if (patch.businessRules) config.businessRules = deepMerge(config.businessRules, patch.businessRules);
  if (patch.minimumAppVersions) Object.assign(config.minimumAppVersions, patch.minimumAppVersions);
  if (patch.providers) for (const [service, value] of Object.entries(patch.providers)) { if (!config.providers[service]) throw new Error(`Unknown provider service: ${service}`); if (value.active && !allowedProviders[service].includes(value.active)) throw new Error(`Unsupported ${service} provider: ${value.active}`); if (value.fallback && !allowedProviders[service].includes(value.fallback)) throw new Error(`Unsupported ${service} fallback: ${value.fallback}`); Object.assign(config.providers[service], value); }
  if (config.providers.maps.active === config.providers.maps.fallback) throw new Error('Primary and fallback map providers must differ');
  config.version += 1; persistRuntimeConfig(); return getAdminRuntimeConfig();
}
