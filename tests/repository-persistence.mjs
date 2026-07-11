import assert from 'node:assert/strict';
import {saveState,loadState,repositoryStatus} from '../services/api/src/db/state-repository.mjs';
const payload={items:[{id:'one',status:'ACTIVE'}],nested:{language:'bn'}};
const saved=await saveState('test_contract',payload);
assert.equal(saved.mode,'memory');
assert.deepEqual(await loadState('test_contract'),payload);
const status=await repositoryStatus();
assert(status.namespaces.includes('test_contract'));
console.log('v1.2 repository persistence contract passed');
