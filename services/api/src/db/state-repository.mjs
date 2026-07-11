import crypto from 'node:crypto';
import { getPool, databaseMode } from './postgres.mjs';

const memory = new Map();
const clone=(x)=>structuredClone(x);
const checksum=(payload)=>crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex');

export async function loadState(namespace){
  if(databaseMode()==='memory') return memory.has(namespace)?clone(memory.get(namespace).payload):null;
  const pool=await getPool();
  const result=await pool.query('SELECT payload,revision,updated_at FROM app_state_snapshots WHERE namespace=$1',[namespace]);
  return result.rowCount?clone(result.rows[0].payload):null;
}

export async function saveState(namespace,payload){
  const sum=checksum(payload);
  if(databaseMode()==='memory'){
    const current=memory.get(namespace); const revision=(current?.revision||0)+1;
    memory.set(namespace,{revision,payload:clone(payload),checksum:sum,updatedAt:new Date().toISOString()});
    return {namespace,revision,checksum:sum,mode:'memory'};
  }
  const pool=await getPool();
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    const result=await client.query(`INSERT INTO app_state_snapshots(namespace,revision,payload,updated_at)
      VALUES($1,1,$2::jsonb,now())
      ON CONFLICT(namespace) DO UPDATE SET revision=app_state_snapshots.revision+1,payload=EXCLUDED.payload,updated_at=now()
      RETURNING revision`,[namespace,JSON.stringify(payload)]);
    const revision=Number(result.rows[0].revision);
    await client.query('INSERT INTO repository_write_log(namespace,revision,checksum) VALUES($1,$2,$3)',[namespace,revision,sum]);
    await client.query('COMMIT');
    return {namespace,revision,checksum:sum,mode:'postgres'};
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
}

export async function repositoryStatus(){
  if(databaseMode()==='memory') return {mode:'memory',namespaces:[...memory.keys()],durable:false};
  const pool=await getPool();
  const result=await pool.query('SELECT namespace,revision,updated_at FROM app_state_snapshots ORDER BY namespace');
  return {mode:'postgres',durable:true,namespaces:result.rows};
}
