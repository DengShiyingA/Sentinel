#!/bin/bash
set -e

cd "$(dirname "$0")/packages/sentinel-cli"

echo "📦 Installing dependencies..."
npm install

echo "🔨 Building..."
npm run build

echo "🔗 Linking globally..."
npm link

echo "✅ sentinel 命令已安装，运行 sentinel --help 开始"
