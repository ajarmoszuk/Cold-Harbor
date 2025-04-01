#import "ColdHarborView.h"
#import <CoreText/CoreText.h>

// Define preference keys
static NSString *MessageKey = @"Message";
static NSString *TextColorKey = @"TextColor";
static NSString *GlowColorKey = @"GlowColor";
static NSString *FontNameKey = @"FontName";
static NSString *SpeedKey = @"Speed";

// Define the file path for direct file storage
static NSString *getSettingsFilePath() {
    NSString *userDir = NSHomeDirectory();
    return [userDir stringByAppendingPathComponent:@".coldharbor_settings.plist"];
}

// Register and load the custom font
static void loadCustomFonts() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[ColdHarborView class]];
        NSString *fontPath = [bundle pathForResource:@"Orbitron-Regular" ofType:@"ttf"];
        
        if (fontPath) {
            // Register the font with the system
            CFURLRef fontURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)fontPath, kCFURLPOSIXPathStyle, false);
            CFErrorRef error = NULL;
            
            if (CTFontManagerRegisterFontsForURL(fontURL, kCTFontManagerScopeProcess, &error)) {
                NSLog(@"Successfully registered font: %@", fontPath);
            } else {
                NSLog(@"Failed to register font: %@, error: %@", fontPath, error);
                if (error) CFRelease(error);
            }
            
            if (fontURL) CFRelease(fontURL);
        } else {
            NSLog(@"Could not find font file in bundle: Orbitron-Regular.ttf");
        }
    });
}

@implementation ColdHarborView

// Save settings directly to a file to avoid cache issues
- (void)saveSettingsToFile:(NSDictionary *)settings {
    NSString *filePath = getSettingsFilePath();
    NSLog(@"Saving settings to file: %@", filePath);
    [settings writeToFile:filePath atomically:YES];
}

// Load settings directly from a file to avoid cache issues
- (NSDictionary *)loadSettingsFromFile {
    NSString *filePath = getSettingsFilePath();
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSLog(@"Loading settings from file: %@ - Got: %@", filePath, settings);
    return settings ?: @{};
}

// Helper method to get preferences consistently
- (ScreenSaverDefaults *)getDefaults {
    // Use bundle identifier instead of hardcoded name
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *identifier = [bundle bundleIdentifier];
    NSLog(@"Using preferences identifier: %@", identifier);
    return [ScreenSaverDefaults defaultsForModuleWithName:identifier];
}

// Save the message to a direct file
- (void)saveMessageToDefaults:(NSString *)message {
    // Get existing settings or create new dictionary
    NSMutableDictionary *settings = [[self loadSettingsFromFile] mutableCopy];
    
    // Update message
    settings[MessageKey] = message;
    
    // Save to file
    [self saveSettingsToFile:settings];
    
    // Also try normal defaults as fallback
    ScreenSaverDefaults *defaults = [self getDefaults];
    [defaults setObject:message forKey:MessageKey];
    [defaults synchronize];
    
    NSLog(@"Saved message '%@' to file and preferences", message);
}

