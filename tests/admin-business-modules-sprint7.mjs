import assert from 'node:assert/strict';
import fs from 'node:fs';
import { getAdminRuntimeConfig, updateRuntimeConfig } from '../services/api/src/config/runtime-config.mjs';
const app=fs.readFileSync(new URL('../apps/admin_control_console/app.js',import.meta.url),'utf8');
const css=fs.readFileSync(new URL('../apps/admin_control_console/style.css',import.meta.url),'utf8');
for(const token of ['fareManagement','dynamicPricing','nightService','zoneManager','promoterManagement','compensation','saferideAdmin','partnerSettlements']) assert.ok(app.includes(token),`missing ${token}`);
for(const endpoint of ['/v1/admin/config','/v1/admin/promoters','/v1/late-arrival/evaluate','/v1/admin/promoter-earnings/release']) assert.ok(app.includes(endpoint),`missing endpoint ${endpoint}`);
assert.ok(css.includes('.fare-grid')&&css.includes('.map-placeholder')&&css.includes('.notice.night'));
const before=getAdminRuntimeConfig();
const updated=updateRuntimeConfig({businessRules:{dynamicPricing:{enabled:true,maxMultiplier:1.2},nightService:{start:'21:30',end:'05:30'},saferide:{nightSuggest:true},lateArrival:{graceMinutes:4}}});
assert.equal(updated.businessRules.dynamicPricing.maxMultiplier,1.2);
assert.equal(updated.businessRules.nightService.start,'21:30');
assert.equal(updated.businessRules.saferide.nightSuggest,true);
assert.equal(updated.businessRules.lateArrival.graceMinutes,4);
// restore changed values for deterministic subsequent tests
updateRuntimeConfig({businessRules:{dynamicPricing:before.businessRules.dynamicPricing,nightService:before.businessRules.nightService,saferide:before.businessRules.saferide,lateArrival:before.businessRules.lateArrival}});
console.log('Sprint 7 admin business modules contract passed');
