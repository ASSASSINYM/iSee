//
//  ViewController.m
//  iSee
//
//  Created by Yangtsing.Zhang on 15/8/11.
//  Copyright (c) 2015年 ___Baidu Inc.___. All rights reserved.
//

#import "ViewController.h"
#import "ObjectFileItem.h"
#import "GSCommonDefine.h"
#import "DDFileReader.h"
#import "GSLinkMapParser.h"
#import "ModuleItem.h"
#import "ObjectSecionItem.h"



// Constant strings
static NSString * const kTableColumnType = @"typeIdentifier";
static NSString * const kTableColumnName       = @"nameIdentifier";
static NSString * const kTableColumnSize       = @"sizeIdentifier";


typedef enum : NSUInteger {
    ESourceSegmentAll = 0,
    ESourceSegmentUnusedClass,
    ESourceSegmentUnusedSelector,
} ESourceSegment;

typedef enum : NSUInteger {
    EnumLevelAll = 1,
    EnumLevelModule,
    EnumLevelObjct,
    EnumLevelFunction,
} EnumLevel;

@interface ViewController()<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTextField *titleTextField;

@property (weak) IBOutlet NSButton *backButtion;

@property (weak) IBOutlet NSTextField *resultTextField;

@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSSegmentedControl *segment;

@property (weak) IBOutlet NSTextField *excutePathTextField;

@property (weak) IBOutlet NSTextFieldCell *linkMapPathTextField;

@property (nonatomic, retain) NSString *linkMapFilePath;


@property (strong, nonatomic) NSMutableArray *dataSource;

@property (strong, nonatomic) NSMutableArray *resultList;

@property (nonatomic, retain) NSString *selectedFilePath;

@property (nonatomic, retain) DDFileReader *textFileReader;

@property (nonatomic, retain) GSLinkMapParser *linkMapParser;

@property (nonatomic, retain) NSOpenPanel *fileSelectPanel;


@property (nonatomic, assign) EnumLevel level;  //当前层级

@property (nonatomic, strong) NSMutableArray *itemsQueue;

@property (nonatomic, assign) long long totoalSize;

@property (nonatomic, assign) BOOL fileSizeDesc;

@property (nonatomic, copy) NSString *excuteFilePath;  //可执行文件的地址

@property (nonatomic, strong) NSMutableArray *unUsedClassList;

@property (nonatomic, strong) NSMutableArray *unUsedSelectorList;

@end

@implementation ViewController

- (void)dealloc
{
    [self unRegistNotification];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registNotification];
    _resultsTextView.editable = NO;
    self.dataSource = [NSMutableArray array];
    self.resultList = [NSMutableArray array];
    self.itemsQueue = [NSMutableArray array];
    self.unUsedClassList = [NSMutableArray array];
    self.unUsedSelectorList = [NSMutableArray array];
    
    [self.tableView setDoubleAction:@selector(tableViewDoubleClicked)];
    self.level = EnumLevelAll;
    //_analyzeProgressBar.hidden = YES;
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - Actions methods
- (IBAction)sortResultsBtnClicked:(NSButton *)sender {

}

- (IBAction)resetResultsBtnClicked:(NSButton *)sender {
    self.excuteFilePath = @"";
    self.excutePathTextField.stringValue = @"";
    self.linkMapFilePath = @"";
    self.linkMapPathTextField.stringValue = @"";
}

- (IBAction)backAction:(id)sender {
    if (self.level <= EnumLevelAll) {
        return;
    }
    
    self.level -= 1;
    [self.itemsQueue removeLastObject];
    
    [self buildDataSource];
}

- (IBAction)excuteFileAction:(id)sender {
    [self constructFileSelect];
    [_fileSelectPanel beginSheetModalForWindow:  [[NSApplication sharedApplication] mainWindow] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *selectURL = [[self.fileSelectPanel URLs] firstObject];
            self.excuteFilePath = [selectURL path];
            self.excutePathTextField.stringValue = [selectURL path];
            if (self.linkMapFilePath.length > 0) {
                [self startAnalyExcuteFile];
            }else {
                self.titleTextField.stringValue = @"需要配置LinkMap文件地址";
                
            }

        }
    }];
}
- (IBAction)openLinkMapAction:(id)sender {
    [self constructFileSelect];
    [_fileSelectPanel beginSheetModalForWindow:  [[NSApplication sharedApplication] mainWindow] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *selectURL = [[self.fileSelectPanel URLs] firstObject];
            self.linkMapFilePath = [selectURL path];
            self.linkMapPathTextField.stringValue = [selectURL path];
            
            if (self.excuteFilePath.length > 0) {
                [self startAnalyExcuteFile];
            }else {
                self.titleTextField.stringValue = @"需要配置可执行文件地址";
            }
        }
    }];
}

