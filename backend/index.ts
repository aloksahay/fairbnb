import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import config from './config';
import fileRoutes from './routes/fileRoutes';
import imageAnalysisRoutes from './routes/imageAnalysisRoutes';
import selfVerificationRoutes from './routes/selfVerificationRoutes';
import selfRoutes from './routes/selfRoutes';
import { errorHandler, notFound } from './middleware/errorHandler';

const app = express();

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: config.nodeEnv === 'development' ? true : config.cors.origin, // Allow all origins in development
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.maxRequests,
  message: {
    success: false,
    error: 'Too many requests from this IP, please try again later.',
  },
});
app.use('/api/', limiter);

// Logging
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Body parsing middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Fairbnb Backend API is running',
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv,
  });
});

// API routes
app.use('/api/files', fileRoutes);
app.use('/api/image-analysis', imageAnalysisRoutes);
app.use('/api/self-verification', selfVerificationRoutes);
app.use('/api/self', selfRoutes);

// API documentation endpoint
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

// 404 handler
app.use(notFound);

// Error handler
app.use(errorHandler);

// Start server
const PORT = config.port;
app.listen(PORT, () => {
  console.log(`🚀 Fairbnb Backend API running on port ${PORT}`);
  console.log(`🌍 Environment: ${config.nodeEnv}`);
  console.log(`📡 0G Storage RPC: ${config.zeroG.rpcUrl}`);
  console.log(`🔗 API Documentation: http://localhost:${PORT}/api`);
  console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
});

export default app;
