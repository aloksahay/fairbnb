"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.zeroGStorage = exports.ZeroGStorageService = void 0;
const _0g_ts_sdk_1 = require("@0glabs/0g-ts-sdk");
const ethers_1 = require("ethers");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const config_1 = __importDefault(require("../config"));
class ZeroGStorageService {
    constructor() {
        this.provider = new ethers_1.ethers.JsonRpcProvider(config_1.default.zeroG.rpcUrl);
        this.signer = new ethers_1.ethers.Wallet(config_1.default.zeroG.privateKey, this.provider);
        this.indexer = new _0g_ts_sdk_1.Indexer(config_1.default.zeroG.indexerRpc);
    }
    async uploadFile(filePath, originalName) {
        try {
            console.log(`📤 Starting upload for file: ${originalName}`);
            const file = await _0g_ts_sdk_1.ZgFile.fromFilePath(filePath);
            const [tree, treeErr] = await file.merkleTree();
            if (treeErr !== null) {
                throw new Error(`Error generating Merkle tree: ${treeErr}`);
            }
            if (!tree) {
                throw new Error('Failed to generate Merkle tree');
            }
            const rootHash = tree.rootHash();
            if (!rootHash) {
                throw new Error('Failed to get root hash');
            }
            console.log(`🌳 Generated root hash: ${rootHash}`);
            const [tx, uploadErr] = await this.indexer.upload(file, config_1.default.zeroG.rpcUrl, this.signer);
            if (uploadErr !== null) {
                throw new Error(`Upload error: ${uploadErr}`);
            }
            const stats = fs_1.default.statSync(filePath);
            const mimeType = this.getMimeType(originalName);
            console.log(`✅ Upload successful! Transaction: ${tx}`);
            await file.close();
            return {
                rootHash,
                txHash: tx,
                fileSize: stats.size,
                fileName: originalName,
                mimeType,
                uploadedAt: new Date(),
            };
        }
        catch (error) {
            console.error('❌ Upload failed:', error);
            throw new Error(`Failed to upload file: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    async uploadFromBuffer(buffer, fileName, mimeType) {
        try {
            const tempFilePath = path_1.default.join(config_1.default.upload.tempDir, `temp_${Date.now()}_${fileName}`);
            if (!fs_1.default.existsSync(config_1.default.upload.tempDir)) {
                fs_1.default.mkdirSync(config_1.default.upload.tempDir, { recursive: true });
            }
            fs_1.default.writeFileSync(tempFilePath, buffer);
            try {
                const result = await this.uploadFile(tempFilePath, fileName);
                return {
                    ...result,
                    mimeType,
                    fileSize: buffer.length,
                };
            }
            finally {
                if (fs_1.default.existsSync(tempFilePath)) {
                    fs_1.default.unlinkSync(tempFilePath);
                }
            }
        }
        catch (error) {
            console.error('❌ Buffer upload failed:', error);
            throw new Error(`Failed to upload buffer: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    async downloadFile(rootHash, fileName) {
        try {
            console.log(`📥 Starting download for root hash: ${rootHash}`);
            const tempFileName = fileName || `download_${Date.now()}_${rootHash.slice(0, 8)}`;
            const tempFilePath = path_1.default.join(config_1.default.upload.tempDir, tempFileName);
            if (!fs_1.default.existsSync(config_1.default.upload.tempDir)) {
                fs_1.default.mkdirSync(config_1.default.upload.tempDir, { recursive: true });
            }
            const downloadErr = await this.indexer.download(rootHash, tempFilePath, true);
            if (downloadErr !== null) {
                throw new Error(`Download error: ${downloadErr}`);
            }
            const data = fs_1.default.readFileSync(tempFilePath);
            const stats = fs_1.default.statSync(tempFilePath);
            console.log(`✅ Download successful for: ${rootHash}`);
            fs_1.default.unlinkSync(tempFilePath);
            return {
                data,
                fileName: tempFileName,
                mimeType: this.getMimeType(tempFileName),
                fileSize: stats.size,
            };
        }
        catch (error) {
            console.error('❌ Download failed:', error);
            throw new Error(`Failed to download file: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    getMimeType(fileName) {
        const ext = path_1.default.extname(fileName).toLowerCase();
        const mimeTypes = {
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.gif': 'image/gif',
            '.webp': 'image/webp',
            '.svg': 'image/svg+xml',
            '.pdf': 'application/pdf',
            '.txt': 'text/plain',
            '.json': 'application/json',
        };
        return mimeTypes[ext] || 'application/octet-stream';
    }
    generateFileUrl(rootHash, fileName) {
        const baseUrl = process.env.API_BASE_URL || `http://localhost:${config_1.default.port}`;
        const fileParam = fileName ? `?filename=${encodeURIComponent(fileName)}` : '';
        return `${baseUrl}/api/files/${rootHash}${fileParam}`;
    }
    validateFile(fileName, fileSize, mimeType) {
        if (fileSize > config_1.default.upload.maxFileSize) {
            throw new Error(`File size exceeds maximum allowed size of ${config_1.default.upload.maxFileSize} bytes`);
        }
        if (!config_1.default.upload.allowedTypes.includes(mimeType)) {
            throw new Error(`File type ${mimeType} is not allowed. Allowed types: ${config_1.default.upload.allowedTypes.join(', ')}`);
        }
        const ext = path_1.default.extname(fileName).toLowerCase();
        const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        if (!allowedExtensions.includes(ext)) {
            throw new Error(`File extension ${ext} is not allowed`);
        }
    }
}
exports.ZeroGStorageService = ZeroGStorageService;
exports.zeroGStorage = new ZeroGStorageService();
//# sourceMappingURL=zeroGStorage.js.map