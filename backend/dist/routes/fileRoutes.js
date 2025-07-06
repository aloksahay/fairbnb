"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const upload_1 = __importDefault(require("../middleware/upload"));
const fileController_1 = require("../controllers/fileController");
const router = (0, express_1.Router)();
router.post('/upload', upload_1.default.single('file'), fileController_1.uploadFile);
router.post('/upload-multiple', upload_1.default.array('files', 10), fileController_1.uploadMultipleFiles);
router.get('/:rootHash', fileController_1.downloadFile);
router.get('/:rootHash/info', fileController_1.getFileInfo);
router.get('/:rootHash/exists', fileController_1.checkFileExists);
router.get('/status/network', fileController_1.getNetworkStatus);
exports.default = router;
//# sourceMappingURL=fileRoutes.js.map