// Load message from direct file with fallback
- (NSString *)loadMessageFromDefaults {
    // Try to load from direct file first
    NSDictionary *settings = [self loadSettingsFromFile];
    NSString *message = settings[MessageKey];
    
    // If nothing in file, try preferences
    if (!message || message.length == 0) {
        ScreenSaverDefaults *defaults = [self getDefaults];
        message = [defaults stringForKey:MessageKey];
        NSLog(@"Falling back to ScreenSaverDefaults, got: '%@'", message);
    }
    
    // Final fallback to default value
    if (!message || message.length == 0) {
        message = @"C o l d  H a r b o r";
        NSLog(@"No saved message found, using default: '%@'", message);
    }
    
    return message;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/60.0];
        
        // Load custom fonts
        loadCustomFonts();
        
        // Defaults if no preferences exist
        NSString *defaultMessage = @"C o l d  H a r b o r";
        NSColor *defaultTextColor = [NSColor whiteColor];
        NSColor *defaultGlowColor = [NSColor colorWithCalibratedRed:0.6 green:0.9 blue:1.0 alpha:0.8];
        NSString *defaultFontName = @"Orbitron-Regular";
        CGFloat defaultSpeed = 1.5;
        
        // Log whether we're in preview mode
        NSLog(@"ColdHarbor initializing with isPreview = %@", isPreview ? @"YES" : @"NO");
        
        // Load all settings from file first
        NSDictionary *fileSettings = [self loadSettingsFromFile];
        
        // Load user preferences as fallback
        ScreenSaverDefaults *defaults = [self getDefaults];
        
        // Register defaults
        [defaults registerDefaults:@{
            MessageKey: defaultMessage,
            TextColorKey: [NSKeyedArchiver archivedDataWithRootObject:defaultTextColor requiringSecureCoding:NO error:nil],
            GlowColorKey: [NSKeyedArchiver archivedDataWithRootObject:defaultGlowColor requiringSecureCoding:NO error:nil],
            FontNameKey: defaultFontName,
            SpeedKey: @(defaultSpeed)
        }];
        
        // Initialize properties from file first, then fallback to defaults
        
        // Message
        _message = fileSettings[MessageKey];
        if (!_message) {
            _message = [self loadMessageFromDefaults]; // This has its own fallback chain
        }
        NSLog(@"Loaded message: '%@'", _message);
        
        // Text color
        NSData *textColorData = fileSettings[TextColorKey];
        if (!textColorData) {
            textColorData = [defaults objectForKey:TextColorKey];
        }
        _textColor = textColorData ? [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:textColorData error:nil] : defaultTextColor;
        
        // Glow color
        NSData *glowColorData = fileSettings[GlowColorKey];
        if (!glowColorData) {
            glowColorData = [defaults objectForKey:GlowColorKey];
        }
        _glowColor = glowColorData ? [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:glowColorData error:nil] : defaultGlowColor;
        
        // Font
        NSString *fontName = fileSettings[FontNameKey];
        if (!fontName) {
            fontName = [defaults stringForKey:FontNameKey];
        }
        _textFont = [NSFont fontWithName:fontName size:42.0];
        if (!_textFont) {
            _textFont = [NSFont monospacedSystemFontOfSize:42.0 weight:NSFontWeightLight];
        }
        
        // Speed
        NSNumber *speedNumber = fileSettings[SpeedKey];
        if (speedNumber) {
            _animationSpeed = [speedNumber floatValue];
        } else {
            _animationSpeed = [defaults floatForKey:SpeedKey];
        }
        
        _letters = [NSMutableArray array];
        _lastTime = [NSDate timeIntervalSinceReferenceDate];
        
        [self setupLetters];
    }
    return self;
}

- (void)setupLetters {
    [_letters removeAllObjects];
    
    // Debug: Log the current message
    NSLog(@"Setting up letters with message: '%@'", _message);
    
    // Force reload the message from defaults each time
    _message = [self loadMessageFromDefaults];
    NSLog(@"Reloaded message from defaults with fallback: '%@'", _message);
    
    CGFloat screenWidth = NSWidth(self.bounds);
    CGFloat screenHeight = NSHeight(self.bounds);
    CGFloat centerY = screenHeight / 2;
    
    // Calculate space needed for centered text
    CGFloat letterSpacing = 25.0;
    CGFloat totalWidth = _message.length * letterSpacing;
    CGFloat startX = (screenWidth - totalWidth) / 2;
    
    // Start time is staggered for each letter
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    for (NSInteger i = 0; i < _message.length; i++) {
        LetterInfo *letter = [[LetterInfo alloc] init];
        
        // Initial position is off-screen to the right
        letter.position = NSMakePoint(screenWidth + 100 + (i * 30), centerY);
        letter.alpha = 0.0;
        letter.state = LetterStateOffscreenRight;
        
        // Target position in center
        letter.targetX = startX + (i * letterSpacing);
        
        // Stagger start times so letters animate in sequence
        letter.stateStartTime = now + (i * 0.15);
        
        [_letters addObject:letter];
    }
}

