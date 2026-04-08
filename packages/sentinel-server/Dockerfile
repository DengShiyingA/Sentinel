FROM node:20-alpine

WORKDIR /app

# 安装依赖
COPY package*.json ./
RUN npm ci

# 复制源码
COPY prisma ./prisma
COPY sources ./sources
COPY tsconfig.json ./

# Prisma generate（PGlite 适配器需要）
RUN npx prisma generate

# 数据目录
RUN mkdir -p /data/sentinel

# 非 root 用户
RUN addgroup -g 1001 -S sentinel && \
    adduser -S sentinel -u 1001 && \
    chown -R sentinel:sentinel /data/sentinel
USER sentinel

EXPOSE 3005

CMD ["npx", "tsx", "sources/main.ts"]
