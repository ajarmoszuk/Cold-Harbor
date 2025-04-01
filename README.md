# ColdHarbor Screensaver

A macOS screensaver inspired by the TV show "Severance" displaying the text "hello ms. cobel" with animation effects that mimic the show's aesthetic.

## Features

- Authentic Severance-style animation with:
  - Letter-by-letter fade-in from right to left
  - Light blue ice glow effect on text
  - Text eventually sliding off to the left
  - Continuous animation cycle
- Black background with white glowing text
- Monospaced font similar to the show
- User customization options:
  - Custom message text
  - Adjustable animation speed
  - Text and glow color selection
  - Font selection

## Requirements

- macOS 10.13 or later
- Xcode Command Line Tools (if building from source)

## Build Instructions

1. Open Terminal and navigate to the project directory:
   ```
   cd path/to/ColdHarborScreenSaver
   ```

2. Build the screensaver:
   ```
   make
   ```

3. Install to your user's Screen Savers directory:
   ```
   make install
   ```

## Usage

1. Open System Preferences/System Settings
2. Go to "Desktop & Screen Saver"
3. Select the "Screen Saver" tab
4. Find and select "ColdHarbor" in the list of screensavers
5. Click the "Screen Saver Options..." button to customize:
   - Message text (default: "l o M s . C o b e l")
   - Animation speed
   - Text color
   - Glow color
   - Font selection

## Customization

You can customize the screensaver through the built-in options panel, or by editing the source:

To modify the screensaver in code, edit `ColdHarborView.m` and adjust:
- The default values at the top of the `initWithFrame:isPreview:` method
- The animation behavior in `animateOneFrame`
- The drawing style in `drawRect:`

After making changes, rebuild and reinstall using the instructions above.

## License

This project is for personal use only. 