#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "Tweak.h"

%group Inject
    %hook WKWebView
    - (bool)_didCommitLoadForMainFrame {
        NSLog(@"[webshade] Running on %@", self.URL.absoluteString);
        if (![self.URL.scheme isEqualToString:@"http"] && ![self.URL.scheme isEqualToString:@"https"]) {
            NSLog(@"[webshade] Not a web page, skipping");
            return %orig;
        }
        NSDictionary *settings = [NSDictionary 
        dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.wilsonthewolf.webshadeprefs.plist"];
        BOOL enabled = [[settings valueForKey:@"enabled"] == nil ? @"1" : [settings valueForKey:@"enabled"] boolValue];
        if(enabled) {
            NSDictionary *sites = [NSDictionary 
            dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.wilsonthewolf.webshadesites.plist"];
            NSDictionary *details = settings;
            for(NSString *site in sites) {
                NSDictionary *value = sites[site];
                NSString *match = value[@"websiteMatch"];
                if(match == nil) {
                    continue;
                }
                match = [match stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if([match isEqualToString:@""]) {
                    continue;
                }
                match = [match stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                if([self.URL.absoluteString containsString:match]) {
                   details = value;
                   NSLog(@"[webshade] Using ruleset from %@", site);
                   break;
                }
            }
            BOOL followSystemTheme = [[details valueForKey:@"followSystemTheme"] == nil ? @"1" : [details valueForKey:@"followSystemTheme"] boolValue];
            if([UIDevice currentDevice].systemVersion.floatValue < 13) {
                followSystemTheme = false;
            }
            NSNumber *engine = [details valueForKey:@"engine"] == nil ? @"0" : [details valueForKey:@"engine"];
            if (![engine isEqual: @2]) { // Not Off
                NSLog(@"[webshade] Engine: %@", engine);
                id brightness = @"100";
                id contrast = @"100";
                id grayscale = @"0";
                id sepia = @"0";
                id script = @"";
                if ([engine isEqual: @0]) { // Advanced (Dark reader)
                    script = [NSString stringWithFormat: @"%@\n%@", 
                        kDarkReaderScript, 
                        kDarkReaderRun];
                } else if ([engine isEqual: @1]) { // Basic
                    script = kBasicEngineRun;
                }
                if([[details valueForKey:@"sliders"] == nil ? @"0" : [details valueForKey:@"sliders"] boolValue]){
                    brightness = [details valueForKey:@"brightness"] == nil ? brightness : [details valueForKey:@"brightness"];
                    contrast = [details valueForKey:@"contrast"] == nil ? contrast : [details valueForKey:@"contrast"];
                    grayscale = [details valueForKey:@"grayscale"] == nil ? grayscale : [details valueForKey:@"grayscale"];
                    sepia = [details valueForKey:@"sepia"] == nil ? sepia : [details valueForKey:@"sepia"];
                }
                id jsOptions = [NSString stringWithFormat:@"{dynamic: %@, brightness: %@, contrast: %@, grayscale: %@, sepia: %@}", 
                followSystemTheme ? @"true" : @"false",
                brightness, contrast, grayscale, sepia];
                NSLog(@"[webshade] Options: %@", jsOptions);
                [self evaluateJavaScript: [NSString stringWithFormat:@"{\nconst options = %@;\n%@\n}", jsOptions, script]
                completionHandler: nil];
                NSLog(@"[webshade] Injected");
            } else {
                NSLog(@"[webshade] Engine off");
            }
        } else {
            NSLog(@"[webshade] Disabled");
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
                NSLog(@"[webshade] Not injecting");
            }
        }
    }
}
