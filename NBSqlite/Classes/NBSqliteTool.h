//
//  NBSqliteTool.h
//  Sqlite封装
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 采用用户机制uid确认数据库
 类名确认表
 */
@interface NBSqliteTool : NSObject

/**
 执行单条数据库语句
 */
+ (BOOL)deal:(NSString *)sql uid:(NSString *)uid;

/**
 执行多条数据库语句
 */
+ (BOOL)dealSqls:(NSArray <NSString *>*)sqls uid:(NSString *)uid;

/**
 查询获取所有的表以字典的形式
 */
+ (NSMutableArray <NSMutableDictionary *>*)querySql:(NSString *)sql uid:(NSString *)uid;


@end
