#import <ScreenSaver/ScreenSaver.h>

typedef NS_ENUM(NSInteger, LetterState) {
    LetterStateOffscreenRight,
    LetterStateMovingToCenter,
    LetterStateCenterPause,
    LetterStateMovingLeft
};

@interface LetterInfo : NSObject
@property (nonatomic) NSPoint position;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) LetterState state;
@property (nonatomic) CGFloat targetX;
@property (nonatomic) NSTimeInterval stateStartTime;
@end

@implementation LetterInfo
@end

@interface ColdHarborView : ScreenSaverView

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSMutableArray<LetterInfo *> *letters;
@property (nonatomic, strong) NSFont *textFont;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *glowColor;
@property (nonatomic) NSTimeInterval lastTime;
@property (nonatomic) CGFloat animationSpeed;
@property (nonatomic) IBOutlet NSWindow *configSheet;
@property (nonatomic) IBOutlet NSTextField *messageField;
@property (nonatomic) IBOutlet NSSlider *speedSlider;
@property (nonatomic) IBOutlet NSColorWell *colorWell;
@property (nonatomic) IBOutlet NSColorWell *glowColorWell;
@property (nonatomic) IBOutlet NSPopUpButton *fontPopup;

- (IBAction)closeConfig:(id)sender;
- (IBAction)cancelConfig:(id)sender;

@end
