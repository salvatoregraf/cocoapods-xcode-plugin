//
//  CCPPreferences.m
//  CocoaPods
//
//  Created by Delisa Mason on 2/28/14.
//  Copyright (c) 2014 Delisa Mason. All rights reserved.
//

#import "CCPPreferences.h"

static NSString * const DMMCocoaPodsIntegrateWithDocsKey = @"DMMCocoaPodsIntegrateWithDocs";

@implementation CCPPreferences

#pragma mark - Preferences

+ (BOOL)shouldInstallDocsForPods
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DMMCocoaPodsIntegrateWithDocsKey];
}

+ (void)setShouldInstallDocsForPods:(BOOL)enabled
{
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:DMMCocoaPodsIntegrateWithDocsKey];
}

+ (void)toggleShouldInstallDocsForPods
{
  [self setShouldInstallDocsForPods:![self shouldInstallDocsForPods]];
}

@end
