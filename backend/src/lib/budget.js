const BudgetExceededError = require('../errors/budgetExceededError');

const COOLDOWN_MS = 60 * 1000;

/**
 * A server-wide cap on calls to one source, shared by every user: Open Food Facts and USDA limit Render's single IP,
 * and Gemini's free quota belongs to one project. Each limit counts the calls started in the last `windowMs` (a sliding
 * window, so there is no double burst at a window edge). After the source answers 429 it is left alone for
 * `cooldownMs`. A call over the cap fails at once with BudgetExceededError and never reaches the source.
 */
const createBudget = ({ name, limits = [], maxConcurrent = Infinity, cooldownMs = COOLDOWN_MS, now = Date.now }) => {
    const windows = limits.map(({ max, windowMs }) => ({ max, windowMs, starts: [] }));
    let running = 0;
    let pausedUntil = -Infinity;

    const refusal = (time) => {
        if (time < pausedUntil) {
            return 'paused after HTTP 429';
        }
        if (running >= maxConcurrent) {
            return `${maxConcurrent} calls already running`;
        }
        for (const window of windows) {
            while (window.starts.length > 0 && window.starts[0] <= time - window.windowMs) {
                window.starts.shift();
            }
            if (window.starts.length >= window.max) {
                return `${window.max} calls per ${window.windowMs / 1000} s`;
            }
        }
        return null;
    };

    /** Runs `task`, one call to the source, if the budget allows it. */
    const run = async (task) => {
        const time = now();
        const reason = refusal(time);
        if (reason !== null) {
            throw new BudgetExceededError(name, reason);
        }
        for (const window of windows) {
            window.starts.push(time);
        }
        running += 1;
        try {
            return await task();
        } catch (error) {
            if (error?.upstreamStatus === 429) {
                pausedUntil = now() + cooldownMs;
            }
            throw error;
        } finally {
            running -= 1;
        }
    };

    return { run };
};

module.exports = createBudget;
