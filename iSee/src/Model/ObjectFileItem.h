//
//  ObjectFileItem.h
//  iSee
//
//  Created by Yangtsing.Zhang on 15/8/11.
//  Copyright (c) 2015年 ___Baidu Inc.___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MethodFileItem.h"

/**
 *  目标文件的来源
 */
typedef enum{
    OBJECT_FILE_FROM_INVALID_VAL = 0x00000000,  //无效值
    OBJECT_FILE_FROM_CUSTOM_CODE = 0x00000001,  //自定义可见代码
    OBJECT_FILE_FROM_STATIC_FILE = 0x00000010,  //第三方静态库
    OBJECT_FILE_FROM_SYSTEM_LIB = 0x00000100    //系统标准库
} OBJECT_FILE_SRC_ENUM;

@class ObjectSecionItem;

/**
 *  目标文件项目, 用于统计.o 文件
 */
@interface ObjectFileItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *module;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign) OBJECT_FILE_SRC_ENUM fileType;
@property (nonatomic, assign, readonly) NSString *fileTypeName;
@property (nonatomic, assign) BOOL hasUesd;

/* 保存object的段信息 
 
 * __TEXT端节名含义
 
 1. __text: 代码节，存放机器编译后的代码
 2. __stubs: 用于辅助做动态链接代码（dyld）.
 3. __stub_helper:用于辅助做动态链接（dyld）.
 4. __objc_methname:objc的方法名称
 5. __cstring:代码运行中包含的字符串常量,比如代码中定义`#define kGeTuiPushAESKey        @"DWE2#@e2!"`,那DWE2#@e2!会存在这个区里。
 6. __objc_classname:objc类名
 7. __objc_methtype:objc方法类型
 8. __ustring:
 9. __gcc_except_tab:
 10. __const:存储const修饰的常量
 11. __dof_RACSignal:
 12. __dof_RACCompou:
 13. __unwind_info:
 __DATA端节名含义
 
 1. __got:存储引用符号的实际地址，类似于动态符号表
 2. __la_symbol_ptr:lazy symbol pointers。懒加载的函数指针地址。和__stubs和stub_helper配合使用。具体原理暂留。
 3. __mod_init_func:模块初始化的方法。
 4. __const:存储constant常量的数据。比如使用extern导出的const修饰的常量。
 5. __cfstring:使用Core Foundation字符串
 6. __objc_classlist:objc类列表,保存类信息，映射了__objc_data的地址
 7. __objc_nlclslist:Objective-C 的 +load 函数列表，比 __mod_init_func 更早执行。
 8. __objc_catlist: categories
 9. __objc_nlcatlist:Objective-C 的categories的 +load函数列表。
 10. __objc_protolist:objc协议列表
 11. __objc_imageinfo:objc镜像信息
 12. __objc_const:objc常量。保存objc_classdata结构体数据。用于映射类相关数据的地址，比如类名，方法名等。
 13. __objc_selrefs:引用到的objc方法
 14. __objc_protorefs:引用到的objc协议
 15. __objc_classrefs:引用到的objc类
 16. __objc_superrefs:objc超类引用
 17. __objc_ivar:objc ivar指针,存储属性。
 18. __objc_data:objc的数据。用于保存类需要的数据。最主要的内容是映射__objc_const地址，用于找到类的相关数据。
 19. __data:暂时没理解，从日志看存放了协议和一些固定了地址的静态量。
 20. __bss:存储未初始化的静态量。比如：`static NSThread *_networkRequestThread = nil;`其中这里面的size表示应用运行占用的内存，不是实际的占用空间。所以计算大小的时候应该去掉这部分数据。
 21. __common:存储导出的全局的数据。类似于static，但是没有用static修饰。比如KSCrash里面`NSDictionary* g_registerOrders;`, g_registerOrders就存储在__common里面
 
*
*/
@property (nonatomic, strong) NSMutableDictionary<NSString *,ObjectSecionItem *> *sectionDictionary;

@property (nonatomic, strong) NSMutableDictionary<NSString *,MethodFileItem *> *usedMethod; //有使用过的方法，用__objc_methname和__objc_selrefs两者对比得到，其中__objc_selrefs需要用otool解析
@property (nonatomic, strong) NSMutableDictionary<NSString *,MethodFileItem *> *unUsedMethod; //未使用的方法，用__objc_methname和__objc_selrefs两者对比得到，其中__objc_selrefs需要用otool解析
@property (nonatomic, strong) NSMutableDictionary<NSString *,MethodFileItem *> *usedClass; //使用的类，用__objc_classname和__objc_classrefs两者对比得到，其中__objc_classrefs需要用otool解析 

@property (nonatomic, strong) NSMutableDictionary<NSString *,MethodFileItem *> *unUsedClass; //使用的类，用__objc_classname和__objc_classrefs两者对比得到，其中__objc_classrefs需要用otool解析


@end
