# ColdHarbor Screensaver Installer

This directory contains files needed to build a macOS installer package for the ColdHarbor screensaver.

## Prerequisites

- Mac with macOS 10.13 or later
- Xcode Command Line Tools installed
- The screensaver must be built before creating the installer

## Directory Structure

```
installer/
├── scripts/
│   ├── preinstall     # Script to run before installation
│   └── postinstall    # Script to run after installation
├── resources/
│   ├── welcome.html   # Welcome screen
│   ├── conclusion.html # Conclusion screen
│   ├── license.txt    # License text
│   └── background.png # Background image for the installer
└── distribution.xml   # Distribution XML file
```

## Building the Installer

1. Make sure you have built the screensaver first:
   ```
   cd /path/to/coldharbor
   make
   ```

2. Create necessary directories:
   ```
   mkdir -p installer/flat/root/tmp/ColdHarborInstall
   mkdir -p installer/flat/resources
   mkdir -p installer/flat/scripts
   mkdir -p installer/flat/package
   ```

3. Copy the built screensaver to the installation location:
   ```
   cp -R build/ColdHarbor.saver installer/flat/root/tmp/ColdHarborInstall/
   ```

4. Copy resources and scripts:
   ```
   cp -R installer/resources/* installer/flat/resources/
   cp -R installer/scripts/* installer/flat/scripts/
   chmod +x installer/flat/scripts/*
   ```

5. Build the component package:
   ```
   pkgbuild --root installer/flat/root \
            --scripts installer/flat/scripts \
            --identifier com.coldharbor.screensaver \
            --version 1.0 \
            --install-location / \
            installer/flat/package/ColdHarborScreensaver.pkg
   ```

6. Build the product package:
   ```
   productbuild --distribution installer/distribution.xml \
                --resources installer/flat/resources \
                --package-path installer/flat/package \
                ColdHarbor_Installer.pkg
   ```

7. The final installer package will be `ColdHarbor_Installer.pkg` in the project root

## Using the Installer

Double-click the `ColdHarbor_Installer.pkg` file to run the installer. Follow the on-screen instructions to install the screensaver.

## Cleanup

After creating the installer, you can remove the temporary files:
```
rm -rf installer/flat
``` 