- (IBAction)switchAction:(id)sender {
    [self buildDataSource];
}


#pragma mark - notifications

- (void)registNotification
{
    SEL handler = @selector(onHandleResultsMsgDone:);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:handler name: RESULTS_DONE_NOTIFICATION object: nil];
    
    SEL arcTypeHandler = @selector(onHandleArchTypeFoundMsg:);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:arcTypeHandler name:ARC_TYPE_FIOUND_NOTIFICATION object: nil];
    
    SEL progressUpdateHanlder = @selector(onHandleAnalyzeProgressMsg:);
    [[NSNotificationCenter defaultCenter] addObserver:self selector: progressUpdateHanlder name: ANALYZE_PROGRESS_UPDATE_NOTIFICATION object: nil];
    
    SEL onBeginAnalyzeHanlder = @selector(onBeginAnalyze:);
    [[NSNotificationCenter defaultCenter] addObserver:self selector: onBeginAnalyzeHanlder name: ANALYZE_BEGIN_NOTIFICATION object: nil];
}

- (void)unRegistNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)onHandleResultsMsgDone:(NSNotification *)notification
{
    
    //清除之前的结果
    [self.resultList removeAllObjects];
    
    NSMutableArray *objectsArray = notification.object;
    NSUInteger length = objectsArray.count - 2;
    NSRange range = NSMakeRange(2, length);
    [self.resultList addObjectsFromArray:[objectsArray subarrayWithRange: range]];
    
    [self buildDataSource];
    
    [self startAnylyUnused];
}

- (void)onHandleArchTypeFoundMsg:(NSNotification *)notification
{
    [_arcTypeTextField setStringValue: (NSString *)notification.object];
}

- (void)onHandleAnalyzeProgressMsg:(NSNotification *)notification
{
    double progress = [(NSNumber *)notification.object doubleValue];
    
    progress *= 100;//范围转成0.0 ~ 100.0
    dispatch_async(dispatch_get_main_queue(), ^(){
       [_analyzeProgressBar setDoubleValue: progress];
    });
}

- (void)onBeginAnalyze:(NSNotification *)notification {
    NSString *path = notification.object;
    self.selectedFilePath = path;
    [self startAnalyze];
}

#pragma mark - <NSTableViewDelegate>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.dataSource count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    
    if (rowIndex >= [self.dataSource count]) {
        return @"";
    }
    
    NSString *columnIdentifier = [tableColumn identifier];
    id obj = [self.dataSource objectAtIndex:rowIndex];
    
    
    switch (self.level) {
        case EnumLevelAll:
        case EnumLevelModule:
        case EnumLevelObjct:
        case EnumLevelFunction:{
            if ([columnIdentifier isEqualToString:kTableColumnType]) {
                return [obj valueForKey:@"fileTypeName"];
            } else if ([columnIdentifier isEqualToString:kTableColumnName]) {
                return [obj valueForKey:@"name"];
            } else if ([columnIdentifier isEqualToString:kTableColumnSize]) {
                return [NSString stringWithFormat:@"%@",[obj valueForKey:@"size"]];
            }
        }
            break;
        default:
            break;
    }
    
    return @"";
}

