// Every answer is JSON; this stops a browser from guessing another type for it.
const noSniff = (request, response, next) => {
    response.set('X-Content-Type-Options', 'nosniff');
    next();
};

module.exports = noSniff;
