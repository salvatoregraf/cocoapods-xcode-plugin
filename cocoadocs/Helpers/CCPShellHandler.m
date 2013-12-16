//
//  CCPShellHandler.m
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

#import "CCPShellHandler.h"
#import "CCPWorkspaceManager.h"
#import "CocoaPods.h"

#import <AppKit/AppKit.h>

#import "CCPRunOperation.h"

static NSOperationQueue *operationQueue;
static NSString * const DMMCocoaPodsEnvironmentKey = @"COCOAPODS_BUNDLE_ROOT";
static NSString * const DMMCocoaPodsWrapperName    = @"pod_wrapper";
static NSString * const DMMCocoaPodsWrapperType    = @"rb";
static NSString * const RUBY_EXECUTABLE            = @"/usr/bin/ruby";

@implementation CCPShellHandler

+ (void)runShellCommand:(NSString *)command withArgs:(NSArray *)args
              directory:(NSString *)directory completion:(ShellCompletionBlock)completion
{
	if (operationQueue == nil) {
		operationQueue = [NSOperationQueue new];
	}
    
	NSTask *task = [NSTask new];
    
	task.currentDirectoryPath = directory;
	task.launchPath = command;
	task.arguments  = args;
    task.environment = @{ DMMCocoaPodsEnvironmentKey : [[self podWrapperPath] stringByDeletingLastPathComponent],
                          @"HOME" : NSHomeDirectory(),
                          @"PATH" : @"/usr/bin"
                          };

	CCPRunOperation *operation = [[CCPRunOperation alloc] initWithTask:task
                                                            completion:completion];
	[operationQueue addOperation:operation];
}

+ (void)runPodWithArguments:(NSArray *)args completion:(ShellCompletionBlock)completion
{
    [self runShellCommand:RUBY_EXECUTABLE
                 withArgs:[@[[self podWrapperPath]] arrayByAddingObjectsFromArray:args]
                directory:[CCPWorkspaceManager currentWorkspaceDirectoryPath]
               completion:completion];
}

+ (NSString *)podWrapperPath
{
    static NSString * wrapperPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle * bundle = [[CocoaPods sharedPlugin] bundle];
        wrapperPath = [bundle pathForResource:DMMCocoaPodsWrapperName
                                       ofType:DMMCocoaPodsWrapperType];
    });

    return wrapperPath;
}

@end
