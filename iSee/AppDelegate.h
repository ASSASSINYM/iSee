//
//  AppDelegate.h
//  iSee
//  // 入口文件
//  Created by Yangtsing.Zhang on 15/8/11.
//  Copyright (c) 2015年 ___Baidu Inc.___. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

// 主viewcontroller入口
@property (nonatomic, strong) IBOutlet ViewController *mainVC;

@end

