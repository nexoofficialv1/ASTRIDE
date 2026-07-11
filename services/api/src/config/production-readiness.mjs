import { getAdminRuntimeConfig } from './runtime-config.mjs';
import { listCredentialStatus } from './provider-vault.mjs';

const weak = (value) => !value || /CHANGE_ME|example\.com|password|secret/i.test(String(value));

export function productionReadiness(env = process.env) {
  const cfg = getAdminRuntimeConfig();
  const checks = [];
  const add = (name, ok, detail, critical = true) => checks.push({ name, ok: Boolean(ok), detail, critical });
  const production = env.NODE_ENV === 'production';

  add('node_environment', production, production ? 'production' : `current=${env.NODE_ENV || 'development'}`, false);
  add('database_url', !weak(env.DATABASE_URL), 'DATABASE_URL must point to PostgreSQL');
  add('redis_url', !weak(env.REDIS_URL), 'REDIS_URL is required for presence and WebSocket scaling');
  add('admin_password', !weak(env.ADMIN_PASSWORD) && String(env.ADMIN_PASSWORD || '').length >= 12, 'ADMIN_PASSWORD must be a unique 12+ character value');
  add('ops_password', !weak(env.OPS_PASSWORD) && String(env.OPS_PASSWORD || '').length >= 12, 'OPS_PASSWORD must be a unique 12+ character value');
  add('finance_password', !weak(env.FINANCE_PASSWORD) && String(env.FINANCE_PASSWORD || '').length >= 12, 'FINANCE_PASSWORD must be a unique 12+ character value');
  add('admin_password_pepper', !weak(env.ADMIN_PASSWORD_PEPPER) && String(env.ADMIN_PASSWORD_PEPPER || '').length >= 32, 'ADMIN_PASSWORD_PEPPER must be 32+ characters');
  add('provider_credential_key', !weak((env.PROVIDER_CREDENTIALS_MASTER_KEY || env.PROVIDER_CREDENTIAL_KEY)) && String(env.PROVIDER_CREDENTIALS_MASTER_KEY || env.PROVIDER_CREDENTIAL_KEY || '').length >= 32, 'PROVIDER_CREDENTIALS_MASTER_KEY must be 32+ characters');
  add('https_api_domain', Boolean(env.API_DOMAIN) && !weak(env.API_DOMAIN), 'A real API domain is required');
  add('https_admin_domain', Boolean(env.ADMIN_DOMAIN) && !weak(env.ADMIN_DOMAIN), 'A real admin domain is required');

  for (const [type, provider] of Object.entries(cfg.providers)) {
    const live = provider.mode === 'live';
    add(`${type}_live_mode`, live, `${provider.active} is in ${provider.mode} mode`, false);
  }

  const credentials = listCredentialStatus();
  for (const type of ['otp', 'payments', 'notifications', 'maps']) {
    const p = cfg.providers[type];
    if (p.mode !== 'live') continue;
    const available = credentials.some((c) => c.type === type && c.name === p.active && c.mode === 'live' && c.configured);
    add(`${type}_credentials`, available, `${p.active} live credentials ${available ? 'configured' : 'missing'}`, false);
  }

  const failedCritical = checks.filter((c) => c.critical && !c.ok);
  const providerChecks = checks.filter((c)=>/_live_mode$|_credentials$/.test(c.name));
  const serviceReady = failedCritical.length === 0 && providerChecks.every((c)=>c.ok || c.name.startsWith('maps_'));
  return { ready: failedCritical.length === 0, bootstrapReady: failedCritical.length === 0, serviceReady, production, checkedAt: new Date().toISOString(), failedCritical: failedCritical.map((c) => c.name), checks };
}

export function assertProductionReady(env = process.env) {
  const result = productionReadiness(env);
  if (env.NODE_ENV === 'production' && env.STRICT_PRODUCTION_STARTUP !== 'false' && !result.ready) {
    throw new Error(`Production readiness failed: ${result.failedCritical.join(', ')}`);
  }
  return result;
}
