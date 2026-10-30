const AppError = require('../../errors/AppError');
const { API_ERROR_CODES } = require('../../errors/errorCodes');
const { readPositiveInteger } = require('../../config/env');

const WINDOW_MS = 60 * 1000;
// Open Food Facts allows 15 product reads and 10 searches per minute per IP; Fluw keeps one request of headroom.
const DEFAULT_READS_PER_MINUTE = 14;
const DEFAULT_SEARCHES_PER_MINUTE = 9;

class TokenBucket {
    constructor({ perMinute, now }) {
        this.capacity = perMinute;
        this.now = now;
        this.tokens = perMinute;
        this.updatedAt = now();
    }

    refill() {
        const current = this.now();
        const elapsed = Math.max(0, current - this.updatedAt);
        this.tokens = Math.min(this.capacity, this.tokens + (elapsed * this.capacity) / WINDOW_MS);
        this.updatedAt = current;
    }

    // Returns 0 when a token was taken, otherwise the whole seconds to wait for the next one.
    tryTake() {
        this.refill();

        if (this.tokens >= 1) {
            this.tokens -= 1;
            return 0;
        }

        return Math.max(1, Math.ceil(((1 - this.tokens) * WINDOW_MS) / this.capacity / 1000));
    }
}

const budgetExceededError = (retryAfterSeconds) => new AppError(
    'Fluw đang tạm giới hạn số lượt tra cứu tới Open Food Facts. Vui lòng thử lại sau khoảng ' + retryAfterSeconds + ' giây.',
    503,
    API_ERROR_CODES.UPSTREAM_RATE_LIMITED,
    { retryAfterSeconds }
);

const createUpstreamBudget = ({ readsPerMinute, searchesPerMinute, now = Date.now }) => {
    const buckets = {
        read: new TokenBucket({ perMinute: readsPerMinute, now }),
        search: new TokenBucket({ perMinute: searchesPerMinute, now })
    };

    const take = (kind) => {
        const waitSeconds = buckets[kind].tryTake();

        if (waitSeconds > 0) {
            console.warn('[OpenFoodFacts Budget] exhausted', kind, waitSeconds + 's');
            throw budgetExceededError(waitSeconds);
        }
    };

    return { take };
};

const offBudget = createUpstreamBudget({
    readsPerMinute: readPositiveInteger(process.env.OFF_READS_PER_MINUTE, DEFAULT_READS_PER_MINUTE),
    searchesPerMinute: readPositiveInteger(process.env.OFF_SEARCHES_PER_MINUTE, DEFAULT_SEARCHES_PER_MINUTE)
});

module.exports = { createUpstreamBudget, offBudget };
