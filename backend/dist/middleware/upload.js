"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadFields = exports.uploadMultiple = exports.uploadSingle = void 0;
const multer_1 = __importDefault(require("multer"));
const config_1 = __importDefault(require("../config"));
const storage = multer_1.default.memoryStorage();
const fileFilter = (req, file, cb) => {
    if (config_1.default.upload.allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    }
    else {
        cb(new Error(`File type ${file.mimetype} is not allowed. Allowed types: ${config_1.default.upload.allowedTypes.join(', ')}`));
    }
};
const upload = (0, multer_1.default)({
    storage,
    fileFilter,
    limits: {
        fileSize: config_1.default.upload.maxFileSize,
        files: 10,
    },
});
exports.uploadSingle = upload.single('file');
exports.uploadMultiple = upload.array('files', 10);
exports.uploadFields = upload.fields([
    { name: 'images', maxCount: 10 },
    { name: 'documents', maxCount: 5 },
]);
exports.default = upload;
//# sourceMappingURL=upload.js.map