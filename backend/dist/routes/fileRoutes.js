"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const upload_1 = require("../middleware/upload");
const fileController_1 = require("../controllers/fileController");
const router = (0, express_1.Router)();
router.post('/upload', upload_1.uploadSingle, fileController_1.uploadFile);
router.post('/upload-multiple', upload_1.uploadMultiple, fileController_1.uploadMultipleFiles);
router.get('/:rootHash', fileController_1.downloadFile);
router.get('/:rootHash/info', fileController_1.getFileInfo);
exports.default = router;
//# sourceMappingURL=fileRoutes.js.map