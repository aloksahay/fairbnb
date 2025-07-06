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
        this.rpcUrl = process.env.ZEROG_RPC_URL || 'https://evmrpc-testnet.0g.ai/';
        this.indexerRpc = process.env.ZEROG_INDEXER_RPC || 'https://indexer-storage-testnet-turbo.0g.ai';
        this.uploadTimeout = parseInt(process.env.ZEROG_UPLOAD_TIMEOUT || '90000');
        this.maxRetries = parseInt(process.env.ZEROG_MAX_RETRIES || '3');
        const privateKey = process.env.PRIVATE_KEY;
        if (!privateKey) {
            throw new Error('PRIVATE_KEY environment variable is required');
        }
        this.privateKey = privateKey;
        this.provider = new ethers_1.ethers.JsonRpcProvider(this.rpcUrl);
        this.signer = new ethers_1.ethers.Wallet(this.privateKey, this.provider);
        this.indexer = new _0g_ts_sdk_1.Indexer(this.indexerRpc);
    }
    async uploadFile(filePath, originalName) {
        let file = null;
        let attempt = 0;
        while (attempt < this.maxRetries) {
            try {
                console.log(`📤 Starting upload attempt ${attempt + 1}/${this.maxRetries} for file: ${originalName}`);
                file = await _0g_ts_sdk_1.ZgFile.fromFilePath(filePath);
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
                const uploadPromise = this.indexer.upload(file, this.rpcUrl, this.signer);
                const timeoutPromise = new Promise((_, reject) => {
                    setTimeout(() => reject(new Error('Upload timeout')), this.uploadTimeout);
                });
                const [tx, uploadErr] = await Promise.race([uploadPromise, timeoutPromise]);
                if (uploadErr !== null) {
                    throw new Error(`Upload error: ${uploadErr}`);
                }
                const stats = fs_1.default.statSync(filePath);
                const mimeType = this.getMimeType(originalName);
                console.log(`✅ Upload successful! Transaction: ${tx}`);
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
                console.error(`❌ Upload attempt ${attempt + 1} failed:`, error);
                if (attempt === this.maxRetries - 1) {
                    throw new Error(`Failed to upload file after ${this.maxRetries} attempts: ${error instanceof Error ? error.message : 'Unknown error'}`);
                }
                const waitTime = Math.pow(2, attempt) * 5000;
                console.log(`⏳ Waiting ${waitTime}ms before retry...`);
                await new Promise(resolve => setTimeout(resolve, waitTime));
                attempt++;
            }
            finally {
                if (file) {
                    try {
                        await file.close();
                    }
                    catch (closeError) {
                        console.warn('⚠️ Failed to close file handle:', closeError);
                    }
                    file = null;
                }
            }
        }
        throw new Error('Upload failed after all retry attempts');
    }
    async uploadFromBuffer(buffer, fileName, mimeType) {
        let tempFilePath = null;
        try {
            tempFilePath = path_1.default.join(config_1.default.upload.tempDir, `temp_${Date.now()}_${fileName}`);
            if (!fs_1.default.existsSync(config_1.default.upload.tempDir)) {
                fs_1.default.mkdirSync(config_1.default.upload.tempDir, { recursive: true });
            }
            fs_1.default.writeFileSync(tempFilePath, buffer);
            const result = await this.uploadFile(tempFilePath, fileName);
            return {
                ...result,
                mimeType,
                fileSize: buffer.length,
            };
        }
        catch (error) {
            console.error('❌ Buffer upload failed:', error);
            throw new Error(`Failed to upload buffer: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
        finally {
            if (tempFilePath && fs_1.default.existsSync(tempFilePath)) {
                try {
                    fs_1.default.unlinkSync(tempFilePath);
                }
                catch (cleanupError) {
                    console.warn('⚠️ Failed to clean up temp file:', cleanupError);
                }
            }
        }
    }
    async downloadFile(rootHash, fileName) {
        let tempFilePath = null;
        let attempt = 0;
        while (attempt < this.maxRetries) {
            try {
                console.log(`📥 Starting download attempt ${attempt + 1}/${this.maxRetries} for root hash: ${rootHash}`);
                const tempFileName = fileName || `download_${Date.now()}_${rootHash.slice(0, 8)}`;
                tempFilePath = path_1.default.join(config_1.default.upload.tempDir, tempFileName);
                if (!fs_1.default.existsSync(config_1.default.upload.tempDir)) {
                    fs_1.default.mkdirSync(config_1.default.upload.tempDir, { recursive: true });
                }
                const downloadPromise = this.indexer.download(rootHash, tempFilePath, true);
                const timeoutPromise = new Promise((_, reject) => {
                    setTimeout(() => reject(new Error('Download timeout')), this.uploadTimeout);
                });
                const downloadErr = await Promise.race([downloadPromise, timeoutPromise]);
                if (downloadErr !== null) {
                    throw new Error(`Download error: ${downloadErr}`);
                }
                const data = fs_1.default.readFileSync(tempFilePath);
                const stats = fs_1.default.statSync(tempFilePath);
                console.log(`✅ Download successful for: ${rootHash}`);
                return {
                    data,
                    fileName: tempFileName,
                    mimeType: this.getMimeType(tempFileName),
                    fileSize: stats.size,
                };
            }
            catch (error) {
                console.error(`❌ Download attempt ${attempt + 1} failed:`, error);
                if (attempt === this.maxRetries - 1) {
                    throw new Error(`Failed to download file after ${this.maxRetries} attempts: ${error instanceof Error ? error.message : 'Unknown error'}`);
                }
                const waitTime = Math.pow(2, attempt) * 3000;
                console.log(`⏳ Waiting ${waitTime}ms before retry...`);
                await new Promise(resolve => setTimeout(resolve, waitTime));
                attempt++;
            }
            finally {
                if (tempFilePath && fs_1.default.existsSync(tempFilePath)) {
                    try {
                        fs_1.default.unlinkSync(tempFilePath);
                    }
                    catch (cleanupError) {
                        console.warn('⚠️ Failed to clean up temp file:', cleanupError);
                    }
                }
            }
        }
        throw new Error('Download failed after all retry attempts');
    }
    async checkNetworkStatus() {
        try {
            const [nodes, err] = await this.indexer.selectNodes(4);
            if (err !== null) {
                console.error('Network status check error:', err);
                return { connected: false, nodeCount: 0 };
            }
            if (nodes && nodes.length > 0) {
                console.log('Selected nodes:', nodes);
                try {
                    const firstNodeStatus = await nodes[0].getStatus();
                    console.log('First selected node status:', firstNodeStatus);
                }
                catch (statusError) {
                    console.warn('Failed to get node status:', statusError);
                }
            }
            return {
                connected: true,
                nodeCount: nodes?.length || 0,
                nodes: nodes || []
            };
        }
        catch (error) {
            console.error('Network status check failed:', error);
            return { connected: false, nodeCount: 0 };
        }
    }
    async getWalletBalance() {
        try {
            const balance = await this.provider.getBalance(this.signer.address);
            return ethers_1.ethers.formatEther(balance);
        }
        catch (error) {
            console.error('Failed to get wallet balance:', error);
            return '0';
        }
    }
    getWalletAddress() {
        return this.signer.address;
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