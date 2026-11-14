// A data source (Open Food Facts, USDA) failed or timed out. Its details stay in the server log.
class UpstreamError extends Error {
    constructor(source, detail) {
        super(`${source}: ${detail}`);
        this.name = 'UpstreamError';
        this.source = source;
    }
}

module.exports = UpstreamError;
