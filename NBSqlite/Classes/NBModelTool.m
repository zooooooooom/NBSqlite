//
//  NBModelTool.m
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "NBModelTool.h"
#import <objc/runtime.h>
#import "NBModelProtocol.h"

@implementation NBModelTool

+ (NSString *)tableName:(Class)cls
{
    return NSStringFromClass(cls);
}

+ (NSString *)tmpTableName:(Class)cls
{
    return [NSStringFromClass(cls) stringByAppendingString:@"_tmp"];
}

/**
 * 根据类名,获取所有的 成员变量类型(OC中的类型) 以字典的形式 key是model中的属性 value是类型
 */
+ (NSDictionary *)classIvarNameTypeDic:(Class)cls
{
    // 获取这个类中所有的成员变量以及类型
    unsigned int outCount = 0;
    Ivar *varList = class_copyIvarList(cls, &outCount);
    
    NSArray *ignoreNames = nil;
    if ([cls respondsToSelector:@selector(ignoreColumnNames)]) {
        ignoreNames = [cls ignoreColumnNames];
    }
    
    NSMutableDictionary *nameTypeDic = [NSMutableDictionary dictionary];
    for (int i = 0; i < outCount; i++) {
        Ivar ivar = varList[i];
        
        // 1. 获取成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String: ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        
        // 1.5 这里排除不需要存储的类型
        if ([ignoreNames containsObject:ivarName]) { continue; }
        
        // 2. 获取成员变量类型
        NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        
        type = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        
        [nameTypeDic setValue:type forKey:ivarName];
    }
    
    return nameTypeDic;
}

// 所有的成员变量, 以及成员变量映射到数据库里面对应的类型 (根据所获取成员变量类型(OC中的类型)返回对应的数据库中的类型)
+ (NSDictionary *)classIvarNameSqliteTypeDic:(Class)cls;
{
    NSMutableDictionary *dic = [[self classIvarNameTypeDic:cls] mutableCopy];
    
    NSDictionary *typeDic = [self ocTypeToSqliteTypeDic];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        dic[key] = typeDic[obj];
    }];
    
    return dic;
}

+ (NSString *)columnNamesAndTypesStr:(Class)cls
{
    // 1.获取OC成员变量到sqlite的映射
    NSDictionary *nameTypeDic = [self classIvarNameSqliteTypeDic:cls];
    
    NSMutableArray *result = [NSMutableArray array];
    [nameTypeDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        
        [result addObject:[NSString stringWithFormat:@"%@ %@", key, obj]];
    }];
    
    return [result componentsJoinedByString:@","];
}

+ (NSArray *)allTableSortedIvarNames:(Class)cls
{
    NSDictionary *dic = [self classIvarNameTypeDic:cls];
    NSArray *keys = dic.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return keys;
}


#pragma mark - 私有的方法
+ (NSDictionary *)ocTypeToSqliteTypeDic {
    return @{
             @"d": @"real", // double
             @"f": @"real", // float
             
             @"i": @"integer",  // int
             @"q": @"integer", // long
             @"Q": @"integer", // long long
             @"B": @"integer", // bool
             
             @"NSData": @"blob",
             @"NSDictionary": @"text",
             @"NSMutableDictionary": @"text",
             @"NSArray": @"text",
             @"NSMutableArray": @"text",
             
             @"NSString": @"text"
             };
}
@end