- (void)tableViewDoubleClicked {
    
    if (self.segment.selectedSegment == ESourceSegmentAll) {
        if (self.level >=  EnumLevelFunction) {
            return;
        }
        
        self.level += 1;
        
        id obj = [self.dataSource objectAtIndex:[self.tableView clickedRow]];
        [self.itemsQueue addObject:obj];
        
        [self buildDataSource];
        [self.tableView deselectAll:self];
    }
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn{
    
    NSString *columnIdentifier = [tableColumn identifier];
    if ([columnIdentifier isEqualToString:kTableColumnType]) {
        [self.dataSource sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [[obj1 valueForKey:@"fileTypeName"] compare:[obj2 valueForKey:@"fileTypeName"]];
        }];
    } else if ([columnIdentifier isEqualToString:kTableColumnName]) {
        [self.dataSource sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [[obj1 valueForKey:@"name"] compare:[obj2 valueForKey:@"name"]];
        }];
    } else if ([columnIdentifier isEqualToString:kTableColumnSize]) {
        _fileSizeDesc = !_fileSizeDesc;
        [self.dataSource sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if (_fileSizeDesc) {
                return [[obj2 valueForKey:@"size"] compare:[obj1 valueForKey:@"size"]];
            }
            return [[obj1 valueForKey:@"size"] compare:[obj2 valueForKey:@"size"]];
        }];
    }
    
    [self.tableView reloadData];
}


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextFieldCell *textField = (NSTextFieldCell *)cell;
    textField.textColor = [NSColor blackColor];
    if (self.segment.selectedSegment == ESourceSegmentAll && self.level == EnumLevelModule && [tableColumn.identifier isEqualToString:kTableColumnName]) {
        ObjectFileItem *item = [self.dataSource objectAtIndex:row];
        textField.textColor = item.hasUesd ? [NSColor blackColor] : [NSColor redColor];
    }
}

#pragma mark - Analized

- (void)startAnalyze {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self constructFileReader];
        [self extractLinkMapDataFromFile];
        [self outputAnalysisResults];
    });
}

- (void)extractLinkMapDataFromFile
{
    NSString *aLineStr = [_textFileReader readLine];
    while (aLineStr && ![_linkMapParser isSectionEndFlag:aLineStr]) {
        if ([aLineStr hasPrefix: @"# Arch:"]) {//found code type
            NSRange range = [aLineStr rangeOfString: @":"];
            range.location += 2;
            range.length = aLineStr.length - range.location;
            NSString *arcTypeStr = [[aLineStr substringWithRange: range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [[NSNotificationCenter defaultCenter] postNotificationName: ARC_TYPE_FIOUND_NOTIFICATION  object: arcTypeStr];
        }
        if ([_linkMapParser isSectionStartFlag:aLineStr]) {
            
            [_linkMapParser startSubParserWithStartFlag: aLineStr];
            aLineStr = [_linkMapParser lastLinkMapLineLog];
            
            continue;
        }
        
        aLineStr = [_textFileReader readLine];
    }
    [_linkMapParser updateAnalyzeProgress: 1];
}

- (void)outputAnalysisResults
{
    [_linkMapParser outputObjectFileSize];
}

- (void)constructFileReader
{
    if (_textFileReader) {
        self.textFileReader = nil;
    }
    _linkMapParser = [[GSLinkMapParser alloc] init];
    _textFileReader = [[DDFileReader alloc] initWithFilePath: _selectedFilePath];
    _linkMapParser.linkMapfileReader = _textFileReader;
    
}

- (void)constructFileSelect
{
    if (_fileSelectPanel == nil) {
        _fileSelectPanel = [[NSOpenPanel alloc] init];
        [_fileSelectPanel setCanChooseFiles: YES];
        [_fileSelectPanel setCanChooseDirectories: NO];
        [_fileSelectPanel setAllowsMultipleSelection: NO];
        [_fileSelectPanel setTreatsFilePackagesAsDirectories: YES];
//        [_fileSelectPanel setAllowedFileTypes:@[@"txt"]];
    }
}

- (void)startAnalyExcuteFile {
    [[NSNotificationCenter defaultCenter] postNotificationName: ANALYZE_BEGIN_NOTIFICATION  object: self.linkMapFilePath];
}

- (void)startAnylyUnused {
    if ([self.excuteFilePath length] == 0) {
        return;
    }
    [self.unUsedSelectorList removeAllObjects];
    [self.unUsedClassList removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self startAnalyUsedSelector];
        [self startAnalyUsedClass];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.segment.enabled = YES;
            [self buildDataSource];
        });
    });
}