- (void)startAnimation {
    [super startAnimation];
    
    // Load all settings from file
    NSDictionary *fileSettings = [self loadSettingsFromFile];
    
    // Reload preferences as fallback
    ScreenSaverDefaults *defaults = [self getDefaults];
    
    // Message with fallback chain
    _message = fileSettings[MessageKey];
    if (!_message) {
        _message = [self loadMessageFromDefaults];
    }
    
    // Text color
    NSData *textColorData = fileSettings[TextColorKey];
    if (!textColorData) {
        textColorData = [defaults objectForKey:TextColorKey];
    }
    _textColor = textColorData ? [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:textColorData error:nil] : [NSColor whiteColor];
    
    // Glow color
    NSData *glowColorData = fileSettings[GlowColorKey];
    if (!glowColorData) {
        glowColorData = [defaults objectForKey:GlowColorKey];
    }
    _glowColor = glowColorData ? [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:glowColorData error:nil] : [NSColor colorWithCalibratedRed:0.6 green:0.9 blue:1.0 alpha:0.8];
    
    // Font
    NSString *fontName = fileSettings[FontNameKey];
    if (!fontName) {
        fontName = [defaults stringForKey:FontNameKey];
    }
    _textFont = [NSFont fontWithName:fontName size:42.0];
    if (!_textFont) {
        _textFont = [NSFont monospacedSystemFontOfSize:42.0 weight:NSFontWeightLight];
    }
    
    // Speed
    NSNumber *speedNumber = fileSettings[SpeedKey];
    if (speedNumber) {
        _animationSpeed = [speedNumber floatValue];
    } else {
        _animationSpeed = [defaults floatForKey:SpeedKey];
    }
    
    NSLog(@"Animation starting with message: '%@'", _message);
    
    [self setupLetters];
}

