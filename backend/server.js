require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const { createApp } = require('./src/app');

const PORT = process.env.PORT || 5000;
const server = createApp().listen(PORT, () => {
    console.log('Server is running on port ' + server.address().port);
});