- (void)startAnalyUsedSelector {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/otool"];
    
    NSMutableArray *argvals = [NSMutableArray array];
    
    [argvals addObject:@"-V"];
    [argvals addObject:@"-s"];
    [argvals addObject:@"__DATA"];
    [argvals addObject:@"__objc_selrefs"];
    [argvals addObject:self.excuteFilePath];
    [argvals addObject:@"-arch"];
    [argvals addObject:self.arcTypeTextField.stringValue];
    
    [task setArguments:argvals];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    // Run task
    [task launch];
    
    // Read the response
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // See if we can create a lines array
    if (string.length) {
        [self anylyzeUsedMethodWithData:string];
    }
}

- (void)startAnalyUsedClass {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/otool"];
    
    NSMutableArray *argvals = [NSMutableArray array];
    
    [argvals addObject:@"-V"];
    [argvals addObject:@"-o"];
    [argvals addObject:self.excuteFilePath];
    [argvals addObject:@"-arch"];
    [argvals addObject:self.arcTypeTextField.stringValue];
    
    [task setArguments:argvals];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    // Run task
    [task launch];
    
    // Read the response
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self anylyzeUsedClassWithData:string];
}


#pragma mark - DataSource

- (void)buildDataSource {
    
    [self.dataSource removeAllObjects];
    
    
    switch (self.segment.selectedSegment) {
        case ESourceSegmentAll: {
            [self buildAllSource];
        }
            break;
        case ESourceSegmentUnusedClass: {
            [self buildUnUsedClass];
        }
            break;
        case ESourceSegmentUnusedSelector: {
            [self buildUnUsedSelector];
        }
            break;
        default:
            break;
    }
    

    [self.dataSource sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj2 valueForKey:@"size"] compare:[obj1 valueForKey:@"size"]];
    }];
    
    _fileSizeDesc = YES;
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.tableView reloadData];
        [self.tableView scrollRowToVisible:0];
        [self updateUI];
    });

}

- (void) buildAllSource {
    switch (self.level) {
        case EnumLevelAll: {
            self.totoalSize = 0;
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:[self.resultList count]];
            for (ObjectFileItem *info in self.resultList) {
                ModuleItem *item = [resultDic objectForKey:info.module];
                if (item == nil) {
                    item = [ModuleItem new];
                    item.name = info.module;
                    item.fileTypeName = info.fileTypeName;
                    [resultDic setObject:item forKey:info.module];
                }
                
                [item.objectsList addObject:info];
                item.size += info.size;
                self.totoalSize += info.size;
            }
            [self.dataSource addObjectsFromArray:[resultDic allValues]];
        }
            
            break;
        case EnumLevelModule: {
            ModuleItem *item = [self.itemsQueue lastObject];
            [self.dataSource addObjectsFromArray:item.objectsList];
        }
            
            break;
        case EnumLevelObjct: {
            ObjectFileItem *item = [self.itemsQueue lastObject];
            [self.dataSource addObjectsFromArray:[item.sectionDictionary allValues]];
        }
            break;
            
        case EnumLevelFunction: {
            ObjectSecionItem *item = [self.itemsQueue lastObject];
            [self.dataSource addObjectsFromArray:item.objectsList];
        }
            break;
        default:
            break;
    }
    
}

- (void)buildUnUsedClass {
    [self.dataSource addObjectsFromArray:self.unUsedClassList];
}

- (void)buildUnUsedSelector {
    [self.dataSource addObjectsFromArray:self.unUsedSelectorList];
}

#pragma mark - UI
- (void)updateUI {
    self.titleTextField.stringValue = [self getTitle];
    self.resultTextField.stringValue = [self getResult];
    switch (self.level) {
        case EnumLevelAll: {
            self.backButtion.hidden = YES;
        }
            break;
        case EnumLevelModule: {
            self.backButtion.hidden = NO;
        }
            break;
        case EnumLevelObjct:
            self.backButtion.hidden = NO;
            break;
        case EnumLevelFunction:
            self.backButtion.hidden = NO;
            break;
        default:
            self.backButtion.hidden = NO;
            break;
    }
    
}

- (NSString *)getTitle {
    NSMutableString *title = [NSMutableString stringWithString:@"总览"];
    for (id obj in self.itemsQueue) {
        NSString *name = [obj valueForKey:@"name"];
        [title appendFormat:@"/%@",name];
    }
    return title;
}

