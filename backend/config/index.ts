import dotenv from 'dotenv';
import path from 'path';

// Load environment variables
dotenv.config();

interface Config {
  port: number;
  nodeEnv: string;
  zeroG: {
    rpcUrl: string;
    indexerRpc: string;
    privateKey: string;
  };
  jwt: {
    secret: string;
    expiresIn: string;
  };
  rateLimit: {
    windowMs: number;
    maxRequests: number;
  };
  upload: {
    maxFileSize: number;
    allowedTypes: string[];
    tempDir: string;
    uploadsDir: string;
  };
  cors: {
    origin: string[];
  };
  encryption: {
    key: string;
  };
}

const config: Config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  zeroG: {
    rpcUrl: process.env.ZEROG_RPC_URL || 'https://evmrpc-testnet.0g.ai/',
    indexerRpc: process.env.ZEROG_INDEXER_RPC || 'https://indexer-storage-testnet-turbo.0g.ai',
    privateKey: process.env.ZEROG_PRIVATE_KEY || '',
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
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10), // 10MB
    allowedTypes: process.env.ALLOWED_FILE_TYPES?.split(',') || [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif'
    ],
    tempDir: path.join(process.cwd(), 'temp'),
    uploadsDir: path.join(process.cwd(), 'uploads'),
  },
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  },
  encryption: {
    key: process.env.ENCRYPTION_KEY || 'default-32-character-key-here!!!',
  },
};

// Validate required environment variables
const requiredEnvVars = [
  'ZEROG_PRIVATE_KEY',
  'JWT_SECRET',
  'ENCRYPTION_KEY',
];

const missingEnvVars = requiredEnvVars.filter(
  (envVar) => !process.env[envVar]
);

if (missingEnvVars.length > 0 && config.nodeEnv === 'production') {
  throw new Error(
    `Missing required environment variables: ${missingEnvVars.join(', ')}`
  );
}

export default config;
