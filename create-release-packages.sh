#!/bin/bash

# Task Marketplace - Release Package Generator
# Creates all downloadable ZIP files for GitHub release

set -e

VERSION="1.0.0"
PROJECT="task-marketplace"

echo "📦 Creating Task Marketplace v${VERSION} Release Packages..."
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
  echo "❌ Error: docker-compose.yml not found!"
  echo "Please run this script from the project root directory."
  exit 1
fi

# Create release directory
RELEASE_DIR="release-v${VERSION}"
mkdir -p "$RELEASE_DIR"

echo "🔄 Creating package archives..."

# 1. Complete Package
echo "📦 Creating complete package..."
zip -r "$RELEASE_DIR/${PROJECT}-v${VERSION}-complete.zip" \
  backend/ \
  frontend/ \
  docs/ \
  .github/ \
  docker-compose.yml \
  .gitignore \
  README.md \
  -q

SIZE_COMPLETE=$(du -sh "$RELEASE_DIR/${PROJECT}-v${VERSION}-complete.zip" | cut -f1)
echo "   ✅ Complete: $SIZE_COMPLETE"

# 2. Backend Only
echo "📦 Creating backend package..."
zip -r "$RELEASE_DIR/${PROJECT}-v${VERSION}-backend.zip" \
  backend/ \
  -q

SIZE_BACKEND=$(du -sh "$RELEASE_DIR/${PROJECT}-v${VERSION}-backend.zip" | cut -f1)
echo "   ✅ Backend: $SIZE_BACKEND"

# 3. Frontend Only
echo "📦 Creating frontend package..."
zip -r "$RELEASE_DIR/${PROJECT}-v${VERSION}-frontend.zip" \
  frontend/ \
  -q

SIZE_FRONTEND=$(du -sh "$RELEASE_DIR/${PROJECT}-v${VERSION}-frontend.zip" | cut -f1)
echo "   ✅ Frontend: $SIZE_FRONTEND"

# 4. Docs Only
echo "📦 Creating documentation package..."
zip -r "$RELEASE_DIR/${PROJECT}-v${VERSION}-docs.zip" \
  docs/ \
  README.md \
  -q

SIZE_DOCS=$(du -sh "$RELEASE_DIR/${PROJECT}-v${VERSION}-docs.zip" | cut -f1)
echo "   ✅ Documentation: $SIZE_DOCS"

# 5. Create source archives
echo "📦 Creating source archives..."
tar -czf "$RELEASE_DIR/${PROJECT}-v${VERSION}-source.tar.gz" \
  --exclude=node_modules \
  --exclude=.next \
  --exclude=dist \
  --exclude=uploads \
  backend/ frontend/ docs/ .github/ docker-compose.yml .gitignore README.md

SIZE_SOURCE=$(du -sh "$RELEASE_DIR/${PROJECT}-v${VERSION}-source.tar.gz" | cut -f1)
echo "   ✅ Source (tar.gz): $SIZE_SOURCE"

# Create checksum file
echo "🔐 Generating checksums..."
cd "$RELEASE_DIR"
sha256sum *.zip *.tar.gz > SHA256CHECKSUMS.txt
cd ..

echo ""
echo "✅ ✅ ✅ ALL PACKAGES CREATED SUCCESSFULLY! ✅ ✅ ✅"
echo ""
echo "📦 Packages created in: $RELEASE_DIR/"
echo ""
ls -lh "$RELEASE_DIR/"
echo ""
echo "📋 Package Details:"
echo "   Complete Package:     $SIZE_COMPLETE"
echo "   Backend Package:      $SIZE_BACKEND"
echo "   Frontend Package:     $SIZE_FRONTEND"
echo "   Documentation:        $SIZE_DOCS"
echo "   Source Code (tar.gz): $SIZE_SOURCE"
echo ""
echo "🚀 Next Steps:"
echo "1. Go to: https://github.com/gituser865/task-marketplace/releases"
echo "2. Click 'Create a new release'"
echo "3. Tag: v${VERSION}"
echo "4. Title: 🎉 Task Marketplace v${VERSION} - Complete Release"
echo "5. Upload all files from: $RELEASE_DIR/"
echo "6. Copy release notes from RELEASE_NOTES.md"
echo "7. Publish release"
echo ""
echo "✨ Done! Your release is ready for download."