//
//  LogViewer.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/18/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "LogViewer.h"

@interface LogViewer ()

@end

@implementation LogViewer
@synthesize currentTask = _currentTask;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)windowWillClose:(NSNotification *)notification
{
    if (_currentTask) {
        self.currentTask.logsAreInView = NO;
        self.currentTask = nil;
    }
}

- (void)loadLogDataIntoView
{
    NSLog(@"Loading log data into view");
    [[self stdoutTextField] setString:@""];
    if (_currentTask) {
        for (NSString *stdoutLine in _currentTask.stdoutLogOutput) {
            [[[self stdoutTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                          initWithString:stdoutLine]];
            [[self stdoutTextField] scrollRangeToVisible:NSMakeRange([[[self stdoutTextField] string] length], 0)];
        }
        for (NSString *stderrLine in _currentTask.stderrLogOutput) {
            [[[self stderrTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                          initWithString:stderrLine]];
            [[self stderrTextField] scrollRangeToVisible:NSMakeRange([[[self stderrTextField] string] length], 0)];
        }
    }
}

@end
