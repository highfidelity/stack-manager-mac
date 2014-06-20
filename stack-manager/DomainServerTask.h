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

@property (nonatomic, retain) LogViewer *logView;
@property (nonatomic, retain) NSTask *instance;
@property (nonatomic, retain) NSMutableArray *stdoutLogOutput;
@property (nonatomic, retain) NSMutableArray *stderrLogOutput;
@property (nonatomic) BOOL logsAreInView;

+ (id)domainServerManager;
- (void)displayLog;
- (void)appendAndRotateStdoutLogs:(NSNotification *)notification;
- (void)appendAndRotateStderrLogs:(NSNotification *)notification;

@end
