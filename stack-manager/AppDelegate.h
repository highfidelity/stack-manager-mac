//
//  AppDelegate.h
//  stack-manager
//
//  Created by Leonardo Murillo on 6/10/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *assignmentInstances;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *domainServerStartButton;
@property (weak) IBOutlet NSButton *domainServerViewLogButton;
@property (weak) IBOutlet NSButton *audioMixerStartButton;
@property (weak) IBOutlet NSButton *audioMixerViewLogButton;
@property (weak) IBOutlet NSButton *avatarMixerStartButton;
@property (weak) IBOutlet NSButton *avatarMixerViewLogButton;
@property (weak) IBOutlet NSButton *voxelServerStartButton;
@property (weak) IBOutlet NSButton *voxelServerViewLogButton;
@property (weak) IBOutlet NSButton *modelServerStartButton;
@property (weak) IBOutlet NSButton *modelServerViewLogButton;
@property (weak) IBOutlet NSButton *particleServerStartButton;
@property (weak) IBOutlet NSButton *particleServerViewLogButton;
@property (weak) IBOutlet NSButton *metavoxelServerStartButton;
@property (weak) IBOutlet NSButton *metavoxelServerViewLogButton;

- (void)createExecutablePath;
- (void)downloadLatestExecutables;
- (void)downloadRequirements;
- (IBAction)toggleServer:(id)sender;
- (IBAction)createServer:(id)sender;
- (IBAction)destroyServer:(id)sender;
- (IBAction)startDomainServer:(id)sender;
- (IBAction)displayLog:(id)sender;
- (IBAction)hideLog:(id)sender;
- (BOOL)doWeHaveThisTypeAlready:(NSInteger)instanceType;
- (IBAction)createAllServers:(id)sender;

@end
