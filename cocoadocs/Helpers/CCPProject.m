//
//  CCPWorkspace.m
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

#import <objc/runtime.h>

#import "CCPProject.h"
#import "CocoaPods.h"
#import "CCPWorkspaceManager.h"

@implementation CCPProject

+ (instancetype)projectForKeyWindow
{
	id workspace = [CCPWorkspaceManager workspaceForKeyWindow];

	id contextManager = [workspace valueForKey:@"_runContextManager"];
	for (id scheme in[contextManager valueForKey:@"runContexts"]) {
		NSString *schemeName = [scheme valueForKey:@"name"];
		if (![schemeName hasPrefix:@"Pods-"]) {
            NSString *path = [CCPWorkspaceManager directoryPathForWorkspace:workspace];
			return [[CCPProject alloc] initWithName:schemeName path:path];
		}
	}

	return nil;
}

- (id)initWithName:(NSString *)name path:(NSString *)path
{
	if (self = [super init]) {
		_projectName = name;
        NSString * podspecRelativePath = [NSString stringWithFormat:@"../%@", [name stringByAppendingString:@".podspec"]];
		_podspecPath   = [path stringByAppendingPathComponent:podspecRelativePath];
		_directoryPath = path;

		NSString *infoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@-Info.plist", _projectName, _projectName]];

		_infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPath];
		_podfilePath = [path stringByAppendingPathComponent:@"Podfile"];
	}

	return self;
}

- (BOOL)containsFileWithName:(NSString *)fileName
{
	NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
	return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

#pragma mark - Podfile

- (BOOL)hasPodfile
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.podfilePath];
}

- (void)createOrEditPodfile
{
	if (![self hasPodfile]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] copyItemAtPath:[[CocoaPods sharedPlugin].bundle pathForResource:@"DefaultPodfile" ofType:@""] toPath:self.podfilePath error:&error];
		if (error) {
			[[NSAlert alertWithError:error] runModal];
		}
	}

  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                   openFile:self.podfilePath];
}

#pragma mark - Podspec

- (BOOL)hasPodspec
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.podspecPath];
}

- (void)createOrEditPodspec
{
	if (![self hasPodspec]) {
    NSString *podspecTemplate = [NSString stringWithContentsOfFile:[[CocoaPods sharedPlugin].bundle pathForResource:@"DefaultPodspec" ofType:@""]
                                                          encoding:NSUTF8StringEncoding error:nil];

    [self createPodspecFromTemplate:podspecTemplate];
  }

  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                   openFile:self.podspecPath];
}

- (void)createPodspecFromTemplate:(NSString *)template
{
	NSMutableString *podspecFile    = template.mutableCopy;
	NSRange range; range.location = 0;

	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@"<Project Name>"
	                             withString:self.projectName
	                                options:NSLiteralSearch
	                                  range:range];

	NSString *version = self.infoDictionary[@"CFBundleShortVersionString"];
	if (version) {
		range.length = podspecFile.length;
		[podspecFile replaceOccurrencesOfString:@"<Project Version>"
		                             withString:version
		                                options:NSLiteralSearch
		                                  range:range];
	}

	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@"'<"
	                             withString:@"'<#"
	                                options:NSLiteralSearch
	                                  range:range];

	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@">'"
	                             withString:@"#>'"
	                                options:NSLiteralSearch
	                                  range:range];

	// Reading dependencies
	NSString *podfileContent    = [NSString stringWithContentsOfFile:self.podfilePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *fileLines          = [podfileContent componentsSeparatedByString:@"\n"];

	for (NSString *tmp in fileLines) {
		NSString *line = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if ([line rangeOfString:@"pod "].location == 0) {
			[podspecFile appendFormat:@"\n  s.dependencies =\t%@", line];
		}
	}

	[podspecFile appendString:@"\n\nend"];

	// Write Podspec File
	[[NSFileManager defaultManager] createFileAtPath:self.podspecPath contents:nil attributes:nil];
	[podspecFile writeToFile:self.podspecPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
