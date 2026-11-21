// The server's own cap on calls to a source was reached, so the source was not called at all.
class BudgetExceededError extends Error {
    constructor(budget, reason) {
        super(`${budget}: ${reason}`);
        this.name = 'BudgetExceededError';
    }
}

module.exports = BudgetExceededError;
