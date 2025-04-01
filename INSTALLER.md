# ColdHarbor Screensaver Installer

This document explains how to build and use the installer for the ColdHarbor screensaver.

## Building the Installer

1. Make sure you have the Xcode Command Line Tools installed:
   ```
   xcode-select --install
   ```

2. Run the build script:
   ```
   ./build_installer.sh
   ```

3. This will create a file called `ColdHarbor_Installer.pkg` in the project root

## Using the Installer

1. Double-click on the `ColdHarbor_Installer.pkg` file
2. Follow the on-screen instructions
3. The screensaver will be installed to your user's Screen Savers directory

## After Installation

1. Open System Settings
2. Go to "Screen Saver" or "Desktop & Screen Saver"
3. Select "ColdHarbor" from the list of screensavers
4. Click "Screen Saver Options..." to customize your experience

## Troubleshooting

If you encounter any issues:

- Make sure you're running macOS 10.13 or later
- Check that you have sufficient permissions to install software
- Try rebuilding the screensaver with `make clean && make` before running the installer build script

## Uninstalling

To uninstall the screensaver, simply delete it from your Screen Savers folder:
```
rm -rf ~/Library/Screen\ Savers/ColdHarbor.saver
``` 