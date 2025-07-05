"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const config_1 = __importDefault(require("./config"));
const fileRoutes_1 = __importDefault(require("./routes/fileRoutes"));
const errorHandler_1 = require("./middleware/errorHandler");
const app = (0, express_1.default)();
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: config_1.default.cors.origin,
    credentials: true,
}));
const limiter = (0, express_rate_limit_1.default)({
    windowMs: config_1.default.rateLimit.windowMs,
    max: config_1.default.rateLimit.maxRequests,
    message: {
        success: false,
        error: 'Too many requests from this IP, please try again later.',
    },
});
app.use('/api/', limiter);
if (config_1.default.nodeEnv === 'development') {
    app.use((0, morgan_1.default)('dev'));
}
else {
    app.use((0, morgan_1.default)('combined'));
}
app.use(express_1.default.json({ limit: '50mb' }));
app.use(express_1.default.urlencoded({ extended: true, limit: '50mb' }));
app.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Fairbnb Backend API is running',
        timestamp: new Date().toISOString(),
        environment: config_1.default.nodeEnv,
    });
});
app.use('/api/files', fileRoutes_1.default);
app.get('/api', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Fairbnb Backend API',
        version: '1.0.0',
        endpoints: {
            files: {
                'POST /api/files/upload': 'Upload a single file',
                'POST /api/files/upload-multiple': 'Upload multiple files',
                'GET /api/files/:rootHash': 'Download a file',
                'GET /api/files/:rootHash/info': 'Get file information',
            },
            health: {
                'GET /health': 'Health check',
            },
        },
        documentation: 'https://docs.0g.ai/developer-hub/building-on-0g/storage/sdk',
    });
});
app.use(errorHandler_1.notFound);
app.use(errorHandler_1.errorHandler);
const PORT = config_1.default.port;
app.listen(PORT, () => {
    console.log(`🚀 Fairbnb Backend API running on port ${PORT}`);
    console.log(`🌍 Environment: ${config_1.default.nodeEnv}`);
    console.log(`📡 0G Storage RPC: ${config_1.default.zeroG.rpcUrl}`);
    console.log(`🔗 API Documentation: http://localhost:${PORT}/api`);
    console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
});
exports.default = app;
//# sourceMappingURL=index.js.map