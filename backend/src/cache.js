function createTtlCache({ ttlMs, maxEntries, now = Date.now }) {
    const entries = new Map();

    function get(key) {
        const entry = entries.get(key);
        if (!entry) {
            return undefined;
        }
        if (now() >= entry.expiresAt) {
            entries.delete(key);
            return undefined;
        }
        return entry.value;
    }

    // Map keeps insertion order, so the first key is always the oldest entry.
    function set(key, value) {
        entries.delete(key);
        while (entries.size >= maxEntries) {
            entries.delete(entries.keys().next().value);
        }
        entries.set(key, { value, expiresAt: now() + ttlMs });
    }

    return {
        get,
        set,
        get size() {
            return entries.size;
        }
    };
}

module.exports = { createTtlCache };
