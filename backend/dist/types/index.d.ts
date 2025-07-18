import { Request } from 'express';
export interface ApiResponse<T = any> {
    success: boolean;
    data?: T;
    error?: string;
    message?: string;
}
export interface ZeroGUploadResult {
    rootHash: string;
    txHash: string;
    fileName: string;
    fileSize: number;
    mimeType: string;
    uploadedAt: Date;
}
export interface ZeroGDownloadResult {
    data: Buffer;
    fileName: string;
    mimeType: string;
    fileSize: number;
}
export interface FileUploadInfo {
    fieldname: string;
    originalname: string;
    encoding: string;
    mimetype: string;
    size: number;
    destination: string;
    filename: string;
    path: string;
    buffer?: Buffer;
}
export interface Property {
    id: string;
    title: string;
    description: string;
    pricePerNight: number;
    location: {
        address: string;
        city: string;
        country: string;
        coordinates: {
            lat: number;
            lng: number;
        };
    };
    images: PropertyImage[];
    amenities: string[];
    hostId: string;
    availability: DateRange[];
    createdAt: Date;
    updatedAt: Date;
}
export interface PropertyImage {
    id: string;
    rootHash: string;
    url: string;
    fileName: string;
    mimeType: string;
    fileSize: number;
    isPrimary: boolean;
    uploadedAt: Date;
}
export interface DateRange {
    startDate: Date;
    endDate: Date;
}
export interface User {
    id: string;
    email: string;
    name: string;
    avatar?: PropertyImage;
    walletAddress?: string;
    createdAt: Date;
    updatedAt: Date;
}
export interface Booking {
    id: string;
    propertyId: string;
    guestId: string;
    hostId: string;
    checkIn: Date;
    checkOut: Date;
    totalPrice: number;
    status: BookingStatus;
    createdAt: Date;
    updatedAt: Date;
}
export declare enum BookingStatus {
    PENDING = "pending",
    CONFIRMED = "confirmed",
    CANCELLED = "cancelled",
    COMPLETED = "completed"
}
export interface JwtPayload {
    userId: string;
    email: string;
    iat?: number;
    exp?: number;
}
export interface AppError extends Error {
    statusCode: number;
    isOperational: boolean;
}
export interface MulterRequest extends Request {
    file?: Express.Multer.File;
}
export interface MulterMultipleRequest extends Request {
    files?: Express.Multer.File[];
}
export interface NetworkStatus {
    connected: boolean;
    nodeCount: number;
    nodes?: any[];
}
export interface WalletInfo {
    address: string;
    balance: string;
    balanceETH: string;
}
//# sourceMappingURL=index.d.ts.map