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
const imageAnalysisRoutes_1 = __importDefault(require("./routes/imageAnalysisRoutes"));
const selfVerificationRoutes_1 = __importDefault(require("./routes/selfVerificationRoutes"));
const selfRoutes_1 = __importDefault(require("./routes/selfRoutes"));
const listingRoutes_1 = __importDefault(require("./routes/listingRoutes"));
const zeroGRoutes_1 = __importDefault(require("./routes/zeroGRoutes"));
const errorHandler_1 = require("./middleware/errorHandler");
const app = (0, express_1.default)();
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: config_1.default.nodeEnv === 'development' ? true : config_1.default.cors.origin,
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
app.use((req, res, next) => {
    const startTime = Date.now();
    const requestId = Math.random().toString(36).substr(2, 9);
    console.log(`📥 [${requestId}] ${req.method} ${req.path} - ${new Date().toISOString()}`);
    if (req.path.startsWith('/api/')) {
        console.log(`📋 [${requestId}] Headers:`, {
            'content-type': req.get('content-type'),
            'content-length': req.get('content-length'),
            'user-agent': req.get('user-agent')
        });
        if (req.method !== 'GET' && req.body && Object.keys(req.body).length > 0) {
            console.log(`📦 [${requestId}] Body keys:`, Object.keys(req.body));
        }
    }
    const timeoutWarning = setTimeout(() => {
        console.warn(`⚠️ [${requestId}] Request taking longer than 30s: ${req.method} ${req.path}`);
    }, 30000);
    res.on('finish', () => {
        clearTimeout(timeoutWarning);
        const duration = Date.now() - startTime;
        console.log(`📤 [${requestId}] ${req.method} ${req.path} - ${res.statusCode} - ${duration}ms`);
        if (duration > 10000) {
            console.warn(`🐌 [${requestId}] Slow request detected: ${duration}ms`);
        }
    });
    next();
});
app.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Fairbnb Backend API is running',
        timestamp: new Date().toISOString(),
        environment: config_1.default.nodeEnv,
    });
});
app.use('/api/files', fileRoutes_1.default);
app.use('/api/image-analysis', imageAnalysisRoutes_1.default);
app.use('/api/self-verification', selfVerificationRoutes_1.default);
app.use('/api/self', selfRoutes_1.default);
app.use('/api/listings', listingRoutes_1.default);
app.use('/api/zerog', zeroGRoutes_1.default);
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
            textAnalysis: {
                'POST /api/image-analysis/analyze': 'Analyze text to extract names using llama-3.3-70b-instruct AI',
                'GET /api/image-analysis/account': 'Get 0G Compute account information',
                'GET /api/image-analysis/providers': 'Get available AI providers',
            },
            listings: {
                'POST /api/listings/create': 'Create a new listing with header image upload to ZeroG and OCR text analysis',
                'GET /api/listings/:listingId': 'Get listing information',
            },
            selfVerification: {
                'GET /api/self-verification/health': 'Health check for Self verification service',
                'GET /api/self-verification/status/:userAddress': 'Get verification status for a user',
                'GET /api/self-verification/config': 'Generate Self configuration for frontend',
                'GET /api/self-verification/requirements/:userType': 'Get verification requirements for user type',
                'GET /api/self-verification/types': 'Get all verification types',
                'POST /api/self-verification/validate': 'Validate a verification proof',
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