require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const app = require('./src/app');

const PORT = process.env.PORT || 5000;
// Hosts such as Render send SIGTERM before stopping an instance during deploys; in-flight lookups get time to finish.
const SHUTDOWN_GRACE_PERIOD_MS = 25000;

const server = app.listen(PORT, () => {
    console.log('Server is running on port ' + PORT);
});

server.on('error', (error) => {
    console.error('[Server Error] Không thể khởi động server:', error.code || error.name, error.message);
    process.exit(1);
});

const shutDown = (signal) => {
    console.log('[Shutdown] Nhận ' + signal + ', ngừng nhận kết nối mới.');

    const forceExitTimer = setTimeout(() => {
        console.error('[Shutdown] Hết thời gian chờ, buộc dừng tiến trình.');
        process.exit(1);
    }, SHUTDOWN_GRACE_PERIOD_MS);
    forceExitTimer.unref();

    server.close(() => process.exit(0));
    server.closeIdleConnections();
};

process.once('SIGTERM', () => shutDown('SIGTERM'));
process.once('SIGINT', () => shutDown('SIGINT'));
