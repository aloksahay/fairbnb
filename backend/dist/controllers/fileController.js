"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getFileInfo = exports.downloadFile = exports.uploadMultipleFiles = exports.uploadFile = void 0;
const zeroGStorage_1 = require("../services/zeroGStorage");
const uploadFile = async (req, res) => {
    try {
        if (!req.file) {
            res.status(400).json({
                success: false,
                error: 'No file provided',
            });
            return;
        }
        zeroGStorage_1.zeroGStorage.validateFile(req.file.originalname, req.file.size, req.file.mimetype);
        const result = await zeroGStorage_1.zeroGStorage.uploadFromBuffer(req.file.buffer, req.file.originalname, req.file.mimetype);
        const url = zeroGStorage_1.zeroGStorage.generateFileUrl(result.rootHash, result.fileName);
        res.status(200).json({
            success: true,
            data: {
                ...result,
                url,
            },
            message: 'File uploaded successfully',
        });
    }
    catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : 'Upload failed',
        });
    }
};
exports.uploadFile = uploadFile;
const uploadMultipleFiles = async (req, res) => {
    try {
        const files = req.files;
        if (!files || files.length === 0) {
            res.status(400).json({
                success: false,
                error: 'No files provided',
            });
            return;
        }
        const uploadPromises = files.map(async (file) => {
            zeroGStorage_1.zeroGStorage.validateFile(file.originalname, file.size, file.mimetype);
            const result = await zeroGStorage_1.zeroGStorage.uploadFromBuffer(file.buffer, file.originalname, file.mimetype);
            const url = zeroGStorage_1.zeroGStorage.generateFileUrl(result.rootHash, result.fileName);
            return {
                ...result,
                url,
            };
        });
        const results = await Promise.all(uploadPromises);
        res.status(200).json({
            success: true,
            data: results,
            message: `${results.length} files uploaded successfully`,
        });
    }
    catch (error) {
        console.error('Multiple upload error:', error);
        res.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : 'Upload failed',
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
                success: false,
                error: 'Root hash is required',
            });
            return;
        }
        const result = await zeroGStorage_1.zeroGStorage.downloadFile(rootHash, filename);
        res.setHeader('Content-Type', result.mimeType);
        res.setHeader('Content-Length', result.fileSize);
        res.setHeader('Content-Disposition', `inline; filename="${result.fileName}"`);
        res.setHeader('Cache-Control', 'public, max-age=31536000');
        res.send(result.data);
    }
    catch (error) {
        console.error('Download error:', error);
        res.status(404).json({
            success: false,
            error: error instanceof Error ? error.message : 'File not found',
        });
    }
};
exports.downloadFile = downloadFile;
const getFileInfo = async (req, res) => {
    try {
        const { rootHash } = req.params;
        if (!rootHash) {
            res.status(400).json({
                success: false,
                error: 'Root hash is required',
            });
            return;
        }
        const result = await zeroGStorage_1.zeroGStorage.downloadFile(rootHash);
        res.status(200).json({
            success: true,
            data: {
                rootHash,
                exists: true,
                size: result.fileSize,
                mimeType: result.mimeType,
                url: zeroGStorage_1.zeroGStorage.generateFileUrl(rootHash),
            },
            message: 'File information retrieved successfully',
        });
    }
    catch (error) {
        console.error('File info error:', error);
        res.status(404).json({
            success: false,
            error: error instanceof Error ? error.message : 'File not found',
        });
    }
};
exports.getFileInfo = getFileInfo;
//# sourceMappingURL=fileController.js.map