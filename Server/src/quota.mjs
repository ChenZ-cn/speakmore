export const DEFAULT_TRIAL_LIMITS = Object.freeze({
  outputChars: 2000,
  speechSeconds: 600
});

export function createMemoryQuotaStore(initialRecords = {}) {
  return {
    records: new Map(Object.entries(initialRecords))
  };
}

export function getQuotaStatus(store, deviceId, limits = DEFAULT_TRIAL_LIMITS) {
  const id = requireDeviceId(deviceId);
  const usage = getUsage(store, id);
  const remaining = {
    outputChars: Math.max(0, limits.outputChars - usage.outputChars),
    speechSeconds: Math.max(0, limits.speechSeconds - usage.speechSeconds)
  };

  return {
    deviceId: id,
    limits: { ...limits },
    usage,
    remaining,
    exhausted: remaining.outputChars <= 0 || remaining.speechSeconds <= 0
  };
}

export function consumeQuota(store, deviceId, usageDelta, limits = DEFAULT_TRIAL_LIMITS) {
  const id = requireDeviceId(deviceId);
  const currentStatus = getQuotaStatus(store, id, limits);
  const outputChars = normalizePositiveInteger(usageDelta?.outputChars);
  const speechSeconds = normalizePositiveInteger(usageDelta?.speechSeconds);

  if (
    outputChars > currentStatus.remaining.outputChars ||
    speechSeconds > currentStatus.remaining.speechSeconds
  ) {
    throw new Error("trial quota exceeded");
  }

  const nextUsage = {
    outputChars: currentStatus.usage.outputChars + outputChars,
    speechSeconds: currentStatus.usage.speechSeconds + speechSeconds
  };
  setUsage(store, id, nextUsage);
  return getQuotaStatus(store, id, limits);
}

export function canConsumeQuota(store, deviceId, usageDelta, limits = DEFAULT_TRIAL_LIMITS) {
  try {
    consumeQuota(createSnapshotStore(store), deviceId, usageDelta, limits);
    return true;
  } catch {
    return false;
  }
}

function getUsage(store, deviceId) {
  const record = store.records.get(deviceId);
  return {
    outputChars: normalizePositiveInteger(record?.outputChars),
    speechSeconds: normalizePositiveInteger(record?.speechSeconds)
  };
}

function setUsage(store, deviceId, usage) {
  store.records.set(deviceId, {
    outputChars: normalizePositiveInteger(usage.outputChars),
    speechSeconds: normalizePositiveInteger(usage.speechSeconds)
  });
}

function createSnapshotStore(store) {
  return createMemoryQuotaStore(Object.fromEntries(store.records.entries()));
}

function requireDeviceId(deviceId) {
  const value = `${deviceId ?? ""}`.trim();
  if (!value) {
    throw new Error("device_id is required");
  }
  return value;
}

function normalizePositiveInteger(value) {
  const number = Number(value ?? 0);
  if (!Number.isFinite(number) || number <= 0) {
    return 0;
  }
  return Math.ceil(number);
}
