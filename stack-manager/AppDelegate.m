//
//  AppDelegate.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/10/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "AppDelegate.h"
#import "MD5.h"
#import "GlobalData.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self downloadLatestExecutablesAndRequirements];
    startAllServersString = @"Start All";
    stopAllServersString = @"Stop All";
    updatingString = @"Updating";
    upToDateString = @"Up to date";
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

- (void)downloadLatestExecutablesAndRequirements
{
    BOOL downloadQT = YES;
    BOOL downloadAC = YES;
    BOOL downloadDS = YES;
    
    // Determine if Qt needs to be downloaded
    NSString *qtCorePath = [[GlobalData sharedGlobalData].clientsLaunchPath stringByAppendingString:@"QtCore.framework"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:qtCorePath]) {
        downloadQT = NO;
    }
    
    // Generate hash for installed clients
    NSData *dsData = [NSData dataWithContentsOfFile:[GlobalData sharedGlobalData].domainServerExecutablePath];
    NSData *acData = [NSData dataWithContentsOfFile:[GlobalData sharedGlobalData].assignmentClientExecutablePath];
    
    // Get latest client hashes
    NSString *latestACMD5 = [self getStringFromURL:[GlobalData sharedGlobalData].assignmentClientMD5URL];
    NSString *latestDSMD5 = [self getStringFromURL:[GlobalData sharedGlobalData].domainServerMD5URL];
    
    if ([latestACMD5 isEqualToString:[acData MD5]]) {
        downloadAC = NO;
    }
    
    if ([latestDSMD5 isEqualToString:[dsData MD5]]) {
        downloadDS = NO;
    }
    
    if (downloadQT) {
        [[self requirementsStatusTextfield] setStringValue:updatingString];
        NSURLSessionConfiguration *qtSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:@"qt"];
        NSURLSession *qtSession;
        qtSession = [NSURLSession sessionWithConfiguration:qtSessionConfig delegate:self delegateQueue:nil];
        NSURLRequest *qtRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[GlobalData sharedGlobalData].requirementsURL]];
        NSURLSessionDownloadTask *qtDownloadTask = [qtSession downloadTaskWithRequest:qtRequest];
        [qtDownloadTask resume];
    } else {
        [[self requirementsStatusTextfield] setStringValue:upToDateString];
    }
    
    if (downloadAC) {
        [[self assignmentClientStatusTextField] setStringValue:updatingString];
        NSURLSessionConfiguration *acSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:@"ac"];
        NSURLSession *acSession;
        acSession = [NSURLSession sessionWithConfiguration:acSessionConfig delegate:self delegateQueue:nil];
        NSURLRequest *acRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[GlobalData sharedGlobalData].assignmentClientURL]];
        NSURLSessionDownloadTask *acDownloadTask = [acSession downloadTaskWithRequest:acRequest];
        [acDownloadTask resume];
    } else {
        [[self assignmentClientStatusTextField] setStringValue:upToDateString];
    }
    
    if (downloadDS) {
        [[self domainServerStatusTextField] setStringValue:updatingString];
        NSURLSessionConfiguration *dsSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:@"ds"];
        NSURLSession *dsSession;
        dsSession = [NSURLSession sessionWithConfiguration:dsSessionConfig delegate:self delegateQueue:nil];
        NSURLRequest *dsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[GlobalData sharedGlobalData].domainServerURL]];
        NSURLSessionDownloadTask *dsDownloadTask = [dsSession downloadTaskWithRequest:dsRequest];
        [dsDownloadTask resume];
    } else {
        [[self domainServerStatusTextField] setStringValue:upToDateString];
    }
    
    [[self updateStatusTextField] setStringValue:@""];
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

- (IBAction)toggleDomainServer:(id)sender
{
    if ([self.domainServerStartButton.title isEqualToString:@"Start"]) {
        domainServer = [[DomainServerTask alloc] init];
        [[domainServer instance] launch];
        [self.domainServerStartButton setTitle:@"Stop"];
    } else {
        [[domainServer instance] terminate];
        domainServer = nil;
        [self.domainServerStartButton setTitle:@"Start"];
    }
    
}

- (IBAction)displayAssignmentClientLog:(id)sender
{
    long buttonTag = ((NSButton *)sender).tag;
    AssignmentClientTask *matchingTask = [self findAssignment:buttonTag];
    if (matchingTask) {
        [matchingTask displayLog];
    } else {
        NSLog(@"The assignment for the requested log is not running");
    }
}

- (IBAction)displayDomainServerLog:(id)sender
{
    [domainServer displayLog];
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

- (NSString *)getStringFromURL:(NSString *)url
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %d", url, (int)[responseCode statusCode]);
        return nil;
    }
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}

@end
