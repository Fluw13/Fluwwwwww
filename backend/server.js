const createApp = require('./src/app');
const loadConfig = require('./src/config');
const createServices = require('./src/createServices');

const app = createApp(createServices(loadConfig()));

const PORT = process.env.PORT || 5000;
// Hosts such as Render send SIGTERM before stopping an instance during deploys; in-flight requests get time to finish.
const SHUTDOWN_GRACE_PERIOD_MS = 25000;

// Express 5 also calls this callback when listen fails; the 'error' handler below reports and exits.
const server = app.listen(PORT, (error) => {
    if (error) {
        return;
    }
    console.log('Server is running on port ' + PORT);
});

server.on('error', (error) => {
    console.error('[Server Error] Không thể khởi động server:', error.code || error.name, error.message);
    process.exit(1);
});

let isShuttingDown = false;

const shutDown = (signal) => {
    if (isShuttingDown) {
        return;
    }
    isShuttingDown = true;
    console.log('[Shutdown] Nhận ' + signal + ', ngừng nhận kết nối mới.');

    const forceExitTimer = setTimeout(() => {
        console.error('[Shutdown] Hết thời gian chờ, buộc dừng tiến trình.');
        process.exit(1);
    }, SHUTDOWN_GRACE_PERIOD_MS);
    forceExitTimer.unref();

    server.close((error) => {
        if (error) {
            console.error('[Shutdown] Lỗi khi đóng server:', error.code || error.message);
            process.exit(1);
        }
        process.exit(0);
    });
};

process.once('SIGTERM', () => shutDown('SIGTERM'));
process.once('SIGINT', () => shutDown('SIGINT'));
