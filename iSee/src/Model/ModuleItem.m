//
//  ModuleItem.m
//  iSee
//
//  Created by bolei on 2017/6/14.
//  Copyright © 2017年 ___zyang.Sir___. All rights reserved.
//

#import "ModuleItem.h"

@implementation ModuleItem


- (NSMutableArray *)objectsList {
    if (_objectsList == nil) {
        _objectsList = [NSMutableArray arrayWithCapacity:4];
    }
    return _objectsList;
}

@end
