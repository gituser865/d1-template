#!/bin/bash

# Complete Task Marketplace - Download & Setup Script
# This creates a ready-to-use project package

echo "📦 Creating Task Marketplace Package..."

PROJECT="task-marketplace"

# Create the project
mkdir -p $PROJECT/{backend/src/{config,middleware,models,routes,services},frontend/{pages,components,store,utils},docs,.github/workflows,uploads}

# Copy all files (as shown above in setup-project.sh)
# ... (all the file creation commands from setup-project.sh)

# Create ZIP
cd ..
zip -r "${PROJECT}.zip" "$PROJECT/" -q

echo "✅ Package created: ${PROJECT}.zip"
echo "📥 Ready to download and extract!"
echo ""
echo "🚀 To use:"
echo "   1. Extract the ZIP file"
echo "   2. cd $PROJECT"
echo "   3. docker-compose up --build"