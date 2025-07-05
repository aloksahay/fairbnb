interface Config {
    port: number;
    nodeEnv: string;
    zeroG: {
        rpcUrl: string;
        indexerRpc: string;
        privateKey: string;
    };
    jwt: {
        secret: string;
        expiresIn: string;
    };
    rateLimit: {
        windowMs: number;
        maxRequests: number;
    };
    upload: {
        maxFileSize: number;
        allowedTypes: string[];
        tempDir: string;
        uploadsDir: string;
    };
    cors: {
        origin: string[];
    };
    encryption: {
        key: string;
    };
}
declare const config: Config;
export default config;
//# sourceMappingURL=index.d.ts.map