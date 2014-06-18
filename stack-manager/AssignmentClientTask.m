//
//  AssignmentClientTask.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/13/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "AssignmentClientTask.h"
#import "GlobalData.h"
#import "LogViewer.h"

@implementation AssignmentClientTask
@synthesize instance = _instance;
@synthesize typeName = _typeName;
@synthesize instanceType = _instanceType;
@synthesize instanceDomain = _instanceDomain;
@synthesize stdoutLogOutput = _stdoutLogOutput;
@synthesize stderrLogOutput = _stderrLogOutput;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleDataAvailableNotification
                                                  object:instanceStdoutFilehandle];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleDataAvailableNotification
                                                  object:instanceStderrorFileHandle];
}

- (id)initWithType:(NSInteger)thisInstanceType
            domain:(NSString *)thisInstanceDomain
{
    NSLog(@"Creating new assignment task of type %zd", thisInstanceType);
    NSLog(@"Expecting to run task from %@", [GlobalData sharedGlobalData].assignmentClientExecutablePath);
    self = [super init];
    if (self) {
        switch ((int)thisInstanceType) {
            case 0:
                _typeName = @"audio-mixer";
                break;
            case 1:
                _typeName = @"avatar-mixer";
                break;
            case 3:
                _typeName = @"voxel-server";
                break;
            case 4:
                _typeName = @"particle-server";
                break;
            case 5:
                _typeName = @"metavoxel-server";
                break;
            case 6:
                _typeName = @"model-server";
                break;
        }
        _instance = [[NSTask alloc] init];
        
        // Set stdout handlers
        instanceStdoutPipe = [NSPipe pipe];
        instanceStdoutFilehandle = [instanceStdoutPipe fileHandleForReading];
        
        // Set stderr handlers
        instanceStderrorPipe = [NSPipe pipe];
        instanceStderrorFileHandle = [instanceStderrorPipe fileHandleForReading];
        
        // Set parameters for this instance
        _instanceType = thisInstanceType;
        _instanceDomain = thisInstanceDomain;
        NSMutableArray *assignmentArguments = [NSMutableArray arrayWithObjects:
                                               @"-t",
                                               [NSString stringWithFormat:@"%d", (int)_instanceType],
                                               @"-a",
                                               _instanceDomain,
                                               nil];
        
        [_instance setLaunchPath: [GlobalData sharedGlobalData].assignmentClientExecutablePath];
        [_instance setArguments: assignmentArguments];
        [_instance setStandardOutput: instanceStdoutPipe];
        [_instance setStandardError: instanceStderrorPipe];
        [_instance setStandardInput: [NSPipe pipe]];
        
        instanceStdoutFilehandle = [instanceStdoutPipe fileHandleForReading];
        instanceStderrorFileHandle = [instanceStderrorPipe fileHandleForReading];
        
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
    if (self.instance.isRunning) {
        [stderrFileHandle waitForDataInBackgroundAndNotify];
    }
}

@end
