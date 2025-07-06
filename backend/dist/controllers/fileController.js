"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNetworkStatus = exports.checkFileExists = exports.getFileInfo = exports.downloadFile = exports.uploadMultipleFiles = exports.uploadFile = void 0;
const zeroGStorage_1 = require("../services/zeroGStorage");
const uploadFile = async (req, res) => {
    try {
        if (!req.file) {
            res.status(400).json({
                error: 'No file uploaded',
                message: 'Please provide a file to upload'
            });
            return;
        }
        const { buffer, originalname, mimetype } = req.file;
        zeroGStorage_1.zeroGStorage.validateFile(originalname, buffer.length, mimetype);
        console.log(`📤 Processing upload: ${originalname} (${buffer.length} bytes, ${mimetype})`);
        const result = await zeroGStorage_1.zeroGStorage.uploadFromBuffer(buffer, originalname, mimetype);
        res.json({
            success: true,
            message: 'File uploaded successfully',
            data: {
                rootHash: result.rootHash,
                txHash: result.txHash,
                fileName: result.fileName,
                fileSize: result.fileSize,
                mimeType: result.mimeType,
                uploadedAt: result.uploadedAt,
                downloadUrl: zeroGStorage_1.zeroGStorage.generateFileUrl(result.rootHash, result.fileName)
            }
        });
    }
    catch (error) {
        console.error('Upload controller error:', error);
        const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
        const statusCode = errorMessage.includes('not allowed') ? 400 : 500;
        res.status(statusCode).json({
            success: false,
            error: 'Upload failed',
            message: errorMessage
        });
    }
};
exports.uploadFile = uploadFile;
const uploadMultipleFiles = async (req, res) => {
    try {
        if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
            res.status(400).json({
                success: false,
                error: 'No files provided'
            });
            return;
        }
        const results = [];
        for (const file of req.files) {
            const result = await zeroGStorage_1.zeroGStorage.uploadFromBuffer(file.buffer, file.originalname, file.mimetype);
            results.push(result);
        }
        res.json({
            success: true,
            data: results,
            message: `${results.length} files uploaded successfully`
        });
    }
    catch (error) {
        console.error('Multiple upload error:', error);
        res.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : 'Multiple upload failed'
        });
    }
};
exports.uploadMultipleFiles = uploadMultipleFiles;
const downloadFile = async (req, res) => {
    try {
        const { rootHash } = req.params;
        const { filename } = req.query;
        if (!rootHash) {
            res.status(400).json({
                error: 'Missing root hash',
                message: 'Root hash is required for download'
            });
            return;
        }
        console.log(`📥 Processing download: ${rootHash}`);
        const result = await zeroGStorage_1.zeroGStorage.downloadFile(rootHash, filename);
        res.set({
            'Content-Type': result.mimeType,
            'Content-Length': result.fileSize.toString(),
            'Content-Disposition': `attachment; filename="${result.fileName}"`,
            'Cache-Control': 'public, max-age=31536000',
        });
        res.send(result.data);
    }
    catch (error) {
        console.error('Download controller error:', error);
        const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
        const statusCode = errorMessage.includes('not found') ? 404 : 500;
        res.status(statusCode).json({
            success: false,
            error: 'Download failed',
            message: errorMessage
        });
    }
};
exports.downloadFile = downloadFile;
const getFileInfo = async (req, res) => {
    try {
        const { rootHash } = req.params;
        if (!rootHash) {
            res.status(400).json({
                error: 'Missing root hash',
                message: 'Root hash is required'
            });
            return;
        }
        res.json({
            success: true,
            data: {
                rootHash,
                downloadUrl: zeroGStorage_1.zeroGStorage.generateFileUrl(rootHash),
                available: true
            }
        });
    }
    catch (error) {
        console.error('File info controller error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get file info',
            message: error instanceof Error ? error.message : 'Unknown error occurred'
        });
    }
};
exports.getFileInfo = getFileInfo;
const checkFileExists = async (req, res) => {
    try {
        const { rootHash } = req.params;
        if (!rootHash) {
            res.status(400).json({
                success: false,
                error: 'Root hash is required'
            });
            return;
        }
        res.json({
            success: true,
            data: {
                rootHash,
                exists: true,
                downloadUrl: zeroGStorage_1.zeroGStorage.generateFileUrl(rootHash)
            },
            message: 'File existence checked'
        });
    }
    catch (error) {
        console.error('File existence check error:', error);
        res.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : 'Failed to check file existence'
        });
    }
};
exports.checkFileExists = checkFileExists;
const getNetworkStatus = async (req, res) => {
    try {
        const status = await zeroGStorage_1.zeroGStorage.checkNetworkStatus();
        const balance = await zeroGStorage_1.zeroGStorage.getWalletBalance();
        const walletAddress = zeroGStorage_1.zeroGStorage.getWalletAddress();
        res.json({
            success: true,
            data: {
                network: {
                    connected: status.connected,
                    nodeCount: status.nodeCount,
                    nodes: status.nodes?.map(node => ({
                        url: node.url,
                        timeout: node.timeout,
                        retry: node.retry
                    })) || []
                },
                wallet: {
                    address: walletAddress,
                    balance: balance,
                    balanceETH: `${balance} ETH`
                },
                timestamp: new Date().toISOString()
            }
        });
    }
    catch (error) {
        console.error('Network status controller error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get network status',
            message: error instanceof Error ? error.message : 'Unknown error occurred'
        });
    }
};
exports.getNetworkStatus = getNetworkStatus;
//# sourceMappingURL=fileController.js.map