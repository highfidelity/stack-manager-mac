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
    assignmentInstances = [[NSMutableArray alloc] init];
    logViewWindow = [[LogViewer alloc] initWithWindowNibName:@"LogViewer"];
}

- (void)createExecutablePath
{
    // Make sure the path to store all components of this program exists.
    // If it doesn't exist create it and define a global variable with it.
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
        NSLog(@"Creating Server with id %ld", buttonTag);
        AssignmentClientTask *thisTask = [[AssignmentClientTask alloc]
                                          initWithType:(NSInteger)buttonTag
                                          domain:[GlobalData sharedGlobalData].defaultDomain];
        [[thisTask instance] launch];
        [assignmentInstances addObject:thisTask];
        [sender setTitle:@"Stop"];
    } else {
        NSLog(@"Assignment with id %ld already exists", buttonTag);
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
}

- (IBAction)startDomainServer:(id)sender
{
    
}

- (IBAction)displayLog:(id)sender
{
    long buttonTag = ((NSButton *)sender).tag;
    AssignmentClientTask *matchingTask = [self findAssignment:buttonTag];
    if (matchingTask) {
        [logViewWindow loadStdoutDataIntoView:matchingTask];
        [logViewWindow showWindow:self];
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

- (IBAction)createAllServers:(id)sender
{
    for (id assignmentType in [GlobalData sharedGlobalData].availableAssignmentTypes) {
        if (![self doWeHaveThisTypeAlready:(NSInteger)assignmentType]) {
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
            [self createServer:associatedButton];
        }
    }
}

@end