- (void)animateOneFrame {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval deltaTime = now - _lastTime;
    _lastTime = now;
    
    // Periodically check for preference changes (roughly every 2 seconds)
    static NSTimeInterval lastCheckTime = 0;
    if (now - lastCheckTime > 1.0) {
        // Check file-based settings first
        NSDictionary *fileSettings = [self loadSettingsFromFile];
        NSString *savedMessage = fileSettings[MessageKey];
        
        // If no file settings, try defaults
        if (!savedMessage) {
            savedMessage = [self loadMessageFromDefaults];
        }
        
        // If the message has changed, update and restart animation
        if (savedMessage && ![_message isEqualToString:savedMessage]) {
            NSLog(@"Message changed from '%@' to '%@'", _message, savedMessage);
            _message = savedMessage;
            [self setupLetters];
        }
        
        lastCheckTime = now;
    }
    
    BOOL allOffscreen = YES;
    
    // Update each letter's state and position
    for (NSInteger i = 0; i < _letters.count; i++) {
        LetterInfo *letter = _letters[i];
        NSTimeInterval timeInState = now - letter.stateStartTime;
        
        switch (letter.state) {
            case LetterStateOffscreenRight:
                // Wait for this letter's turn to animate
                if (timeInState >= 0) {
                    letter.state = LetterStateMovingToCenter;
                    letter.stateStartTime = now;
                }
                allOffscreen = NO;
                break;
                
            case LetterStateMovingToCenter:
                // Fade in and move toward center
                {
                    // Increase alpha
                    letter.alpha = MIN(1.0, timeInState * 2.0);
                    
                    // Move toward target position
                    CGFloat moveSpeed = 300.0 * deltaTime * _animationSpeed; // Apply animation speed
                    CGFloat distToTarget = letter.targetX - letter.position.x;
                    CGFloat moveAmount = MIN(fabs(distToTarget), moveSpeed);
                    if (distToTarget < 0) moveAmount = -moveAmount;
                    
                    letter.position = NSMakePoint(letter.position.x + moveAmount, letter.position.y);
                    
                    // Check if at target position
                    if (fabs(letter.position.x - letter.targetX) < 1.0) {
                        letter.position = NSMakePoint(letter.targetX, letter.position.y);
                        
                        // If this is the last letter and it reached the center
                        if (i == _letters.count - 1) {
                            letter.state = LetterStateCenterPause;
                            letter.stateStartTime = now;
                            
                            // Also transition all other letters to pause state
                            for (NSInteger j = 0; j < i; j++) {
                                LetterInfo *prevLetter = _letters[j];
                                prevLetter.state = LetterStateCenterPause;
                                prevLetter.stateStartTime = now;
                            }
                        }
                    }
                    
                    allOffscreen = NO;
                }
                break;
                
            case LetterStateCenterPause:
                // Hold in center for a moment
                if (timeInState >= 1.0) {
                    letter.state = LetterStateMovingLeft;
                    letter.stateStartTime = now;
                }
                allOffscreen = NO;
                break;
                
            case LetterStateMovingLeft:
                // Move left off screen
                {
                    // Calculate how far we've moved left
                    CGFloat progress = timeInState * 1.5 * _animationSpeed; // Apply animation speed
                    
                    // Accelerating movement to the left
                    CGFloat distance = progress * progress * 500.0;
                    letter.position = NSMakePoint(letter.targetX - distance, letter.position.y);
                    
                    // Check if off screen
                    if (letter.position.x < -50) {
                        letter.alpha = 0;
                    } else {
                        allOffscreen = NO;
                    }
                }
                break;
        }
    }
    
    // If all letters are off screen, reset the animation
    if (allOffscreen) {
        [self setupLetters];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    
    // Fill background with black
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
    
    // Draw each letter
    for (NSInteger i = 0; i < _letters.count; i++) {
        LetterInfo *letterInfo = _letters[i];
        
        if (letterInfo.alpha > 0) {
            // Get the character to draw
            NSString *letter = [_message substringWithRange:NSMakeRange(i, 1)];
            
            // Create shadow for blue glow effect
            NSShadow *shadow = [[NSShadow alloc] init];
            [shadow setShadowColor:[_glowColor colorWithAlphaComponent:letterInfo.alpha * 0.8]];
            [shadow setShadowBlurRadius:10.0];
            [shadow setShadowOffset:NSMakeSize(0, 0)];
            
            // Set up text attributes
            NSDictionary *attributes = @{
                NSFontAttributeName: _textFont,
                NSForegroundColorAttributeName: [_textColor colorWithAlphaComponent:letterInfo.alpha],
                NSShadowAttributeName: shadow
            };
            
            // Draw the letter
            [letter drawAtPoint:letterInfo.position withAttributes:attributes];
        }
    }
}

#pragma mark - Configuration Sheet

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSWindow*)configureSheet {
    if (!_configSheet) {
        // Create the config window programmatically
        _configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 270)
                                                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
        [_configSheet setTitle:@"ColdHarbor Settings"];
        
        NSView *contentView = [_configSheet contentView];
        
        // Create message label and field
        NSTextField *messageLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 230, 80, 24)];
        [messageLabel setBezeled:NO];
        [messageLabel setDrawsBackground:NO];
        [messageLabel setEditable:NO];
        [messageLabel setSelectable:NO];
        [messageLabel setStringValue:@"Message:"];
        [contentView addSubview:messageLabel];
        
        _messageField = [[NSTextField alloc] initWithFrame:NSMakeRect(100, 230, 280, 24)];
        [_messageField setStringValue:_message];
        [contentView addSubview:_messageField];
        
        // Create speed label and slider
        NSTextField *speedLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 190, 80, 24)];
        [speedLabel setBezeled:NO];
        [speedLabel setDrawsBackground:NO];
        [speedLabel setEditable:NO];
        [speedLabel setSelectable:NO];
        [speedLabel setStringValue:@"Speed:"];
        [contentView addSubview:speedLabel];
        
        _speedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(100, 190, 280, 24)];
        [_speedSlider setMinValue:0.5];
        [_speedSlider setMaxValue:3.0];
        [_speedSlider setDoubleValue:_animationSpeed];
        [contentView addSubview:_speedSlider];
        
        // Create color labels and wells
        NSTextField *colorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 150, 80, 24)];
        [colorLabel setBezeled:NO];
        [colorLabel setDrawsBackground:NO];
        [colorLabel setEditable:NO];
        [colorLabel setSelectable:NO];
        [colorLabel setStringValue:@"Text Color:"];
        [contentView addSubview:colorLabel];
        
        _colorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(100, 150, 50, 24)];
        [_colorWell setColor:_textColor];
        [contentView addSubview:_colorWell];
        
        NSTextField *glowLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(170, 150, 80, 24)];
        [glowLabel setBezeled:NO];
        [glowLabel setDrawsBackground:NO];
        [glowLabel setEditable:NO];
        [glowLabel setSelectable:NO];
        [glowLabel setStringValue:@"Glow Color:"];
        [contentView addSubview:glowLabel];
        
        _glowColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(250, 150, 50, 24)];
        [_glowColorWell setColor:_glowColor];
        [contentView addSubview:_glowColorWell];
        
        // Create font label and popup
        NSTextField *fontLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 110, 80, 24)];
        [fontLabel setBezeled:NO];
        [fontLabel setDrawsBackground:NO];
        [fontLabel setEditable:NO];
        [fontLabel setSelectable:NO];
        [fontLabel setStringValue:@"Font:"];
        [contentView addSubview:fontLabel];
        
        _fontPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(100, 110, 280, 24)];
        [_fontPopup addItemWithTitle:@"Orbitron-Regular"];
        [_fontPopup addItemWithTitle:@"Courier"];
        [_fontPopup addItemWithTitle:@"Menlo"];
        [_fontPopup addItemWithTitle:@"Monaco"];
        [_fontPopup addItemWithTitle:@"SF Mono"];
        
        // Try to select the current font
        NSInteger index = [_fontPopup indexOfItemWithTitle:_textFont.fontName];
        if (index != -1) {
            [_fontPopup selectItemAtIndex:index];
        } else {
            // If the font wasn't found in the popup, default to Orbitron
            [_fontPopup selectItemWithTitle:@"Orbitron-Regular"];
        }
        
        [contentView addSubview:_fontPopup];
        
        // Create buttons
        NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(290, 20, 90, 32)];
        [okButton setBezelStyle:NSBezelStyleRounded];
        [okButton setButtonType:NSButtonTypeMomentaryPushIn];
        [okButton setTitle:@"OK"];
        [okButton setTarget:self];
        [okButton setAction:@selector(closeConfig:)];
        [okButton setKeyEquivalent:@"\r"];
        [contentView addSubview:okButton];
        
        NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(190, 20, 90, 32)];
        [cancelButton setBezelStyle:NSBezelStyleRounded];
        [cancelButton setButtonType:NSButtonTypeMomentaryPushIn];
        [cancelButton setTitle:@"Cancel"];
        [cancelButton setTarget:self];
        [cancelButton setAction:@selector(cancelConfig:)];
        [cancelButton setKeyEquivalent:@"\033"];
        [contentView addSubview:cancelButton];
    }
    
    return _configSheet;
}

