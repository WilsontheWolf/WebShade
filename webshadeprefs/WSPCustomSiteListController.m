#include "WSPCustomSiteListController.h"

@implementation WSPCustomSiteListController

    - (NSArray *)specifiers {
        if (!_specifiers) {
            self.selectedSite = self.title;
            _specifiers = [self loadSpecifiersFromPlistName:@"Site" target:self];
            // Loading the plist makes the title blank.
            self.title = self.selectedSite;
        }
        return _specifiers;
    }

    - (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
        NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
        NSMutableDictionary *sites = [NSMutableDictionary dictionaryWithContentsOfFile:path] == nil ? [NSMutableDictionary dictionary] : [NSMutableDictionary dictionaryWithContentsOfFile:path];
        NSMutableDictionary *site = sites[self.selectedSite] == nil ? [NSMutableDictionary dictionary] : [NSMutableDictionary dictionaryWithDictionary:sites[self.selectedSite]];
        [site setObject:value forKey:specifier.properties[@"key"]];
        [sites setObject:site forKey:self.selectedSite];
        [sites writeToFile:path atomically:YES];
    }

    -(id)readPreferenceValue:(PSSpecifier *)specifier {
        return self.site[specifier.properties[@"key"]] ?: specifier.properties[@"default"];
    }

    -(void)viewDidLoad {
        [super viewDidLoad];
        
        NSString *path = @"/User/Library/Preferences/com.wilsonthewolf.webshadesites.plist";
        NSDictionary *sitePrefs = [NSDictionary dictionaryWithContentsOfFile:path] == nil ? [NSDictionary dictionary] : [NSDictionary dictionaryWithContentsOfFile:path];
        self.site = sitePrefs[self.selectedSite] == nil ? [NSMutableDictionary dictionary] : [sitePrefs[self.selectedSite] mutableCopy];
        NSLog(@"[webshadeprefs] Site loaded: %@", self.selectedSite);
    }

@end