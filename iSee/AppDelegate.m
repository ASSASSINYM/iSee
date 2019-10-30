//
//  AppDelegate.m
//  iSee
//  入口文件
//  Created by Yangtsing.Zhang on 15/8/11.
//  Copyright (c) 2015年 ___Baidu Inc.___. All rights reserved.
//

#import "AppDelegate.h"
#import "DDFileReader.h"
#import "GSLinkMapParser.h"
#import "GSCommonDefine.h"

@interface AppDelegate ()

@property (nonatomic, retain) NSOpenPanel *fileSelectPanel;

@property (nonatomic, retain) NSString *selectedFilePath;

@property (nonatomic, retain) DDFileReader *textFileReader;

@property (nonatomic, retain) GSLinkMapParser *linkMapParser;

@end

@implementation AppDelegate

// ADD Code Review

- (void)constructManager
{
    _fileSelectPanel = [[NSOpenPanel alloc] init];
    [_fileSelectPanel setCanChooseFiles: YES];
    [_fileSelectPanel setCanChooseDirectories: NO];
    [_fileSelectPanel setAllowsMultipleSelection: NO];
    [_fileSelectPanel setTreatsFilePackagesAsDirectories: YES];
    [_fileSelectPanel setAllowedFileTypes:@[@"txt"]];
}

- (void)constructFileReader
{
    if (_textFileReader) {
        self.textFileReader = nil;
    }
    
    _textFileReader = [[DDFileReader alloc] initWithFilePath: _selectedFilePath];
    _linkMapParser.linkMapfileReader = _textFileReader;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self constructManager];
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)openDocument:(id)sender
{
    [_fileSelectPanel beginSheetModalForWindow:  [[NSApplication sharedApplication] mainWindow] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *selectURL = [[self.fileSelectPanel URLs] firstObject];
             [[NSNotificationCenter defaultCenter] postNotificationName: ANALYZE_BEGIN_NOTIFICATION  object: [selectURL path]];
        }
    }];
}


@end
