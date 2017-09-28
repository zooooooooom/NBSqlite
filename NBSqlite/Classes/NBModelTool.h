//
//  NBModelTool.h
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBModelTool : NSObject

/**
 根据类名返回表名
 */
+ (NSString *)tableName:(Class)cls;

/**
 临时表名称
 */
+ (NSString *)tmpTableName:(Class)cls;

/**
 所有的成员变量, 以及成员变量对应的类型
 */
+ (NSDictionary *)classIvarNameTypeDic:(Class)cls;

/**
 所有的成员变量, 以及成员变量映射到数据库里面对应的类型
 */
+ (NSDictionary *)classIvarNameSqliteTypeDic:(Class)cls;

/**
 返回这一列的名称和类型的OC字符串
 */
+ (NSString *)columnNamesAndTypesStr:(Class)cls;

/**
 根据类名 转换成员变量为字符串 并排序成数组
 */
+ (NSArray *)allTableSortedIvarNames:(Class)cls;

@end
