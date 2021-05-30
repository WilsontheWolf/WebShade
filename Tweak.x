#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "Tweak.h"

%group Inject
    %hook WKWebView
    - (bool)_didCommitLoadForMainFrame {
        // NSDictionary *settings = [[NSUserDefaults standardUserDefaults]
        // persistentDomainForName:@"com.wilsonthewolf.webshadeprefs"];
        NSDictionary *settings = [NSDictionary 
        dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.wilsonthewolf.webshadeprefs.plist"];
        BOOL enabled = [[settings valueForKey:@"enabled"] == nil ? @"1" : [settings valueForKey:@"enabled"] boolValue];
        if(enabled) {
            BOOL followSystemTheme = [[settings valueForKey:@"followSystemTheme"] == nil ? @"1" : [settings valueForKey:@"followSystemTheme"] boolValue];
            if([UIDevice currentDevice].systemVersion.floatValue < 13) {
                followSystemTheme = false;
            }
            id brightness = @"100";
            id contrast = @"100";
            id grayscale = @"0";
            id sepia = @"0";

            if([[settings valueForKey:@"sliders"] == nil ? @"0" : [settings valueForKey:@"sliders"] boolValue]){
                NSLog(@"[webshade] non-Default sliders");
                brightness = [settings valueForKey:@"brightness"] == nil ? brightness : [settings valueForKey:@"brightness"];
                contrast = [settings valueForKey:@"contrast"] == nil ? contrast : [settings valueForKey:@"contrast"];
                grayscale = [settings valueForKey:@"grayscale"] == nil ? grayscale : [settings valueForKey:@"grayscale"];
                sepia = [settings valueForKey:@"sepia"] == nil ? sepia : [settings valueForKey:@"sepia"];
            }

            NSLog(@"[webshade]DarkReader.%@({brightness: %@,contrast: %@,grayscale: %@,sepia: %@})", 
            followSystemTheme ? @"auto" : @"enable",
            brightness, contrast, grayscale, sepia);
            [self evaluateJavaScript: [NSString stringWithFormat: @"%@\nDarkReader.%@({brightness: %@,contrast: %@,grayscale: %@,sepia: %@})", 
            kDarkReaderScript, 
            followSystemTheme ? @"auto" : @"enable",
            brightness, contrast, grayscale, sepia]
            completionHandler: nil];
        }
        return %orig;
    }
    %end
%end


%ctor {
    // This prevents us from injecting into springboard and making Xen HTML widgets dark mode.
    // Thanks to Galactic-Dev who I stole this from.
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    if(args.count != 0) {
        NSString *executablePath = args[0];
        if(executablePath) {      
            BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound 
            && [executablePath rangeOfString:@"Spotlight"].location == NSNotFound // Fix Spotlight dictionary glitches
            && [executablePath rangeOfString:@"Cydia"].location == NSNotFound; // Cydia crashes for some people and it doesn't even affect it at all.
            if(isApplication) {
               %init(Inject);
            } else {
                NSLog(@"[webshade] No injecty");
            }
        }
    }
}
