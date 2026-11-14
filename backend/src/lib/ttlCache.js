/**
 * Small in-memory cache with expiry and a size cap (oldest entry evicted first). It resets on every deploy or
 * restart, which is fine: it only spares the data sources repeated lookups.
 */
const createTtlCache = ({ maxEntries, now = Date.now }) => {
    const entries = new Map();

    const get = (key) => {
        const entry = entries.get(key);
        if (!entry) {
            return undefined;
        }
        if (entry.expiresAt <= now()) {
            entries.delete(key);
            return undefined;
        }
        return entry.value;
    };

    const set = (key, value, ttlMs) => {
        entries.delete(key);
        entries.set(key, { value, expiresAt: now() + ttlMs });
        if (entries.size > maxEntries) {
            entries.delete(entries.keys().next().value);
        }
    };

    return { get, set };
};

module.exports = createTtlCache;
