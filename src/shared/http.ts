export interface ExpectedStatus {
  codes: number[];
  ranges: [number, number][];
}

const EXACT_RE = /^\d+$/;
const RANGE_RE = /^(\d+)-(\d+)$/;

/**
 * Parse an `expected-status` spec into exact codes and inclusive ranges.
 *
 * Accepts a comma-separated list where each token is either a single status
 * code (e.g. `200`) or an inclusive range (e.g. `300-399`). Family shorthand
 * such as `2xx` is not supported.
 */
export function parseExpectedStatus(spec: string): ExpectedStatus {
  const codes: number[] = [];
  const ranges: [number, number][] = [];

  const tokens = spec
    .split(',')
    .map((token) => token.trim())
    .filter((token) => token.length > 0);

  if (tokens.length === 0) {
    throw new Error(`Invalid expected-status: "${spec}". Must contain at least one status code.`);
  }

  for (const token of tokens) {
    if (EXACT_RE.test(token)) {
      codes.push(parseInt(token, 10));
      continue;
    }

    const rangeMatch = RANGE_RE.exec(token);
    if (rangeMatch) {
      const min = parseInt(rangeMatch[1], 10);
      const max = parseInt(rangeMatch[2], 10);
      if (min > max) {
        throw new Error(`Invalid expected-status range: "${token}". Start must not be greater than end.`);
      }
      ranges.push([min, max]);
      continue;
    }

    throw new Error(`Invalid expected-status token: "${token}". Use single codes (e.g. 200) or ranges (e.g. 300-399).`);
  }

  return { codes, ranges };
}

/** Return true if `status` matches the given `expected-status` spec. */
export function matchesStatus(status: number, spec: string): boolean {
  const { codes, ranges } = parseExpectedStatus(spec);
  if (codes.includes(status)) {
    return true;
  }
  return ranges.some(([min, max]) => status >= min && status <= max);
}

/**
 * Issue an HTTP request and resolve only if the response status matches the
 * given `expected-status` spec. Redirects are not followed so the raw status
 * code is asserted.
 */
export async function checkHttp(
  url: string,
  method: string,
  expectedStatus: string,
  timeoutMs: number = 5000,
): Promise<void> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let response: Response;
  try {
    response = await fetch(url, {
      method,
      redirect: 'manual',
      signal: controller.signal,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`HTTP ${method} ${url} failed: ${message}`);
  } finally {
    clearTimeout(timer);
  }

  if (!matchesStatus(response.status, expectedStatus)) {
    throw new Error(`HTTP ${method} ${url} returned ${response.status}, expected ${expectedStatus}`);
  }
}
