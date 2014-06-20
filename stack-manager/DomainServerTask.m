//
//  DomainServerTask.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/19/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "DomainServerTask.h"
#import "GlobalData.h"

@implementation DomainServerTask
@synthesize  logView = _logView;
@synthesize instance = _instance;
@synthesize stdoutLogOutput = _stdoutLogOutput;
@synthesize stderrLogOutput = _stderrLogOutput;
@synthesize logsAreInView = _logsAreInView;

+ (id)domainServerManager
{
    static DomainServerTask *globalDomainServer = nil;
    if (!globalDomainServer) {
        globalDomainServer = [[super allocWithZone:NULL] init];
    }
    return globalDomainServer;
}

- (id)init {
    if (self = [super init]) {
        _instance = [[NSTask alloc] init];
        instanceStdoutPipe = [NSPipe pipe];
        instanceStdoutFilehandle = [instanceStdoutPipe fileHandleForReading];
        instanceStderrorPipe = [NSPipe pipe];
        instanceStderrorFileHandle = [instanceStderrorPipe fileHandleForReading];
        [_instance setLaunchPath: [GlobalData sharedGlobalData].domainServerExecutablePath];
        [_instance setStandardOutput: instanceStdoutPipe];
        [_instance setStandardError: instanceStderrorPipe];
        [_instance setStandardInput: [NSPipe pipe]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appendAndRotateStdoutLogs:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:instanceStdoutFilehandle];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appendAndRotateStderrLogs:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:instanceStderrorFileHandle];
        
        [instanceStdoutFilehandle waitForDataInBackgroundAndNotify];
        [instanceStderrorFileHandle waitForDataInBackgroundAndNotify];
        
        _stdoutLogOutput = [[NSMutableArray alloc] init];
        _stderrLogOutput = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)displayLog
{
    _logView = [[LogViewer alloc] initWithWindowNibName:@"LogViewer"];
    [[_logView stdoutTextField] setString:@""];
    [[_logView assignmentTypeLabel] setStringValue:@"Domain Server"];
    self.logsAreInView = YES;
    [_logView showWindow:self];
    for (NSString *stdoutLine in self.stdoutLogOutput) {
        [[[_logView stdoutTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                          initWithString:stdoutLine]];
        [[_logView stdoutTextField] scrollRangeToVisible:NSMakeRange([[[_logView stdoutTextField] string] length], 0)];
    }
    for (NSString *stderrLine in self.stderrLogOutput) {
        [[[_logView stderrTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                          initWithString:stderrLine]];
        [[_logView stderrTextField] scrollRangeToVisible:NSMakeRange([[[_logView stderrTextField] string] length], 0)];
    }

}

- (void)appendAndRotateStdoutLogs:(NSNotification *)notification
{
    NSInteger maxScrollBack = 250;
    NSFileHandle *stdoutFileHandle = [notification object];
    NSData *stdoutData = [stdoutFileHandle availableData];
    NSString *stdoutString = [[NSString alloc] initWithData:stdoutData encoding:NSASCIIStringEncoding];
    [_stdoutLogOutput addObject:stdoutString];
    if ([_stdoutLogOutput count] > maxScrollBack) {
        [_stdoutLogOutput removeObjectAtIndex:0];
    }
    if (self.logsAreInView) {
        [[[_logView stdoutTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                          initWithString:stdoutString]];
        [[_logView stdoutTextField] scrollRangeToVisible:NSMakeRange([[[_logView stdoutTextField] string] length], 0)];
    }
    if (self.instance.isRunning) {
        [stdoutFileHandle waitForDataInBackgroundAndNotify];
    }
}

- (void)appendAndRotateStderrLogs:(NSNotification *)notification
{
    NSInteger maxScrollBack = 100;
    NSFileHandle *stderrFileHandle = [notification object];
    NSData *stderrData = [stderrFileHandle availableData];
    NSString *stderrString = [[NSString alloc] initWithData:stderrData encoding:NSASCIIStringEncoding];
    [_stderrLogOutput addObject:stderrString];
    if ([_stderrLogOutput count] > maxScrollBack) {
        [_stderrLogOutput removeObjectAtIndex:0];
    }
    if (self.logsAreInView) {
        [[[_logView stderrTextField] textStorage] appendAttributedString:[[NSAttributedString alloc]
                                                                          initWithString:stderrString]];
        [[_logView stderrTextField] scrollRangeToVisible:NSMakeRange([[[_logView stderrTextField] string] length], 0)];
    }
    if (self.instance.isRunning) {
        [stderrFileHandle waitForDataInBackgroundAndNotify];
    }
}

@end
