//
//  ObjectSecionItem.h
//  iSee
//
//  Created by bolei on 2017/6/15.
//  Copyright © 2017年 ___zyang.Sir___. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MethodFileItem;
@interface ObjectSecionItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) long size;
@property (nonatomic, assign) NSString *fileTypeName;
@property (nonatomic, strong) NSMutableArray<MethodFileItem *> *objectsList;


@end
