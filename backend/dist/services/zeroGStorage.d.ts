import { ZeroGUploadResult, ZeroGDownloadResult } from '../types';
export declare class ZeroGStorageService {
    private provider;
    private signer;
    private indexer;
    constructor();
    uploadFile(filePath: string, originalName: string): Promise<ZeroGUploadResult>;
    uploadFromBuffer(buffer: Buffer, fileName: string, mimeType: string): Promise<ZeroGUploadResult>;
    downloadFile(rootHash: string, fileName?: string): Promise<ZeroGDownloadResult>;
    private getMimeType;
    generateFileUrl(rootHash: string, fileName?: string): string;
    validateFile(fileName: string, fileSize: number, mimeType: string): void;
}
export declare const zeroGStorage: ZeroGStorageService;
//# sourceMappingURL=zeroGStorage.d.ts.map