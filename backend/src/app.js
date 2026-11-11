const express = require('express');
const notFound = require('./middlewares/notFound');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

app.disable('x-powered-by');

app.get('/health', (request, response) => {
    response.json({ status: 'ok' });
});

app.use(notFound);
app.use(errorHandler);

module.exports = app;
