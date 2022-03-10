#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface WSPCustomSiteListController : PSListController
    @property (strong, nonatomic) NSMutableDictionary *site;
    @property (strong, nonatomic) NSString *selectedSite;
@end
