//
//  CCPDocumentationManager.m
//
//  Copyright (c) 2013 Delisa Mason. http://delisa.me
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

#import "CCPDocumentationManager.h"
#import "CCPWorkspaceManager.h"
#import "CCPShellHandler.h"

static NSString *const RELATIVE_DOCSET_PATH  = @"/Library/Developer/Shared/Documentation/DocSets/";
static NSString *const DOCSET_ARCHIVE_FORMAT = @"http://cocoadocs.org/docsets/%@/docset.xar";
static NSString *const XAR_EXECUTABLE = @"/usr/bin/xar";

@implementation CCPDocumentationManager

+ (NSString *)docsetInstallPath
{
    return [NSString pathWithComponents:@[NSHomeDirectory(), RELATIVE_DOCSET_PATH]];
}

+ (void)installOrUpdateDocumentationForPods
{
	for (NSString *podName in [CCPWorkspaceManager installedPodNamesInCurrentWorkspace]) {
		NSURL *docsetURL = [NSURL URLWithString:[NSString stringWithFormat:DOCSET_ARCHIVE_FORMAT, podName]];
		[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:docsetURL] queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData *xarData, NSError *connectionError) {
		    if (xarData) {
		        NSString *tmpFilePath = [NSString pathWithComponents:@[NSTemporaryDirectory(), [NSString stringWithFormat:@"%@.xar", podName]]];
		        [xarData writeToFile:tmpFilePath atomically:YES];
		        [self extractAndInstallDocsAtPath:tmpFilePath];
			}
		}];
	}
}

+ (void)extractAndInstallDocsAtPath:(NSString *)path
{
	NSArray *arguments = @[@"-xf", path, @"-C", [CCPDocumentationManager docsetInstallPath]];
	[CCPShellHandler runShellCommand:XAR_EXECUTABLE
	                        withArgs:arguments
	                       directory:NSTemporaryDirectory()
	                      completion:nil];
}

@end
