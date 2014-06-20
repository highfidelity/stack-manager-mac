//
//  DomainServerTask.h
//  stack-manager
//
//  Created by Leonardo Murillo on 6/19/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogViewer.h"

@interface DomainServerTask : NSObject {
    NSPipe *instanceStdoutPipe;
    NSPipe *instanceStderrorPipe;
    NSFileHandle *instanceStdoutFilehandle;
    NSFileHandle *instanceStderrorFileHandle;
}

@property LogViewer *logView;
@property NSTask *instance;
@property NSMutableArray *stdoutLogOutput;
@property NSMutableArray *stderrLogOutput;
@property BOOL logsAreInView;

- (void)displayLog;
- (void)appendAndRotateStdoutLogs:(NSNotification *)notification;
- (void)appendAndRotateStderrLogs:(NSNotification *)notification;

@end