- (NSString *)getResult {
    id obj = [self.itemsQueue lastObject];
    NSString *size = [NSString stringWithFormat:@"%@",@(self.totoalSize)];
    if (obj) {
        size = [NSString stringWithFormat:@"%@",[obj valueForKey:@"size"]];
    }
    
    return [NSString stringWithFormat:@"分析结果(byte):%@",size];
}

# pragma mark - Anylyze

- (void)anylyzeUsedMethodWithData:(NSString *)string {
    if (string.length) {
        //数据清空
        for (ObjectFileItem *file in self.resultList) {
            [file.usedMethod removeAllObjects];
            [file.unUsedMethod removeAllObjects];
        }
        
        //解析 0000000100dcd9c0  __TEXT:__objc_methname:alloc
        NSArray *lines = [string componentsSeparatedByString:@"\n"];
        NSString *regexStr = @"(.+?)\\s+__TEXT:__objc_methname:(.+)";
        NSRegularExpression* regexExpression = [NSRegularExpression regularExpressionWithPattern:regexStr options:NSRegularExpressionCaseInsensitive error:nil];
        
        
        int objIndex = 0; //扫描的obj的索引
        int methodIndex = 0; //扫描到的方法索引
        
        // 解析出来使用到的方法
        for (NSString *line in lines) {
            @autoreleasepool {
                if (objIndex >= [self.resultList count]) {
                    break;
                }
                
                NSArray* matchs = [regexExpression matchesInString:line options:0 range:NSMakeRange(0, line.length)];
                
                if (matchs == nil || [matchs count] == 0) {
                    continue;
                }
                
                NSTextCheckingResult *checkingResult = [matchs objectAtIndex:0];
                
                if ([checkingResult numberOfRanges] < 3) {
                    continue;
                }
                
                NSString *startAddressStr = [line substringWithRange:[checkingResult rangeAtIndex:1]];
                NSString *method = [line substringWithRange:[checkingResult rangeAtIndex:2]];
                long startAddress = strtoul([startAddressStr UTF8String], 0, 16);
                
                
                ObjectSecionItem *section = nil;
                ObjectFileItem *obj = nil;
                
                //需要找到对应哪个类的起始地址
                while (objIndex < [self.resultList count]) {
                    obj = [self.resultList objectAtIndex:objIndex];
                    section = [obj.sectionDictionary objectForKey:@"__objc_selrefs"];
                    MethodFileItem *method = [section.objectsList lastObject];
                    if (method.startAddress < startAddress) {
                        objIndex ++;
                        methodIndex = 0;
                    }else {
                        break;
                    }
                }
                
                if (objIndex >= [self.resultList count]) {
                    break;
                }
                
                //数据其实是一一对应的，如果没找到可能是异常了
                MethodFileItem *methodItem = [section.objectsList objectAtIndex:methodIndex];
                if (methodItem.startAddress == startAddress) {
                    methodItem.name = method;
                    [obj.usedMethod setObject:methodItem forKey:method];
                    methodIndex ++;
                    continue;
                }
                
                for (int j = 0; j < [section.objectsList count]; j ++) {
                    MethodFileItem *methodItem = [section.objectsList objectAtIndex:j];
                    if (methodItem.startAddress == startAddress) {
                        //获取到
                        methodIndex = j;
                        [obj.usedMethod setObject:methodItem forKey:method];
                        break;
                    }
                }
                
            }
        }
        
        
        
        //填充数据
        for (ObjectFileItem *obj in self.resultList) {
            ObjectSecionItem *allIvarSection = [obj.sectionDictionary objectForKey:@"__objc_ivar"];
            
            for (MethodFileItem *method  in allIvarSection.objectsList) {
                NSRange range = [method.name rangeOfString:@"." options:NSBackwardsSearch];
                if (range.location == NSNotFound) {
                    continue;
                }
                
                //从_开始 0x100DF2014	0x00000004	[ 16] _OBJC_IVAR_$_AFSecurityPolicy._pinnedPublicKeys
                //0x100DF44BC	0x00000004	[723] _OBJC_IVAR_$_HFDataBaseCore.dbPath
                
                NSString *methodStr = [method.name substringFromIndex:range.location + 1];
                if ([methodStr hasPrefix:@"_"]) {
                    methodStr = [methodStr substringFromIndex:1];
                    if ([methodStr length] > 1) {
                        NSString *_methodStr = [NSString stringWithFormat:@"_%@",methodStr];
                        NSString *setMethod = [NSString stringWithFormat:@"set%@%@:",[methodStr substringToIndex:1].uppercaseString,[methodStr substringFromIndex:1]];
                        
                        [obj.usedMethod setObject:method forKey:_methodStr];
                        [obj.usedMethod setObject:method forKey:setMethod];
                    }
                }
                [obj.usedMethod setObject:method forKey:methodStr];
                
            }
            
            ObjectSecionItem *allClassSection = [obj.sectionDictionary objectForKey:@"__objc_methname"];
            NSMutableDictionary *usedMethod = obj.usedMethod;
            for (MethodFileItem *method in allClassSection.objectsList) {
                NSString *methodStr = [method.name substringFromIndex:@"literal string: ".length];
                if ([usedMethod objectForKey:methodStr]) {
                    continue;
                }
            
                [obj.unUsedMethod setObject:method forKey:methodStr];
                
                
                MethodFileItem *unUsedMethod = [MethodFileItem new];
                unUsedMethod.size = method.size;
                unUsedMethod.fileTypeName = method.fileTypeName;
                unUsedMethod.startAddress = method.startAddress;
                unUsedMethod.name = [NSString stringWithFormat:@"[%@ %@]",obj.name,methodStr];
                
                [self.unUsedSelectorList addObject:unUsedMethod];
            }
            
            if ([obj.unUsedMethod count] > 0) {
                ObjectSecionItem *unusedSection = [[ObjectSecionItem alloc] init];
                unusedSection.name = @"Z__unused_selector";
                unusedSection.fileTypeName = @"Custom";
                unusedSection.size = [obj.unUsedMethod count];
                [unusedSection.objectsList addObjectsFromArray:[obj.unUsedMethod allValues]];
                [obj.sectionDictionary setObject:unusedSection forKey:@"Z__unused_selector"];
            }
            
            
            if ([obj.usedMethod count] > 0) {
                ObjectSecionItem *usedSection = [[ObjectSecionItem alloc] init];
                usedSection.name = @"Z__used_selector";
                usedSection.fileTypeName = @"Custom";
                usedSection.size = [obj.usedMethod count];
                [usedSection.objectsList addObjectsFromArray:[obj.usedMethod allValues]];
                [obj.sectionDictionary setObject:usedSection forKey:@"Z__used_selector"];
            }
        
        }
        
    }
}

