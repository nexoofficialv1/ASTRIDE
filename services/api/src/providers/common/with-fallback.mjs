export async function withFallback({ primary, fallback, operation, service }) {
  try {
    return { provider: primary.code, fallbackUsed: false, result: await operation(primary.adapter) };
  } catch (primaryError) {
    if (!fallback) throw primaryError;
    try {
      return { provider: fallback.code, fallbackUsed: true, result: await operation(fallback.adapter) };
    } catch (fallbackError) {
      throw new Error(`${service} failed on primary and fallback: ${primaryError.message}; ${fallbackError.message}`);
    }
  }
}
