import crypto from 'node:crypto';

const accounts = new Map();
const byIdentity = new Map();
const sessions = new Map();
const resetChallenges = new Map();

const now = () => new Date().toISOString();
const clone = (x) => structuredClone(x);
const normalizeIdentity = (value) => String(value || '').trim().toLowerCase();
const id = (prefix) => `${prefix}_${crypto.randomUUID().slice(0, 12)}`;
const SESSION_TTL_MS = Number(process.env.STAFF_SESSION_TTL_MS || 24 * 3600_000);
const RESET_TTL_MS = Number(process.env.STAFF_RESET_TTL_MS || 5 * 60_000);
const MAX_FAILED_LOGINS = Number(process.env.STAFF_MAX_FAILED_LOGINS || 5);
const LOCK_MS = Number(process.env.STAFF_LOCK_MS || 15 * 60_000);

const hashPassword = (
  value,
  salt = crypto.randomBytes(16).toString('hex'),
) => ({
  salt,
  hash: crypto.scryptSync(String(value), salt, 64).toString('hex'),
});

const verifyPassword = (value, record) => {
  if (!record?.salt || !record?.hash) return false;
  const candidate = crypto.scryptSync(String(value), record.salt, 64);
  const expected = Buffer.from(record.hash, 'hex');
  return candidate.length === expected.length &&
    crypto.timingSafeEqual(candidate, expected);
};

const sanitize = (account) => {
  if (!account) return null;
  const x = clone(account);
  delete x.credential;
  return x;
};

function bindIdentity(account) {
  for (const value of [account.mobile, account.loginId]) {
    const key = normalizeIdentity(value);
    if (key) byIdentity.set(key, account.id);
  }
}

export function createStaffAccount(input) {
  const mobile = String(input.mobile || '').replace(/\D/g, '');
  const loginId = String(input.loginId || '').trim();
  if (!mobile && !loginId) throw new Error('mobile_or_login_id_required');
  if (!input.password || String(input.password).length < 8) {
    throw new Error('temporary_password_min_8_characters');
  }
  const identities = [mobile, loginId]
    .map(normalizeIdentity)
    .filter(Boolean);
  for (const identity of identities) {
    if (byIdentity.has(identity)) throw new Error('staff_identity_exists');
  }

  const account = {
    id: input.id || id('staff'),
    role: String(input.role || '').toUpperCase(),
    mobile,
    loginId: loginId || null,
    name: String(input.name || '').trim(),
    status: input.status || 'ACTIVE',
    linkedEntityId: input.linkedEntityId || null,
    areaId: input.areaId || null,
    createdBy: input.createdBy || null,
    mustChangePassword: input.mustChangePassword !== false,
    failedLoginCount: 0,
    lockedUntil: null,
    lastLoginAt: null,
    passwordChangedAt: null,
    credential: hashPassword(input.password),
    createdAt: now(),
    updatedAt: now(),
  };

  accounts.set(account.id, account);
  bindIdentity(account);
  return sanitize(account);
}

export function updateStaffAccount(accountId, patch) {
  const account = accounts.get(accountId);
  if (!account) return null;
  Object.assign(account, {
    ...patch,
    id: account.id,
    updatedAt: now(),
  });
  bindIdentity(account);
  return sanitize(account);
}

export function findStaffByIdentity(identity) {
  const accountId = byIdentity.get(normalizeIdentity(identity));
  return accountId ? sanitize(accounts.get(accountId)) : null;
}

export function getStaffAccount(accountId) {
  return sanitize(accounts.get(accountId));
}

export function listStaffAccounts() {
  return [...accounts.values()].map(sanitize);
}

export function staffLogin({ identity, password, expectedRole }) {
  const accountId = byIdentity.get(normalizeIdentity(identity));
  const account = accounts.get(accountId);
  if (!account || account.status !== 'ACTIVE') return null;
  if (expectedRole) {
    const expected = String(expectedRole).toUpperCase();
    const allowed = expected === 'PARTNER'
      ? ['PROMOTER', 'AREA_PROMOTER'].includes(account.role)
      : account.role === expected;
    if (!allowed) return null;
  }

  if (account.lockedUntil && new Date(account.lockedUntil) > new Date()) {
    return {
      error: 'account_temporarily_locked',
      lockedUntil: account.lockedUntil,
    };
  }

  if (!verifyPassword(password, account.credential)) {
    account.failedLoginCount += 1;
    if (account.failedLoginCount >= MAX_FAILED_LOGINS) {
      account.lockedUntil = new Date(Date.now() + LOCK_MS).toISOString();
      account.failedLoginCount = 0;
    }
    account.updatedAt = now();
    return null;
  }

  account.failedLoginCount = 0;
  account.lockedUntil = null;
  account.lastLoginAt = now();
  account.updatedAt = now();

  const token = crypto.randomBytes(32).toString('base64url');
  sessions.set(token, {
    accountId: account.id,
    expiresAt: Date.now() + SESSION_TTL_MS,
  });

  return {
    accessToken: token,
    expiresInSeconds: Math.floor(SESSION_TTL_MS / 1000),
    mustChangePassword: account.mustChangePassword,
    staff: sanitize(account),
  };
}

