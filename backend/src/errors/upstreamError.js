// A data source (Open Food Facts, USDA, Gemini) failed or timed out. Its details stay in the server log.
// `upstreamStatus` is the source's HTTP status when it answered with an error, so a 429 can pause further calls.
class UpstreamError extends Error {
    constructor(source, detail, upstreamStatus = null) {
        super(`${source}: ${detail}`);
        this.name = 'UpstreamError';
        this.source = source;
        this.upstreamStatus = upstreamStatus;
    }
}

module.exports = UpstreamError;
