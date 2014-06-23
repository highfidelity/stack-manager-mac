//
//  GlobalData.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/12/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "GlobalData.h"

@implementation GlobalData
@synthesize clientsLaunchPath;
@synthesize assignmentClientExecutablePath;
@synthesize domainServerExecutablePath;
@synthesize requirementsURL;
@synthesize assignmentClientURL;
@synthesize domainServerURL;
@synthesize assignmentClientMD5URL;
@synthesize domainServerMD5URL;
@synthesize defaultDomain;
@synthesize availableAssignmentTypes;

static GlobalData *sharedGlobalData = nil;

+ (GlobalData *) sharedGlobalData {
    if (sharedGlobalData == nil) {
        sharedGlobalData = [[super allocWithZone:NULL] init];
        
        // Define global path for assignment-client
        NSString *stackManagerPath = @"/High Fidelity/stack-manager/";
        NSString *assignmentClientExecutable = @"assignment-client";
        NSString *domainServerExecutable = @"domain-server";
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        sharedGlobalData.clientsLaunchPath = [applicationSupportDirectory stringByAppendingString:stackManagerPath];
        sharedGlobalData.assignmentClientExecutablePath = [sharedGlobalData.clientsLaunchPath stringByAppendingString:assignmentClientExecutable];
        sharedGlobalData.domainServerExecutablePath = [sharedGlobalData.clientsLaunchPath stringByAppendingString:domainServerExecutable];
        
        // Define other global constants
        sharedGlobalData.requirementsURL =
        @"https://s3-us-west-1.amazonaws.com/highfidelity-public/requirements/mac/qt.zip";
        sharedGlobalData.assignmentClientURL =
        @"https://s3-us-west-1.amazonaws.com/highfidelity-public/assignment-client/mac/assignment-client";
        sharedGlobalData.domainServerURL =
        @"https://s3-us-west-1.amazonaws.com/highfidelity-public/domain-server/mac/domain-server";
        
        sharedGlobalData.assignmentClientMD5URL = [sharedGlobalData.assignmentClientURL stringByAppendingString:@".md5"];
        sharedGlobalData.domainServerMD5URL = [sharedGlobalData.domainServerURL stringByAppendingString:@".md5"];
        
        sharedGlobalData.defaultDomain = @"localhost";
        sharedGlobalData.availableAssignmentTypes = [[NSArray alloc] initWithObjects:
                                                     [NSNumber numberWithInt: 0],
                                                     [NSNumber numberWithInt: 1],
                                                     [NSNumber numberWithInt: 3],
                                                     [NSNumber numberWithInt: 4],
                                                     [NSNumber numberWithInt: 5],
                                                     [NSNumber numberWithInt: 6],
                                                     nil];
    }
    return sharedGlobalData;
}

@end
