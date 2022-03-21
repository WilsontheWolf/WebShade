#include <objc/runtime.h>
#include "WSPSiteListController.h"
// Special thanks to @LacertosusRepo @denialpan @AzzouDuGhetto @Galactic-Dev for this
// No way I could do this myself. 
// If your looking to do something similar yourself, trust me
// Turn away while you still can.

@implementation WSPSiteListController
	-(id)init {
		self = [super init];

		if(self) {
            [self loadData];
		}

		return self;
	}

	-(NSArray *)specifiers {
		if (!_specifiers) {
            [self loadSites];
		}

		return _specifiers;
	}

    -(void)loadSites {
        NSMutableArray *siteSpecifiers = [[NSMutableArray alloc] init];
        PSSpecifier *groupSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Custom Site Rules" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
        [groupSpecifier setProperty:@"Swipe to delete or rename sites." forKey:@"footerText"];
        [siteSpecifiers addObject:groupSpecifier];

        for(NSString *site in self.sites) {
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:site target:self set:nil get:nil detail:objc_getClass("WSPCustomSiteListController") cell:PSLinkCell edit:nil];
            [specifier setProperty:@YES forKey:@"enabled"];
            [self insertSpecifier:specifier atIndex:1 animated:YES];
            [siteSpecifiers addObject:specifier];
        }

        _specifiers = [siteSpecifiers copy];
    }

    -(void)loadData {
        NSString *path = @"/User/Library/Preferences/com.wilsonthewolf.webshadesites.plist";
        self.sites = [NSMutableDictionary dictionaryWithContentsOfFile:path] == nil ? [NSMutableDictionary dictionary] : [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }

	-(void)addSite {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"New Site Rule"
                                                                                    message: @"Please input what you want this to show as.\nNote: this is not the necessarily the name or the url of the site."
                                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Name";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }]];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSArray *textfields = alertController.textFields;
            UITextField *namefield = textfields[0];
            NSString *text = [namefield.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *error = nil;
            if(text.length == 0) {
                error = @"Please enter a name.";
            } else if([self.sites objectForKey:text]) {
                error = @"A site with that name already exists.";
            }
            if(error != nil) {
                UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Error"
                                                                                            message: error
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                [self presentViewController:alertController animated:YES completion:nil];
            } else {
                NSLog(@"[webshade-prefs] Site added: %@",text);
                PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:text target:self set:nil get:nil detail:objc_getClass("WSPCustomSiteListController") cell:PSLinkCell edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [self insertSpecifier:specifier atIndex:1 animated:YES];

                [self saveSites];
            }
        }];
        [alertController addAction:okAction];
        alertController.preferredAction = okAction;
        [self presentViewController:alertController animated:YES completion:nil];
	}

    - (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath { 
        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            PSSpecifier *specifierToBeRemoved = [self specifierAtIndexPath:indexPath];
			[self removeSpecifier:specifierToBeRemoved animated:YES];
            [self.sites removeObjectForKey:[specifierToBeRemoved name]];
            NSLog(@"[webshade-prefs] Site deleted: %@", [specifierToBeRemoved name]);
            NSLog(@"[webshade-prefs] self.sites: %@", self.sites);
            [self saveSites];
            completionHandler(YES);
        }];
        UIContextualAction *updateAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Rename" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Rename Site Rule"
                                                                                        message: @"Please input the new name."
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = [specifier name];
                textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            }];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSArray *textfields = alertController.textFields;
                UITextField *namefield = textfields[0];
                NSString *text = [namefield.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *error = nil;
                if(text.length == 0) {
                    error = @"Please enter a name.";
                } else if([self.sites objectForKey:text]) {
                    error = @"A site with that name already exists.";
                }
                if(error != nil) {
                    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Error"
                                                                                                message: error
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    }]];
                    [self presentViewController:alertController animated:YES completion:nil];
                } else {
                    NSLog(@"[webshade-prefs] Site updated: %@",text);
                    NSDictionary *site = [self.sites objectForKey:[specifier name]];
                    [self.sites setObject:site forKey:text]; 
                    [specifier setName:text];
                    [self reloadSpecifier:specifier];
                    [self saveSites];
                }
            }];
            [alertController addAction:okAction];
            alertController.preferredAction = okAction;
            [self presentViewController:alertController animated:YES completion:nil];
            completionHandler(YES);
        }];
        updateAction.backgroundColor = [UIColor systemYellowColor];
        
        UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, updateAction]];
        return config;
    };
    
	-(void)saveSites {
        NSString *path = @"/User/Library/Preferences/com.wilsonthewolf.webshadesites.plist";
        NSMutableDictionary *data =[NSMutableDictionary dictionary];

        for(PSSpecifier *specifier in _specifiers) {
            // Prevents the header explaining the value to be written.
            if([specifier cellType] != PSLinkCell) {
                continue;
            }
            NSString *name = [specifier name];
            NSLog(@"[webshade-prefs] Saving site: %@", name);
            if(!self.sites[name]) {
                [data setObject:@{} forKey:name];
            } else {
                [data setObject:self.sites[name] forKey:name];
            }
		}

        NSLog(@"[webshade-prefs] Saving sites: %@", data);
        [data writeToFile:path atomically:YES];
	}

	-(void)viewDidLoad {
		[super viewDidLoad];

		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSite)] animated:YES];
    }

	-(void)viewDidAppear:(BOOL)animated {
		[super viewDidAppear:animated];

        if(_specifiers) {
            [self loadData];
        }
	}
@end