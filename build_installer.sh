#!/bin/bash

# Exit on error
set -e

echo "Building ColdHarbor Screensaver Installer"
echo "----------------------------------------"

# Build the screensaver if it doesn't exist
if [ ! -d "build/ColdHarbor.saver" ]; then
    echo "Building screensaver..."
    make
fi

# Create installer directory structure
echo "Creating installer directory structure..."
mkdir -p installer/flat/root/tmp/ColdHarborInstall
mkdir -p installer/flat/resources
mkdir -p installer/flat/scripts
mkdir -p installer/flat/package

# Copy screensaver to installer location
echo "Copying screensaver to installer location..."
cp -R build/ColdHarbor.saver installer/flat/root/tmp/ColdHarborInstall/

# Copy resources and scripts
echo "Copying resources and scripts..."
cp -R installer/resources/* installer/flat/resources/
cp -R installer/scripts/* installer/flat/scripts/
chmod +x installer/flat/scripts/*

# Generate background image if it doesn't exist
if [ ! -f "installer/resources/background.png" ]; then
    echo "Creating background image..."
    # This uses a simple 'convert' command from ImageMagick if it's installed
    # If not, we just create a simple colored background
    if command -v convert &> /dev/null; then
        convert -size 600x400 gradient:black-darkblue \
                -gravity center \
                -pointsize 30 -fill white \
                -annotate 0 "ColdHarbor Screensaver" \
                installer/resources/background.png
    else
        # Create a placeholder file
        echo "ImageMagick not found, creating placeholder background."
        echo "<html><body style='background-color:#000033;'></body></html>" > installer/resources/background.html
        mv installer/resources/background.html installer/resources/background.png
    fi
fi

# Build component package
echo "Building component package..."
pkgbuild --root installer/flat/root \
         --scripts installer/flat/scripts \
         --identifier com.coldharbor.screensaver \
         --version 1.0 \
         --install-location / \
         installer/flat/package/ColdHarborScreensaver.pkg

# Build product archive
echo "Building product archive..."
productbuild --distribution installer/distribution.xml \
             --resources installer/flat/resources \
             --package-path installer/flat/package \
             ColdHarbor_Installer.pkg

echo "----------------------------------------"
echo "Installer created: ColdHarbor_Installer.pkg"
echo "To install, double-click on the package file."
echo ""
echo "To clean up build files: rm -rf installer/flat" 