//
//  ExecutableCodeItem.m
//  iSee
//
//  Created by Yangtsing.Zhang on 15/10/22.
//  Copyright © 2015年 ___Baidu Inc.___. All rights reserved.
//

#import "ExecutableCodeItem.h"

@implementation ExecutableCodeItem

- (NSString *)segmentTypeStr {
    switch (_segmentType) {
        case CodeType_TEXT:
            return SEGMENT_TYPE_CODE;
            break;
        case CodeType_DATA:
            return SEGMENT_TYPE_DATA;
            break;
        default:
            break;
    }
    return @"";
}

@end
