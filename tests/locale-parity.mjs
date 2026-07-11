import assert from 'node:assert/strict';
import fs from 'node:fs';
const load=(name)=>JSON.parse(fs.readFileSync(new URL(`../packages/locales/${name}.json`,import.meta.url),'utf8'));
const flatten=(obj,p='',out={})=>{for(const [k,v] of Object.entries(obj)){const key=p?`${p}.${k}`:k;if(v&&typeof v==='object'&&!Array.isArray(v))flatten(v,key,out);else out[key]=v;}return out;};
const locales={en:flatten(load('en')),bn:flatten(load('bn')),hi:flatten(load('hi'))};
const base=Object.keys(locales.en).sort();
for(const [lang,data] of Object.entries(locales)){assert.deepEqual(Object.keys(data).sort(),base,`${lang} locale keys differ`);for(const [key,value] of Object.entries(data)){assert.equal(typeof value,'string',`${lang}:${key} must be string`);assert.ok(value.trim().length>0,`${lang}:${key} empty`);}}
console.log(`locale parity passed: ${base.length} keys across en/bn/hi`);
