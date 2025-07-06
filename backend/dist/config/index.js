"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
dotenv_1.default.config();
const config = {
    port: parseInt(process.env.PORT || '3000', 10),
    nodeEnv: process.env.NODE_ENV || 'development',
    zeroG: {
        rpcUrl: process.env.ZEROG_RPC_URL || 'https://evmrpc-testnet.0g.ai/',
        indexerRpc: process.env.ZEROG_INDEXER_RPC || 'https://indexer-storage-testnet-turbo.0g.ai',
        privateKey: process.env.PRIVATE_KEY || '',
    },
    zeroGCompute: {
        fallbackFee: parseFloat(process.env.ZEROG_FALLBACK_FEE || '0.01'),
    },
    celo: {
        rpcUrl: process.env.CELO_RPC_URL || 'https://alfajores-forno.celo-testnet.org',
        chainId: parseInt(process.env.CELO_CHAIN_ID || '44787', 10),
    },
    selfVerification: {
        contractAddress: process.env.SELF_VERIFICATION_CONTRACT_ADDRESS || '0xD5e23f89C260c9893c02bfb48D34232e54347970',
    },
    jwt: {
        secret: process.env.JWT_SECRET || 'fallback-secret-key',
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    },
    rateLimit: {
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
        maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
    },
    upload: {
        maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10),
        allowedTypes: process.env.ALLOWED_FILE_TYPES?.split(',') || [
            'image/jpeg',
            'image/png',
            'image/webp',
            'image/gif'
        ],
        tempDir: path_1.default.join(process.cwd(), 'temp'),
        uploadsDir: path_1.default.join(process.cwd(), 'uploads'),
    },
    cors: {
        origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
    },
    encryption: {
        key: process.env.ENCRYPTION_KEY || 'default-32-character-key-here!!!',
    },
};
const requiredEnvVars = [
    'PRIVATE_KEY',
    'JWT_SECRET',
    'ENCRYPTION_KEY',
];
const missingEnvVars = requiredEnvVars.filter((envVar) => !process.env[envVar]);
if (missingEnvVars.length > 0 && config.nodeEnv === 'production') {
    throw new Error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
}
exports.default = config;
//# sourceMappingURL=index.js.map