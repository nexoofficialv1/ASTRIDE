let pool=null;
export const databaseMode=()=>process.env.DATABASE_URL?'postgres':'memory';
export async function getPool(){
  if(!process.env.DATABASE_URL) return null;
  if(pool) return pool;
  let pg; try{pg=await import('pg');}catch{throw new Error('PostgreSQL mode requires npm package "pg". Run npm install.');}
  pool=new pg.Pool({connectionString:process.env.DATABASE_URL,ssl:process.env.PGSSL==='require'?{rejectUnauthorized:false}:undefined,max:Number(process.env.PGPOOL_MAX||20),idleTimeoutMillis:30000,connectionTimeoutMillis:10000});
  pool.on('error',e=>console.error('postgres_pool_error',e.message));
  return pool;
}
export async function databaseHealth(){
  if(databaseMode()==='memory') return {mode:'memory',connected:true,productionReady:false};
  try{const p=await getPool();const r=await p.query('select now() as now, current_database() as database');return {mode:'postgres',connected:true,productionReady:true,database:r.rows[0].database,serverTime:r.rows[0].now};}
  catch(e){return {mode:'postgres',connected:false,productionReady:false,error:e.message};}
}
export async function closePool(){if(pool){await pool.end();pool=null;}}