- (IBAction)closeConfig:(id)sender {
    // Get values from UI
    NSString *newMessage = [_messageField stringValue];
    NSLog(@"Message from text field: '%@'", newMessage);
    
    if (newMessage.length == 0) {
        newMessage = @"C o l d  H a r b o r"; // Default if empty
    }
    
    NSColor *newTextColor = [_colorWell color];
    NSColor *newGlowColor = [_glowColorWell color];
    CGFloat newSpeed = [_speedSlider doubleValue];
    NSString *newFontName = [[_fontPopup selectedItem] title];
    
    // Create settings dictionary with all values
    NSMutableDictionary *settings = [[self loadSettingsFromFile] mutableCopy];
    settings[MessageKey] = newMessage;
    settings[TextColorKey] = [NSKeyedArchiver archivedDataWithRootObject:newTextColor requiringSecureCoding:NO error:nil];
    settings[GlowColorKey] = [NSKeyedArchiver archivedDataWithRootObject:newGlowColor requiringSecureCoding:NO error:nil];
    settings[FontNameKey] = newFontName;
    settings[SpeedKey] = @(newSpeed);
    
    // Save all settings to file
    [self saveSettingsToFile:settings];
    
    // Also save to normal defaults as fallback
    ScreenSaverDefaults *defaults = [self getDefaults];
    [defaults setObject:newMessage forKey:MessageKey];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:newTextColor requiringSecureCoding:NO error:nil] forKey:TextColorKey];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:newGlowColor requiringSecureCoding:NO error:nil] forKey:GlowColorKey];
    [defaults setObject:newFontName forKey:FontNameKey];
    [defaults setFloat:newSpeed forKey:SpeedKey];
    [defaults synchronize];
    
    // Update our properties
    _message = newMessage;
    _textColor = newTextColor;
    _glowColor = newGlowColor;
    _animationSpeed = newSpeed;
    _textFont = [NSFont fontWithName:newFontName size:42.0];
    if (!_textFont) {
        _textFont = [NSFont monospacedSystemFontOfSize:42.0 weight:NSFontWeightLight];
    }
    
    // Reset the animation with new settings
    [self setupLetters];
    
    // Close the sheet properly using the document property
    if ([[NSApplication sharedApplication] respondsToSelector:@selector(endSheet:returnCode:)]) {
        [[NSApplication sharedApplication] endSheet:_configSheet returnCode:NSModalResponseOK];
    } else {
        [NSApp endSheet:_configSheet returnCode:NSModalResponseOK];
    }
    [_configSheet orderOut:nil];
}

- (IBAction)cancelConfig:(id)sender {
    // Just close the sheet without saving
    if ([[NSApplication sharedApplication] respondsToSelector:@selector(endSheet:returnCode:)]) {
        [[NSApplication sharedApplication] endSheet:_configSheet returnCode:NSModalResponseCancel];
    } else {
        [NSApp endSheet:_configSheet returnCode:NSModalResponseCancel];
    }
    [_configSheet orderOut:nil];
}

@end
