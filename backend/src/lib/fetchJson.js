const UpstreamError = require('../errors/upstreamError');

/**
 * GET or POST JSON from a data source with a timeout. Any network error, timeout, non-2xx status (except those
 * listed in acceptStatuses) or non-JSON body becomes an UpstreamError, so callers handle one failure type.
 */
const createFetchJson = ({ fetch = globalThis.fetch, timeoutMs, userAgent }) => {
    return async (source, url, { method = 'GET', body, headers = {}, acceptStatuses = [], timeoutMs: requestTimeoutMs } = {}) => {
        let response;
        try {
            response = await fetch(url, {
                method,
                body,
                headers: { Accept: 'application/json', 'User-Agent': userAgent, ...headers },
                signal: AbortSignal.timeout(requestTimeoutMs ?? timeoutMs),
            });
        } catch (error) {
            throw new UpstreamError(source, error.name);
        }
        if (!response.ok && !acceptStatuses.includes(response.status)) {
            // An unread body keeps the connection busy until garbage collection.
            await response.body?.cancel().catch(() => {});
            throw new UpstreamError(source, `HTTP ${response.status}`, response.status);
        }
        try {
            return { status: response.status, body: await response.json() };
        } catch {
            throw new UpstreamError(source, 'invalid JSON');
        }
    };
};

module.exports = createFetchJson;