- (void)anylyzeUsedClassWithData:(NSString *)string {
    if (string.length == 0) {
        return;
    }
    
    for (ObjectFileItem *file in self.resultList) {
        [file.usedClass removeAllObjects];
    }
    
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    NSUInteger lineNumber = 0;
    
    //计算引用到的class列表
    for (lineNumber = 0; lineNumber < [lines count]; lineNumber ++) {
        NSString *line = [lines objectAtIndex:lineNumber];
        if ([line isEqualToString:@"Contents of (__DATA,__objc_classrefs) section"]) {
            lineNumber ++;
            break;
        }
    }
    
    NSString *regexStr = @"(.+?)\\s+(.+?)\\s+_OBJC_.+_\\$_(.+)";
    NSRegularExpression* regexExpression = [NSRegularExpression regularExpressionWithPattern:regexStr options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSMutableDictionary *usedClassDic = [NSMutableDictionary dictionary];
    
    
    int objIndex = 0; //扫描的obj的索引
    int methodIndex = 0; //扫描到的方法索引
    
    for (NSUInteger i = lineNumber; i < [lines count]; i++) {
        NSString *line = [lines objectAtIndex:i];
        
        if ([line hasPrefix:@"contents of"]) {
            break;
        }
        
        NSArray* matchs = [regexExpression matchesInString:line options:0 range:NSMakeRange(0, line.length)];
        if ([matchs count] < 1) {
            continue;
        }
        NSTextCheckingResult *checkingResult = [matchs objectAtIndex:0];
        
        if ([checkingResult numberOfRanges] < 4) {
            continue;
        }
        
        NSString *startAddressStr = [line substringWithRange:[checkingResult rangeAtIndex:1]];
        NSString *method = [line substringWithRange:[checkingResult rangeAtIndex:3]];
        long startAddress = strtoul([startAddressStr UTF8String], 0, 16);
        
        [usedClassDic setObject:method forKey:method];
        
        
        ObjectSecionItem *section = nil;
        ObjectFileItem *obj = nil;
        
        //需要找到对应哪个类的起始地址
        while (objIndex < [self.resultList count]) {
            obj = [self.resultList objectAtIndex:objIndex];
            section = [obj.sectionDictionary objectForKey:@"__objc_classrefs"];
            MethodFileItem *method = [section.objectsList lastObject];
            if (method.startAddress < startAddress) {
                objIndex ++;
                methodIndex = 0;
            }else {
                break;
            }
        }
        
        if (objIndex >= [self.resultList count]) {
            break;
        }
        
        
        //数据其实是一一对应的，如果没找到可能是异常了
        MethodFileItem *methodItem = [section.objectsList objectAtIndex:methodIndex];
        if (methodItem.startAddress == startAddress) {
            methodItem.name = method;
            [obj.usedClass setObject:methodItem forKey:method];
            methodIndex ++;
            continue;
        }
        
        for (int j = 0; j < [section.objectsList count]; j ++) {
            MethodFileItem *methodItem = [section.objectsList objectAtIndex:j];
            if (methodItem.startAddress == startAddress) {
                //获取到
                methodItem.name = method;
                methodIndex = j;
                [obj.usedClass setObject:methodItem forKey:method];
                break;
            }
        }
    }
    
    
    //计算下用到的protocol
    
    for (ObjectFileItem *obj in self.resultList) {
    
        ObjectSecionItem *allProtocol = [obj.sectionDictionary objectForKey:@"__objc_protolist"];
        if ([allProtocol.objectsList count] == 0) {
            continue;
        }
        
        for (MethodFileItem *methodItem in allProtocol.objectsList) {
            //l_OBJC_LABEL_PROTOCOL_$_NSObject
            if (![methodItem.name hasPrefix:@"l_OBJC_LABEL_PROTOCOL_$_"]) {
                continue;
            }
            NSString *className = [methodItem.name substringFromIndex:@"l_OBJC_LABEL_PROTOCOL_$_".length];
            if (className.length == 0) {
                continue;
            }
            
            [obj.usedClass setObject:methodItem forKey:className];
            [usedClassDic setObject:methodItem forKey:className];
        }
    }
    
    
    NSMutableDictionary *unusedClass = [NSMutableDictionary dictionaryWithCapacity:[usedClassDic count]];
    
    for (ObjectFileItem *obj in self.resultList) {

        ObjectSecionItem *allClassList = [obj.sectionDictionary objectForKey:@"__objc_classname"];
        if ([allClassList.objectsList count] == 0) {
            continue;
        }
        
        for (MethodFileItem *methodItem in allClassList.objectsList) {
            //literal string: NSObject
            NSString *className = [methodItem.name substringFromIndex:@"literal string: ".length];
            if (className.length == 0) {
                continue;
            }
            if (![usedClassDic objectForKey:className]) {
                obj.hasUesd = NO;
                [obj.unUsedClass setObject:methodItem forKey:className];
                [unusedClass setObject:methodItem forKey:className];
            }
        }
        
        if ([obj.usedClass count] > 0) {
            ObjectSecionItem *usedSection = [[ObjectSecionItem alloc] init];
            usedSection.name = @"Z__used_class";
            usedSection.fileTypeName = @"Custom";
            usedSection.size = [obj.usedClass count];
            [usedSection.objectsList addObjectsFromArray:[obj.usedClass allValues]];
            [obj.sectionDictionary setObject:usedSection forKey:@"Z__used_class"];
        }
        
        if ([obj.unUsedClass count] > 0) {
            ObjectSecionItem *unusedSection = [[ObjectSecionItem alloc] init];
            unusedSection.name = @"Z__unused_class";
            unusedSection.fileTypeName = @"Custom";
            unusedSection.size = [obj.unUsedClass count];
            [unusedSection.objectsList addObjectsFromArray:[obj.unUsedClass allValues]];
            [obj.sectionDictionary setObject:unusedSection forKey:@"Z__unused_class"];
        }
    }
    
    [self.unUsedClassList addObjectsFromArray:[unusedClass allValues]];
}



@end
