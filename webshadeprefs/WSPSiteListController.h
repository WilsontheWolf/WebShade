#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>

@interface WSPSiteListController : PSListController
@property (nonatomic, retain) NSMutableDictionary *sites;
- (void)loadSites;
- (void)loadData;
@end
