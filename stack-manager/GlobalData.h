//
//  GlobalData.h
//  stack-manager
//
//  Created by Leonardo Murillo on 6/12/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalData : NSObject {
    NSString *clientsLaunchPath;
    NSString *assignmentClientExecutablePath;
    NSString *domainServerExecutablePath;
    NSString *requirementsURL;
    NSString *assignmentClientURL;
    NSString *domainServerURL;
    NSString *defaultDomain;
    NSArray *availableAssignmentTypes;
}

@property (nonatomic, retain) NSString *clientsLaunchPath;
@property (nonatomic, retain) NSString *assignmentClientExecutablePath;
@property (nonatomic, retain) NSString *domainServerExecutablePath;
@property (nonatomic, retain) NSString *requirementsURL;
@property (nonatomic, retain) NSString *assignmentClientURL;
@property (nonatomic, retain) NSString *domainServerURL;
@property (nonatomic, retain) NSString *defaultDomain;
@property (nonatomic, retain) NSArray *availableAssignmentTypes;

+ (GlobalData *)sharedGlobalData;

@end
