import express from 'express';
export declare function createHttpServer(port?: number): express.Application;
export declare function startHttpServer(port?: number): Promise<void>;
