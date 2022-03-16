#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

%group Inject
    #import "Tweak.h"

    @interface WSHelperObject:NSObject <WKScriptMessageHandler> {
        NSString *key;
    }
    @end

    @implementation WSHelperObject

    -(id)init {
        self = [super init];
        key = [[NSProcessInfo processInfo] globallyUniqueString];
        return self;
    }

    -(void) injectIntoController:(WKUserContentController *)controller {
        NSLog(@"[webshade-fetch] Injecting into controller");
        [controller addScriptMessageHandler:self name:@"WebShadeCorsFetch"];
    }

    -(void) informChild:(NSString *)id fromView:(WKWebView *)webView withResponse:(NSString *)message ofType:(NSString *)type {
        NSString *js = [NSString stringWithFormat:@"window.webkit.WebShadeCorsFetchResponse({id: '%@', message: '%@', type: '%@'});", id, message, type];
        [webView evaluateJavaScript:js completionHandler:nil];
    }

    -(NSString*) getKey {
        return key;
    }

    -(void) resetKey {
        key = [[NSProcessInfo processInfo] globallyUniqueString];
    }

    // This function is used to bypass cors and other stuff 
    // for the advanced/dark reader engine. Now, obviously 
    // this is delicate stuff and could have security
    // issues. As such I've taken the time to implement
    // as many precautions as possible, as well as 
    // explain them here. If you have any issues with
    // how I did this or found an exploit *please* contact
    // me either through github issues or on discord at
    // WilsontheWolf#0074,
    // 
    // Firstly we'll talk about the obj-c side. The 
    // following are in place.
    // - A randomly generated key is required to make 
    //   requests. This prevents any sites from making
    //   requests at will. This key is per-process and
    //   reset on process load making it very hard to guess
    // - The ability to turn it off is available. This
    //   disables anyone from using this method, in the
    //   case the user is not conformable with this.
    // Next we'll talk about the JS side.
    // - The token, all injected scripts and functions 
    //   are injected into their own scope, preventing
    //   malicious sites from using fetch or reading
    //   the token,
    // - The script generates a random id when making
    //   requests to prevent malicious sites from imitating
    //   WebShade.
    // - The script attempts to check if the function has 
    //   been replaced, and if it has it falls back to fetch.
    //   This prevents malicious sites from stealing the token.
    // If you would like to see the js side of this checkout
    // the file advanced-engine.js.
    - (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
        NSDictionary *messageBody = message.body;
        NSString *id = messageBody[@"id"];
        if(!id) {
            return;
        }
        NSDictionary *settings = [NSDictionary 
        dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.wilsonthewolf.webshadeprefs.plist"];
        BOOL enabled = [[settings valueForKey:@"enabled"] == nil ? @"1" : [settings valueForKey:@"enabled"] boolValue];
        if(!enabled) {
            NSLog(@"[webshade-fetch] WebShade is disabled but a request was made!");
            [self informChild:id fromView:message.webView withResponse:@"disabled" ofType:@"error"];
            return;
        }
        BOOL canUseFetch = [[settings valueForKey:@"allowFetch"] == nil ? @"1" : [settings valueForKey:@"allowFetch"] boolValue];
        if(!canUseFetch) {
            NSLog(@"[webshade-fetch] Fetching is disabled but a request was made!");
            [self informChild:id fromView:message.webView withResponse:@"access denied" ofType:@"error"];
            return;
        }
        NSString *token = messageBody[@"token"];
        if([token isEqualToString:key]) {
            NSString *url = messageBody[@"url"];
            NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];

            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

            [urlRequest setHTTPMethod:@"GET"];

            __block BOOL done = NO;
            NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if(error) {
                    NSLog(@"[webshade-fetch] error %@", error);
                    NSLog(@"[webshade-fetch] error %@", url);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self informChild:id fromView: [message webView] withResponse:[error localizedDescription] ofType:@"error"];
                    });
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self informChild:id fromView: [message webView] withResponse:[data base64EncodedStringWithOptions:0] ofType:@"data"];
                    });
                }
                done = YES;
            }];
            [dataTask resume];

            while (!done) {
                NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:0.1];
                [[NSRunLoop currentRunLoop] runUntilDate:date];
            }
        } else {
            NSLog(@"[webshade-fetch] invalid token: %@", token);
            [self informChild:id fromView: [message webView] withResponse:@"access denied" ofType:@"error"];
        }
    }
    @end

    static WSHelperObject *helper = nil;

    %hook WKWebView

    %property (nonatomic, strong) WSHelperObject *WSHelperObject;

    - (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
        if(!configuration) {
            configuration = [[WKWebViewConfiguration alloc] init];
        }
        if(!configuration.userContentController) {
            configuration.userContentController = [[WKUserContentController alloc] init];
        }
        if(!helper) {
            helper = [WSHelperObject new];
            [helper injectIntoController:configuration.userContentController];
        }
        return %orig;
    };     
    
    - (bool)_didCommitLoadForMainFrame {
        NSLog(@"[webshade-core] Running on %@", self.URL.absoluteString);
        if (![self.URL.scheme isEqualToString:@"http"] && ![self.URL.scheme isEqualToString:@"https"]) {
            NSLog(@"[webshade-core] Not a web page, skipping");
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
                NSString *matchString = value[@"websiteMatch"];
                if(matchString == nil) {
                    continue;
                }
                NSArray *matchArray = [matchString componentsSeparatedByString:@"|"];
                NSString *finalMatch = nil; 
                for(NSString *matchInfo in matchArray) {
                    NSString *match = [matchInfo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if([match isEqualToString:@""]) {
                        continue;
                    }
                    match = [match stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    if([self.URL.absoluteString containsString:match]) {
                        finalMatch = match;
                        break;
                    }
                }
                if(finalMatch == nil) {
                    continue;
                }
                details = value;
                NSLog(@"[webshade-core] Using ruleset from %@. Matched %@", site, finalMatch);
                break;
            }
            BOOL canUseFetch = [[settings valueForKey:@"allowFetch"] == nil ? @"1" : [settings valueForKey:@"allowFetch"] boolValue];
            NSNumber *engine = [details valueForKey:@"engine"] == nil ? @0 : [details valueForKey:@"engine"];
            if (![engine isEqual: @2]) { // Not Off
                NSLog(@"[webshade-core] Engine: %@", engine);
                NSString *brightness = @"100";
                NSString *contrast = @"100";
                NSString *grayscale = @"0";
                NSString *sepia = @"0";
                NSString *script = @"";
                BOOL followSystemTheme = [[details valueForKey:@"followSystemTheme"] == nil ? @"1" : [details valueForKey:@"followSystemTheme"] boolValue];
                BOOL oled = [[details valueForKey:@"oled"] == nil ? @"0" : [details valueForKey:@"oled"] boolValue];
                if([UIDevice currentDevice].systemVersion.floatValue < 13) {
                    followSystemTheme = false;
                }
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
                NSString *jsOptions = [NSString stringWithFormat:@"{dynamic: %@, brightness: %@, contrast: %@, grayscale: %@, sepia: %@, OLED: %@}", 
                followSystemTheme ? @"true" : @"false",
                brightness, contrast, grayscale, sepia, oled ? @"true" : @"false"];
                NSLog(@"[webshade-core] Options: %@", jsOptions);
                NSLog(@"[webshade-core] Can use webshade-fetch: %d", (int)canUseFetch);
                [self evaluateJavaScript: [NSString stringWithFormat:@"{\nconst options = %@;\nconst wsToken = '%@';\n%@\n}", jsOptions, canUseFetch ? [helper getKey] : @"", script]
                completionHandler: nil];
                NSLog(@"[webshade-core] Injected");
            } else {
                NSLog(@"[webshade-core] Engine off");
            }
        } else {
            NSLog(@"[webshade-core] Disabled");
        }
        return %orig;
    }
    %end
%end


// methods of getting executablePath and bundleIdentifier with the least side effects possible
// for more information, check out https://github.com/checkra1n/BugTracker/issues/343
// Thanks to @opa334dev for this https://github.com/opa334/Choicy/blob/master/Tweak.x#L37-L58
extern char*** _NSGetArgv();
NSString* safe_getExecutablePath()
{
	char* executablePathC = **_NSGetArgv();
	return [NSString stringWithUTF8String:executablePathC];
}

%ctor {
    // This prevents us from injecting into springboard and making Xen HTML widgets dark mode.
    // Thanks to Galactic-Dev who I stole this from.
    NSString *executablePath = safe_getExecutablePath();
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
