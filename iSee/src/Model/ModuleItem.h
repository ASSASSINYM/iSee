//
//  ModuleItem.h
//  iSee
//
//  Created by bolei on 2017/6/14.
//  Copyright © 2017年 ___zyang.Sir___. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ObjectFileItem;
@interface ModuleItem : NSObject

@property (nonatomic, strong) NSMutableArray<ObjectFileItem *> *objectsList;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) long size;
@property (nonatomic, assign) NSString *fileTypeName;

@end