export function authenticateStaffToken(tokenOrHeader) {
  const token = String(tokenOrHeader || '').replace(/^Bearer\s+/i, '');
  const session = sessions.get(token);
  if (!session || session.expiresAt <= Date.now()) {
    if (token) sessions.delete(token);
    return null;
  }
  const account = accounts.get(session.accountId);
  return account && account.status === 'ACTIVE'
    ? sanitize(account)
    : null;
}

export function revokeStaffSession(tokenOrHeader) {
  const token = String(tokenOrHeader || '').replace(/^Bearer\s+/i, '');
  return sessions.delete(token);
}

export function changeStaffPassword(
  accountId,
  currentPassword,
  newPassword,
  preserveToken = null,
) {
  const account = accounts.get(accountId);
  if (!account) throw new Error('staff_account_not_found');
  if (!verifyPassword(currentPassword, account.credential)) {
    throw new Error('current_password_invalid');
  }
  if (String(newPassword || '').length < 8) {
    throw new Error('new_password_min_8_characters');
  }

  account.credential = hashPassword(newPassword);
  account.mustChangePassword = false;
  account.passwordChangedAt = now();
  account.updatedAt = now();

  const keep = String(preserveToken || '').replace(/^Bearer\s+/i, '');
  for (const [token, session] of sessions.entries()) {
    if (session.accountId === account.id && token !== keep) {
      sessions.delete(token);
    }
  }

  return sanitize(account);
}

export function adminResetStaffPassword(accountId, temporaryPassword) {
  const account = accounts.get(accountId);
  if (!account) return null;
  if (String(temporaryPassword || '').length < 8) {
    throw new Error('temporary_password_min_8_characters');
  }
  account.credential = hashPassword(temporaryPassword);
  account.mustChangePassword = true;
  account.passwordChangedAt = null;
  account.updatedAt = now();
  for (const [token, session] of sessions.entries()) {
    if (session.accountId === account.id) sessions.delete(token);
  }
  return sanitize(account);
}

export function createPasswordReset(identity) {
  const accountId = byIdentity.get(normalizeIdentity(identity));
  const account = accounts.get(accountId);
  if (!account || account.status !== 'ACTIVE') return null;
  const challengeId = id('reset');
  const code = String(crypto.randomInt(100000, 1000000));
  const codeHash = crypto
    .createHash('sha256')
    .update(`${challengeId}:${code}`)
    .digest('hex');
  resetChallenges.set(challengeId, {
    accountId: account.id,
    codeHash,
    expiresAt: Date.now() + RESET_TTL_MS,
    attempts: 0,
  });
  return {
    challengeId,
    code,
    mobile: account.mobile,
    expiresInSeconds: Math.floor(RESET_TTL_MS / 1000),
  };
}

export function verifyPasswordReset(
  challengeId,
  code,
  newPassword,
) {
  const challenge = resetChallenges.get(challengeId);
  if (!challenge || challenge.expiresAt <= Date.now()) return null;
  if (challenge.attempts >= 5) return null;
  challenge.attempts += 1;

  const candidate = crypto
    .createHash('sha256')
    .update(`${challengeId}:${String(code)}`)
    .digest('hex');
  if (candidate !== challenge.codeHash) return null;
  if (String(newPassword || '').length < 8) {
    throw new Error('new_password_min_8_characters');
  }

  const account = accounts.get(challenge.accountId);
  if (!account) return null;
  account.credential = hashPassword(newPassword);
  account.mustChangePassword = false;
  account.passwordChangedAt = now();
  account.updatedAt = now();
  resetChallenges.delete(challengeId);
  for (const [token, session] of sessions.entries()) {
    if (session.accountId === account.id) sessions.delete(token);
  }
  return sanitize(account);
}

export function exportStaffAuthState() {
  return {
    accounts: [...accounts.entries()],
    byIdentity: [...byIdentity.entries()],
  };
}

export function restoreStaffAuthState(state = {}) {
  accounts.clear();
  byIdentity.clear();
  for (const [key, value] of state.accounts || []) accounts.set(key, value);
  for (const [key, value] of state.byIdentity || []) byIdentity.set(key, value);
}
