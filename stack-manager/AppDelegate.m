//
//  AppDelegate.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/10/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "AppDelegate.h"
#import "GlobalData.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    startAllServersString = @"Start All";
    stopAllServersString = @"Stop All";
    
    assignmentInstances = [[NSMutableArray alloc] init];
}

- (void)createExecutablePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager createDirectoryAtPath:[GlobalData sharedGlobalData].clientsLaunchPath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
        NSLog(@"Failed to create directory \"%@\". Error: %@",
              [GlobalData sharedGlobalData].clientsLaunchPath,
              error);
    }
    
}

- (void)downloadLatestExecutables
{
    
}

- (void)downloadRequirements
{
    
}

- (AssignmentClientTask *)findAssignment:(long)assignmentType
{
    NSPredicate *findByType = [NSPredicate predicateWithFormat:@"self.instanceType == %d", (NSInteger)assignmentType];
    NSArray *typeMatches = [assignmentInstances filteredArrayUsingPredicate:findByType];
    if (!typeMatches || !typeMatches.count) {
        return nil;
    }
    AssignmentClientTask *matchingTask = [typeMatches objectAtIndex:0];
    typeMatches = nil;
    return matchingTask;
}

- (IBAction)toggleServer:(id)sender
{
    NSString *buttonTitle = ((NSButton *)sender).title;
    if ([buttonTitle isEqualToString:@"Start"]) {
        [self createServer:sender];
    } else {
        [self destroyServer:sender];
    }
}

- (IBAction)createServer:(id)sender
{
    long buttonTag = ((NSButton *)sender).tag;
    if (![self doWeHaveThisTypeAlready:(NSInteger)buttonTag]) {
        AssignmentClientTask *thisTask = [[AssignmentClientTask alloc]
                                          initWithType:(NSInteger)buttonTag
                                          domain:[GlobalData sharedGlobalData].defaultDomain];
        [[thisTask instance] launch];
        [assignmentInstances addObject:thisTask];
        [sender setTitle:@"Stop"];
    } else {
        NSLog(@"Assignment with id %ld already exists", buttonTag);
    }
    if ([assignmentInstances count] == [[GlobalData sharedGlobalData].availableAssignmentTypes count]) {
        [self.startAllServersButton setTitle:stopAllServersString];
    } else {
        [self.startAllServersButton setTitle:startAllServersString];
    }
}

- (IBAction)destroyServer:(id)sender
{
    long buttonTag = ((NSButton *)sender).tag;
    AssignmentClientTask *matchingTask = [self findAssignment:buttonTag];
    NSInteger indexOfInstance = [assignmentInstances indexOfObject:matchingTask];
    [[matchingTask instance] terminate];
    [assignmentInstances removeObjectAtIndex:indexOfInstance];
    [sender setTitle:@"Start"];
    [self.startAllServersButton setTitle:startAllServersString];
}

- (IBAction)startDomainServer:(id)sender
{
    [[[DomainServerTask domainServerManager] instance] launch];
}

- (IBAction)displayLog:(id)sender
{
    long buttonTag = ((NSButton *)sender).tag;
    AssignmentClientTask *matchingTask = [self findAssignment:buttonTag];
    if (matchingTask) {
        [matchingTask displayLog];
    } else {
        NSLog(@"The assignment for the requested log is not running");
    }
}

- (BOOL)doWeHaveThisTypeAlready:(NSInteger)instanceType
{
    NSPredicate *findByType = [NSPredicate predicateWithFormat:@"self.instanceType == %d", instanceType];
    NSArray *typeMatches = [assignmentInstances filteredArrayUsingPredicate:findByType];
    if (!typeMatches || !typeMatches.count) {
        return NO;
    }
    return YES;
}

- (IBAction)toggleAllServers:(id)sender
{
    NSString *buttonTitle = ((NSButton *)sender).title;
    for (id assignmentType in [GlobalData sharedGlobalData].availableAssignmentTypes) {
        NSButton *associatedButton;
        switch ([assignmentType intValue]) {
            case 0:
                associatedButton = self.audioMixerStartButton;
                break;
            case 1:
                associatedButton = self.avatarMixerStartButton;
                break;
            case 3:
                associatedButton = self.voxelServerStartButton;
                break;
            case 4:
                associatedButton = self.particleServerStartButton;
                break;
            case 5:
                associatedButton = self.metavoxelServerStartButton;
                break;
            case 6:
                associatedButton = self.modelServerStartButton;
                break;
        }
        if ([buttonTitle isEqualToString:startAllServersString] &&
            ![self doWeHaveThisTypeAlready:(NSInteger)[assignmentType intValue]]) {
            [self createServer:associatedButton];
        } else if ([buttonTitle isEqualToString:stopAllServersString] &&
                   [self doWeHaveThisTypeAlready:(NSInteger)[assignmentType intValue]]) {
            [self destroyServer:associatedButton];
        }
    }
}

@end
