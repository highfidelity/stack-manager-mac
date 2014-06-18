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

- (void)loadStdoutDataIntoView:(AssignmentClientTask *)assignmentTask
{
    [[self stdoutTextField] setString:@""];
    for (NSString *stdoutLine in assignmentTask.stdoutLogOutput) {
        [[[self stdoutTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                      initWithString:stdoutLine]];
        [[self stdoutTextField] scrollRangeToVisible:NSMakeRange([[[self stdoutTextField] string] length], 0)];
    }
}

@end
