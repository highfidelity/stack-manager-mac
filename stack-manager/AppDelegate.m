//
//  AppDelegate.m
//  stack-manager
//
//  Created by Leonardo Murillo on 6/10/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import "AppDelegate.h"
#import "MD5.h"
#import "SSZipArchive.h"
#import "GlobalData.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    startAllServersString = @"Start All";
    stopAllServersString = @"Stop All";
    updatingString = @"Updating ";
    upToDateString = @"Up to date | Updated: ";
    qtReady = NO;
    dsReady = NO;
    acReady = NO;
    assignmentInstances = [[NSMutableArray alloc] init];
    [self createExecutablePath];
    [self downloadLatestExecutablesAndRequirements];
    
    NSTimer *periodicUpdate = [NSTimer scheduledTimerWithTimeInterval: 60.0
                                                               target: self
                               selector:@selector(downloadLatestExecutablesAndRequirements)
                                                             userInfo:nil
                                                              repeats:YES];
    
}

- (void)createExecutablePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager createDirectoryAtPath:[GlobalData sharedGlobalData].clientsResourcePath
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
    NSCharacterSet *cleanUpCharacters = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *currentDateTime = [[NSString alloc] initWithString:[[NSDate date]
                                                                  descriptionWithLocale:currentLocale]];
                                 
    BOOL downloadQT = YES;
    BOOL downloadAC = YES;
    BOOL downloadDS = YES;
    
    NSString *qtCorePath = [[GlobalData sharedGlobalData].clientsLaunchPath stringByAppendingString:@"QtCore.framework"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:qtCorePath]) {
        downloadQT = NO;
    }
    
    NSData *dsData = [NSData dataWithContentsOfFile:[GlobalData sharedGlobalData].domainServerExecutablePath];
    NSData *acData = [NSData dataWithContentsOfFile:[GlobalData sharedGlobalData].assignmentClientExecutablePath];
    NSString *latestACMD5 = [[[self getStringFromURL:[GlobalData sharedGlobalData].assignmentClientMD5URL] componentsSeparatedByCharactersInSet:cleanUpCharacters] componentsJoinedByString:@""];
    NSString *latestDSMD5 = [[[self getStringFromURL:[GlobalData sharedGlobalData].domainServerMD5URL] componentsSeparatedByCharactersInSet:cleanUpCharacters] componentsJoinedByString:@""];

    if ([latestACMD5 isEqual:[acData MD5]]) {
        downloadAC = NO;
    }
    
    if ([latestDSMD5 isEqual:[dsData MD5]]) {
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
        qtReady = YES;
        [_requirementsStatusTextfield setStringValue:[upToDateString stringByAppendingString:currentDateTime]];
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
        dsReady = YES;
        [_assignmentClientStatusTextField setStringValue:[upToDateString stringByAppendingString:currentDateTime]];
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
        acReady = YES;
        [_domainServerStatusTextField setStringValue:[upToDateString stringByAppendingString:currentDateTime]];
    }
    
    if (downloadAC || downloadDS) {
        [self restartAllServers];
    }
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

- (void)restartAllServers
{
    NSMutableArray *currentRunningTasks = [[NSMutableArray alloc] init];
    for (AssignmentClientTask *thisTask in assignmentInstances) {
        NSNumber *thisType = [[NSNumber alloc] initWithInteger:thisTask.instanceType];
        [currentRunningTasks addObject:thisType];
    }
    for (NSNumber *runningTask in currentRunningTasks) {
        NSButton *associatedButton;
        switch ([runningTask intValue]) {
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
        [self destroyServer:associatedButton];
        [self createServer:associatedButton];
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
    
    NSString *string = [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
    return string;
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSError *error;
    if ([[session configuration].identifier isEqualToString:@"qt"]) {
        BOOL success = [SSZipArchive unzipFileAtPath:[location path] toDestination:[GlobalData sharedGlobalData].clientsLaunchPath];
        if (success) {
            qtReady = YES;
        } else {
            NSLog(@"Unable to unzip Qt requirements");
        }
    } else if ([[session configuration].identifier isEqualToString:@"ac"] ||
               [[session configuration].identifier isEqualToString:@"ds"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *savePath;
        if ([[session configuration].identifier isEqualToString:@"ac"]) {
            [fileManager removeItemAtPath:[GlobalData sharedGlobalData].assignmentClientExecutablePath error:&error];
            savePath = [GlobalData sharedGlobalData].assignmentClientExecutablePath;
        } else if ([[session configuration].identifier isEqualToString:@"ds"]) {
            [fileManager removeItemAtPath:[GlobalData sharedGlobalData].domainServerExecutablePath error:&error];
            savePath = [GlobalData sharedGlobalData].domainServerExecutablePath;
        }
        BOOL success = [fileManager moveItemAtPath:[location path] toPath:savePath error:&error];
        if (success) {
            NSDictionary *attributes;
            NSNumber *permissions;
            permissions = [NSNumber numberWithUnsignedLong: 493];
            attributes = [NSDictionary dictionaryWithObject:permissions forKey:NSFilePosixPermissions];
            [fileManager setAttributes:attributes ofItemAtPath:savePath error:&error];
            if ([[session configuration].identifier isEqualToString:@"ac"]) {
                acReady = YES;
            } else if ([[session configuration].identifier isEqualToString:@"ds"]) {
                dsReady = YES;
            }
        } else {
            NSLog(@"Couldnt copy the downloaded file - error %@", [error localizedDescription]);
        }
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSTextField *textFieldForTask;
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *currentDateTime = [[NSString alloc] initWithString:[[NSDate date] descriptionWithLocale:currentLocale]];
    if ([[session configuration].identifier isEqualToString:@"qt"]) {
        textFieldForTask = self.requirementsStatusTextfield;
    } else if ([[session configuration].identifier isEqualToString:@"ds"]) {
        textFieldForTask = self.domainServerStatusTextField;
    } else if ([[session configuration].identifier isEqualToString:@"ac"]) {
        textFieldForTask = self.assignmentClientStatusTextField;
    }
    NSInteger percentageCompleted = (totalBytesWritten * 100)/totalBytesExpectedToWrite;
    if (percentageCompleted < 100) {
        [textFieldForTask setStringValue:[updatingString stringByAppendingString:[NSString stringWithFormat:@"(%d %%)", (int)percentageCompleted]]];
    } else {
        [textFieldForTask setStringValue:[upToDateString stringByAppendingString:currentDateTime]];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSButton *stopAllButton = [[NSButton alloc] init];
    [stopAllButton setTitle:@"Stop All"];
    [self toggleAllServers:stopAllButton];
}

@end
