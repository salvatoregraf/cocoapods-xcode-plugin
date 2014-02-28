//
//  CocoaPods.m
//
//  Copyright (c) 2014 Delisa Mason. http://delisa.me
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#import "CocoaPods.h"
#import "CCPShellHandler.h"
#import "CCPPreferences.h"
#import "CCPWorkspaceManager.h"
#import "CCPDocumentationManager.h"
#import "CCPProject.h"

static CocoaPods *sharedPlugin = nil;

@interface CocoaPods ()

@property (nonatomic, strong) NSMenuItem *installPodsItem;
@property (nonatomic, strong) NSMenuItem *updatePodsItem;
@property (nonatomic, strong) NSMenuItem *outdatedPodsItem;
@property (nonatomic, strong) NSMenuItem *installDocsItem;

@property (nonatomic, strong) NSBundle *bundle;

@end


@implementation CocoaPods

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    sharedPlugin = [[self alloc] initWithBundle:plugin];
	});
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
	if (self = [super init]) {
		_bundle = plugin;
		[self addMenuItems];
	}
	return self;
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem isEqual:self.installPodsItem]
        || [menuItem isEqual:self.outdatedPodsItem]
        || [menuItem isEqual:self.updatePodsItem]) {
        return [[CCPProject projectForKeyWindow] hasPodfile];
	}
    
	return YES;
}

- (void)addMenuItems
{
	NSMenuItem *topMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
	if (topMenuItem) {
		NSMenuItem *cocoaPodsMenu = [[NSMenuItem alloc] initWithTitle:@"CocoaPods" action:nil keyEquivalent:@""];
		cocoaPodsMenu.submenu = [[NSMenu alloc] initWithTitle:@"CocoaPods"];
        
		self.installDocsItem = [[NSMenuItem alloc] initWithTitle:@"Install Docs during Integration"
		                                                  action:@selector(toggleInstallDocsForPods)
		                                           keyEquivalent:@""];
		self.installDocsItem.state = [CCPPreferences shouldInstallDocsForPods] ? NSOnState : NSOffState;
        
		self.installPodsItem = [[NSMenuItem alloc] initWithTitle:@"Integrate Pods"
		                                                  action:@selector(integratePods)
		                                           keyEquivalent:@""];
        
		self.outdatedPodsItem = [[NSMenuItem alloc] initWithTitle:@"Check for Outdated Pods"
		                                                   action:@selector(checkForOutdatedPods)
		                                            keyEquivalent:@""];
        
		NSMenuItem *createPodfileItem = [[NSMenuItem alloc] initWithTitle:@"Create/Edit Podfile"
                                                                   action:@selector(createPodfile)
                                                            keyEquivalent:@""];

		self.updatePodsItem = [[NSMenuItem alloc] initWithTitle:@"Update installed pods"
                                                         action:@selector(updatePods)
                                                  keyEquivalent:@""];
        
		NSMenuItem *createPodspecItem = [[NSMenuItem alloc] initWithTitle:@"Create/Edit Podspec"
                                                                   action:@selector(createPodspecFile)
                                                            keyEquivalent:@""];

        NSMenuItem *searchPodsItem = [[NSMenuItem alloc] initWithTitle:@"Search Pods"
                                                                action:@selector(searchPods)
                                                         keyEquivalent:@""];
        
		[self.installDocsItem setTarget:self];
		[self.installPodsItem setTarget:self];
		[self.outdatedPodsItem setTarget:self];
		[self.updatePodsItem setTarget:self];
		[createPodfileItem setTarget:self];
		[createPodspecItem setTarget:self];
		[searchPodsItem setTarget:self];
        
		[[cocoaPodsMenu submenu] addItem:self.installPodsItem];
		[[cocoaPodsMenu submenu] addItem:self.outdatedPodsItem];
        [[cocoaPodsMenu submenu] addItem:self.updatePodsItem];
        [[cocoaPodsMenu submenu] addItem:[NSMenuItem separatorItem]];
		[[cocoaPodsMenu submenu] addItem:searchPodsItem];
        [[cocoaPodsMenu submenu] addItem:[NSMenuItem separatorItem]];
		[[cocoaPodsMenu submenu] addItem:createPodfileItem];
        [[cocoaPodsMenu submenu] addItem:createPodspecItem];
        [[cocoaPodsMenu submenu] addItem:[NSMenuItem separatorItem]];
		[[cocoaPodsMenu submenu] addItem:self.installDocsItem];
		[[topMenuItem submenu] insertItem:cocoaPodsMenu
                                  atIndex:[topMenuItem.submenu indexOfItemWithTitle:@"Build For"]];
	}
}

#pragma mark - Menu Actions

- (void)toggleInstallDocsForPods
{
	[CCPPreferences toggleShouldInstallDocsForPods];
    self.installDocsItem.state = [CCPPreferences shouldInstallDocsForPods] ? NSOnState : NSOffState;
}

- (void)createPodfile
{
    CCPProject *project = [CCPProject projectForKeyWindow];
    NSString *podFilePath = project.podfilePath;
    
	if (![project hasPodfile]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] copyItemAtPath:[self.bundle pathForResource:@"DefaultPodfile" ofType:@""] toPath:podFilePath error:&error];
		if (error) {
			[[NSAlert alertWithError:error] runModal];
		}
	}
    
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                     openFile:podFilePath];
}

- (void)createPodspecFile
{
    CCPProject *project = [CCPProject projectForKeyWindow];
    NSString *podspecPath = project.podspecPath;
    
	if (![project hasPodspecFile]) {
        NSString *podspecTemplate = [NSString stringWithContentsOfFile:[self.bundle pathForResource:@"DefaultPodspec" ofType:@""]
                                                              encoding:NSUTF8StringEncoding error:nil];
        
        [project createPodspecFromTemplate:podspecTemplate];
    }
    
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                     openFile:podspecPath];
}

- (void)integratePods
{
    [CCPShellHandler runPodWithArguments:@[@"install"]
                              completion:^(NSTask *task) {
                                  if ([CCPPreferences shouldInstallDocsForPods])
                                      [CCPDocumentationManager installOrUpdateDocumentationForPods];
                              }];
}

- (void)updatePods
{
    [CCPShellHandler runPodWithArguments:@[@"update"]
                              completion:^(NSTask *task) {
                                  if ([CCPPreferences shouldInstallDocsForPods])
                                      [CCPDocumentationManager installOrUpdateDocumentationForPods];
                              }];
}

- (void)checkForOutdatedPods
{
	[CCPShellHandler runPodWithArguments:@[@"outdated"] completion:nil];
}

- (void)searchPods
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Find a pod"
                                     defaultButton:@"Search"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input.cell setPlaceholderString:@"pod name/description"];
    [alert setAccessoryView:input];
    if ([alert runModal] == NSAlertDefaultReturn) {
        [input validateEditing];
        NSString * searchText = [input stringValue];
        if (searchText.length > 0) {
            [CCPShellHandler runPodWithArguments:@[@"search", @"--no-color", searchText]
                                      completion:nil];
        }
    }
}

@end
