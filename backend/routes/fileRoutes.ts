import { Router } from 'express';
import upload from '../middleware/upload';
import {
  uploadFile,
  uploadMultipleFiles,
  downloadFile,
  getFileInfo,
  checkFileExists,
  getNetworkStatus
} from '../controllers/fileController';

const router = Router();

// File upload routes
router.post('/upload', upload.single('file'), uploadFile);
router.post('/upload-multiple', upload.array('files', 10), uploadMultipleFiles);

// File download and info routes
router.get('/:rootHash', downloadFile);
router.get('/:rootHash/info', getFileInfo);
router.get('/:rootHash/exists', checkFileExists);

// Network status route (new)
router.get('/status/network', getNetworkStatus);

export default router;
