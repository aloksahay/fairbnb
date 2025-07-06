import { ZgFile, Indexer } from '@0glabs/0g-ts-sdk';
import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import config from '../config';
import { ZeroGUploadResult, ZeroGDownloadResult } from '../types';

export class ZeroGStorageService {
  private provider: ethers.JsonRpcProvider;
  private signer: ethers.Wallet;
  private indexer: Indexer;
  private rpcUrl: string;
  private indexerRpc: string;
  private privateKey: string;
  private uploadTimeout: number;
  private maxRetries: number;

  constructor() {
    this.rpcUrl = process.env.ZEROG_RPC_URL || 'https://evmrpc-testnet.0g.ai/';
    this.indexerRpc = process.env.ZEROG_INDEXER_RPC || 'https://indexer-storage-testnet-turbo.0g.ai';
    this.uploadTimeout = parseInt(process.env.ZEROG_UPLOAD_TIMEOUT || '90000'); // 90 seconds default
    this.maxRetries = parseInt(process.env.ZEROG_MAX_RETRIES || '3'); // 3 retries default
    
    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey) {
      throw new Error('PRIVATE_KEY environment variable is required');
    }
    this.privateKey = privateKey;

    this.provider = new ethers.JsonRpcProvider(this.rpcUrl);
    this.signer = new ethers.Wallet(this.privateKey, this.provider);
    this.indexer = new Indexer(this.indexerRpc);
  }

  async uploadFile(filePath: string, originalName: string): Promise<ZeroGUploadResult> {
    let file: ZgFile | null = null;
    let attempt = 0;
    
    while (attempt < this.maxRetries) {
      try {
        console.log(`📤 Starting upload attempt ${attempt + 1}/${this.maxRetries} for file: ${originalName}`);
        
        // Create ZgFile from file path
        file = await ZgFile.fromFilePath(filePath);
        
        // Generate merkle tree
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
        
        // Upload file with timeout handling
        const uploadPromise = this.indexer.upload(file, this.rpcUrl, this.signer);
        const timeoutPromise = new Promise<never>((_, reject) => {
          setTimeout(() => reject(new Error('Upload timeout')), this.uploadTimeout);
        });
        
        const [tx, uploadErr] = await Promise.race([uploadPromise, timeoutPromise]);
        
        if (uploadErr !== null) {
          throw new Error(`Upload error: ${uploadErr}`);
        }
        
        const stats = fs.statSync(filePath);
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
        
      } catch (error) {
        console.error(`❌ Upload attempt ${attempt + 1} failed:`, error);
        
        // If this is the last attempt, throw the error
        if (attempt === this.maxRetries - 1) {
          throw new Error(`Failed to upload file after ${this.maxRetries} attempts: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
        
        // Wait before retrying (exponential backoff)
        const waitTime = Math.pow(2, attempt) * 5000; // 5s, 10s, 20s
        console.log(`⏳ Waiting ${waitTime}ms before retry...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
        
        attempt++;
      } finally {
        // Always close the file handle
        if (file) {
          try {
            await file.close();
          } catch (closeError) {
            console.warn('⚠️ Failed to close file handle:', closeError);
          }
          file = null; // Reset for next attempt
        }
      }
    }
    
    throw new Error('Upload failed after all retry attempts');
  }

  async uploadFromBuffer(
    buffer: Buffer, 
    fileName: string, 
    mimeType: string
  ): Promise<ZeroGUploadResult> {
    let tempFilePath: string | null = null;
    
    try {
      // Create temporary file
      tempFilePath = path.join(config.upload.tempDir, `temp_${Date.now()}_${fileName}`);
      
      if (!fs.existsSync(config.upload.tempDir)) {
        fs.mkdirSync(config.upload.tempDir, { recursive: true });
      }
      
      fs.writeFileSync(tempFilePath, buffer);
      
      // Upload the temporary file
      const result = await this.uploadFile(tempFilePath, fileName);
      return {
        ...result,
        mimeType,
        fileSize: buffer.length,
      };
      
    } catch (error) {
      console.error('❌ Buffer upload failed:', error);
      throw new Error(`Failed to upload buffer: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      // Clean up temporary file
      if (tempFilePath && fs.existsSync(tempFilePath)) {
        try {
          fs.unlinkSync(tempFilePath);
        } catch (cleanupError) {
          console.warn('⚠️ Failed to clean up temp file:', cleanupError);
        }
      }
    }
  }

  async downloadFile(rootHash: string, fileName?: string): Promise<ZeroGDownloadResult> {
    let tempFilePath: string | null = null;
    let attempt = 0;
    
    while (attempt < this.maxRetries) {
      try {
        console.log(`📥 Starting download attempt ${attempt + 1}/${this.maxRetries} for root hash: ${rootHash}`);
        
        const tempFileName = fileName || `download_${Date.now()}_${rootHash.slice(0, 8)}`;
        tempFilePath = path.join(config.upload.tempDir, tempFileName);
        
        if (!fs.existsSync(config.upload.tempDir)) {
          fs.mkdirSync(config.upload.tempDir, { recursive: true });
        }
        
        // Download file with timeout
        const downloadPromise = this.indexer.download(rootHash, tempFilePath, true);
        const timeoutPromise = new Promise<never>((_, reject) => {
          setTimeout(() => reject(new Error('Download timeout')), this.uploadTimeout);
        });
        
        const downloadErr = await Promise.race([downloadPromise, timeoutPromise]);
        if (downloadErr !== null) {
          throw new Error(`Download error: ${downloadErr}`);
        }
        
        const data = fs.readFileSync(tempFilePath);
        const stats = fs.statSync(tempFilePath);
        
        console.log(`✅ Download successful for: ${rootHash}`);
        
        return {
          data,
          fileName: tempFileName,
          mimeType: this.getMimeType(tempFileName),
          fileSize: stats.size,
        };
        
      } catch (error) {
        console.error(`❌ Download attempt ${attempt + 1} failed:`, error);
        
        // If this is the last attempt, throw the error
        if (attempt === this.maxRetries - 1) {
          throw new Error(`Failed to download file after ${this.maxRetries} attempts: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
        
        // Wait before retrying
        const waitTime = Math.pow(2, attempt) * 3000; // 3s, 6s, 12s
        console.log(`⏳ Waiting ${waitTime}ms before retry...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
        
        attempt++;
      } finally {
        // Clean up temporary file
        if (tempFilePath && fs.existsSync(tempFilePath)) {
          try {
            fs.unlinkSync(tempFilePath);
          } catch (cleanupError) {
            console.warn('⚠️ Failed to clean up temp file:', cleanupError);
          }
        }
      }
    }
    
    throw new Error('Download failed after all retry attempts');
  }

  async checkNetworkStatus(): Promise<{ connected: boolean; nodeCount: number; nodes?: any[] }> {
    try {
      const [nodes, err] = await this.indexer.selectNodes(4);
      if (err !== null) {
        console.error('Network status check error:', err);
        return { connected: false, nodeCount: 0 };
      }
      
      // Log node information for debugging
      if (nodes && nodes.length > 0) {
        console.log('Selected nodes:', nodes);
        
        // Check first node status
        try {
          const firstNodeStatus = await nodes[0].getStatus();
          console.log('First selected node status:', firstNodeStatus);
        } catch (statusError) {
          console.warn('Failed to get node status:', statusError);
        }
      }
      
      return { 
        connected: true, 
        nodeCount: nodes?.length || 0,
        nodes: nodes || []
      };
    } catch (error) {
      console.error('Network status check failed:', error);
      return { connected: false, nodeCount: 0 };
    }
  }

  async getWalletBalance(): Promise<string> {
    try {
      const balance = await this.provider.getBalance(this.signer.address);
      return ethers.formatEther(balance);
    } catch (error) {
      console.error('Failed to get wallet balance:', error);
      return '0';
    }
  }

  getWalletAddress(): string {
    return this.signer.address;
  }

  private getMimeType(fileName: string): string {
    const ext = path.extname(fileName).toLowerCase();
    const mimeTypes: Record<string, string> = {
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

  generateFileUrl(rootHash: string, fileName?: string): string {
    const baseUrl = process.env.API_BASE_URL || `http://localhost:${config.port}`;
    const fileParam = fileName ? `?filename=${encodeURIComponent(fileName)}` : '';
    return `${baseUrl}/api/files/${rootHash}${fileParam}`;
  }

  validateFile(fileName: string, fileSize: number, mimeType: string): void {
    if (fileSize > config.upload.maxFileSize) {
      throw new Error(`File size exceeds maximum allowed size of ${config.upload.maxFileSize} bytes`);
    }

    if (!config.upload.allowedTypes.includes(mimeType)) {
      throw new Error(`File type ${mimeType} is not allowed. Allowed types: ${config.upload.allowedTypes.join(', ')}`);
    }

    const ext = path.extname(fileName).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    if (!allowedExtensions.includes(ext)) {
      throw new Error(`File extension ${ext} is not allowed`);
    }
  }
}

export const zeroGStorage = new ZeroGStorageService();
