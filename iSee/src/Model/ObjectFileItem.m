//
//  ObjectFileItem.m
//  iSee
//
//  Created by Yangtsing.Zhang on 15/8/11.
//  Copyright (c) 2015年 ___Baidu Inc.___. All rights reserved.
//

#import "ObjectFileItem.h"

@interface ObjectFileItem()

@property (nonatomic, retain) NSMutableArray<__kindof MethodFileItem*> *methodsArray;

@end

@implementation ObjectFileItem


- (NSString *)description {
    return [NSString stringWithFormat:@"module = %@,name = %@,size = %@",_module,_name,@(_size)];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.module = @"Custom";
        self.sectionDictionary = [NSMutableDictionary dictionaryWithCapacity:20];
        self.usedMethod = [NSMutableDictionary dictionaryWithCapacity:20];
        self.unUsedMethod = [NSMutableDictionary dictionaryWithCapacity:20];
        self.usedClass = [NSMutableDictionary dictionaryWithCapacity:20];
        self.unUsedClass = [NSMutableDictionary dictionaryWithCapacity:20];
        self.hasUesd = YES;
    }
    return self;
}

- (NSString *)fileTypeName {
    switch (_fileType) {
        case OBJECT_FILE_FROM_INVALID_VAL:
            return @"Invalid";
            break;
        case OBJECT_FILE_FROM_CUSTOM_CODE:
            return @"Custom_Code";
            break;
        case OBJECT_FILE_FROM_STATIC_FILE:
            return @"Staic_File";
            break;
        case OBJECT_FILE_FROM_SYSTEM_LIB:
            return @"System_Lib";
            break;
        default:
            break;
    }
    return @"UNKnow";
}

@end
