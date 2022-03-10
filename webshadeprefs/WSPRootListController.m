#include "WSPRootListController.h"

@implementation WSPRootListController

    - (NSArray *)specifiers {
        if (!_specifiers) {
            _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        }

        return _specifiers;
    }

    -(void)openGithub {
        [[UIApplication sharedApplication]
        openURL:[NSURL URLWithString:@"https://github.com/WilsontheWolf/WebShade"]
        options:@{}
        completionHandler:nil];
    }

@end
