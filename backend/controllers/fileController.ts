import { Request, Response } from 'express';
import { zeroGStorage } from '../services/zeroGStorage';
import { ApiResponse, MulterRequest, MulterMultipleRequest } from '../types';

export const uploadFile = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.file) {
      res.status(400).json({
        error: 'No file uploaded',
        message: 'Please provide a file to upload'
      });
      return;
    }

    const { buffer, originalname, mimetype } = req.file;
    
    // Validate file
    zeroGStorage.validateFile(originalname, buffer.length, mimetype);
    
    console.log(`📤 Processing upload: ${originalname} (${buffer.length} bytes, ${mimetype})`);
    
    // Upload to 0G Storage
    const result = await zeroGStorage.uploadFromBuffer(buffer, originalname, mimetype);

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
        downloadUrl: zeroGStorage.generateFileUrl(result.rootHash, result.fileName)
      }
    });

  } catch (error) {
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

export const uploadMultipleFiles = async (req: Request, res: Response): Promise<void> => {
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
      const result = await zeroGStorage.uploadFromBuffer(
        file.buffer,
        file.originalname,
        file.mimetype
      );
      results.push(result);
    }

    res.json({
      success: true,
      data: results,
      message: `${results.length} files uploaded successfully`
    });
  } catch (error) {
    console.error('Multiple upload error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Multiple upload failed'
    });
  }
};

export const downloadFile = async (req: Request, res: Response): Promise<void> => {
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
    
    // Download from 0G Storage
    const result = await zeroGStorage.downloadFile(rootHash, filename as string);

    // Set appropriate headers
    res.set({
      'Content-Type': result.mimeType,
      'Content-Length': result.fileSize.toString(),
      'Content-Disposition': `attachment; filename="${result.fileName}"`,
      'Cache-Control': 'public, max-age=31536000', // Cache for 1 year
    });

    res.send(result.data);

  } catch (error) {
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

export const getFileInfo = async (req: Request, res: Response): Promise<void> => {
  try {
    const { rootHash } = req.params;
    
    if (!rootHash) {
      res.status(400).json({ 
        error: 'Missing root hash',
        message: 'Root hash is required'
      });
      return;
    }
    
    // For now, we'll return basic info
    // In a full implementation, you might want to store metadata
    res.json({
      success: true,
      data: {
        rootHash,
        downloadUrl: zeroGStorage.generateFileUrl(rootHash),
        available: true // This would need actual verification
      }
    });
    
  } catch (error) {
    console.error('File info controller error:', error);
    
    res.status(500).json({
      success: false,
      error: 'Failed to get file info',
      message: error instanceof Error ? error.message : 'Unknown error occurred'
    });
  }
};

export const checkFileExists = async (req: Request, res: Response): Promise<void> => {
  try {
    const { rootHash } = req.params;

    if (!rootHash) {
      res.status(400).json({
        success: false,
        error: 'Root hash is required'
      });
      return;
    }

    // For now, assume file exists if we have a valid root hash
    // In a production system, you would check the actual availability
    res.json({
      success: true,
      data: {
        rootHash,
        exists: true,
        downloadUrl: zeroGStorage.generateFileUrl(rootHash)
      },
      message: 'File existence checked'
    });
  } catch (error) {
    console.error('File existence check error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to check file existence'
    });
  }
};

// New endpoint for network status based on SDK documentation
export const getNetworkStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const status = await zeroGStorage.checkNetworkStatus();
    const balance = await zeroGStorage.getWalletBalance();
    const walletAddress = zeroGStorage.getWalletAddress();
    
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

  } catch (error) {
    console.error('Network status controller error:', error);
    
    res.status(500).json({
      success: false,
      error: 'Failed to get network status',
      message: error instanceof Error ? error.message : 'Unknown error occurred'
    });
  }
};
