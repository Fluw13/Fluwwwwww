class TtlCache {
    constructor({ ttlMs, maxEntries, now = Date.now }) {
        this.ttlMs = ttlMs;
        this.maxEntries = maxEntries;
        this.now = now;
        this.entries = new Map();
    }

    get(key) {
        const entry = this.entries.get(key);

        if (entry === undefined) {
            return undefined;
        }

        if (entry.expiresAt <= this.now()) {
            this.entries.delete(key);
            return undefined;
        }

        this.entries.delete(key);
        this.entries.set(key, entry);
        return entry.value;
    }

    set(key, value) {
        this.entries.delete(key);
        this.entries.set(key, { value, expiresAt: this.now() + this.ttlMs });

        while (this.entries.size > this.maxEntries) {
            const oldestKey = this.entries.keys().next().value;
            this.entries.delete(oldestKey);
        }
    }

    clear() {
        this.entries.clear();
    }

    get size() {
        return this.entries.size;
    }
}

module.exports = TtlCache;
