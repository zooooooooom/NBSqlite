//
//  NBTableTool.m
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "NBTableTool.h"
#import "NBModelTool.h"
#import "NBSqliteTool.h"

@implementation NBTableTool

+ (NSArray *)tableSortedColumnNames:(Class)cls uid:(NSString *)uid
{
    // 1.获取表名
    NSString *tableName = [NBModelTool tableName:cls];
    
    // CREATE TABLE XMGStu(age integer,stuNum integer,score real,name text, primary key(stuNum))
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'", tableName];
    
    // 这里可以确定只会取到一条记录
    NSMutableDictionary *dic = [NBSqliteTool querySql:queryCreateSqlStr uid:uid].firstObject;
    NSString *createTableSql = [dic[@"sql"] lowercaseString];
    if (createTableSql.length == 0) {
        return nil;
    }
    
    // 下面防错处理
    createTableSql = [createTableSql stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    // 用括号分割自己创建的sql语句
    // CREATE TABLE XMGStu(age integer,stuNum integer,score real,name text, primary key(stuNum))
    NSString *nameTypeStr = [createTableSql componentsSeparatedByString:@"("][1];
    
    // 分割成一个集合
    NSArray *nameTypeArray = [nameTypeStr componentsSeparatedByString:@","];
    
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *nameType in nameTypeArray) {
        
        // 过滤primary
        if ([[nameType lowercaseString] containsString:@"primary"]) { continue; }
        
        // 通过数据库软件主动修改表结构的时候会改变数据库创建语句
        NSString *nameType2 = [nameType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        
        NSString *name = [nameType2 componentsSeparatedByString:@" "].firstObject;
        
        [names addObject:name];
    }
    
    // 根据字符串排序数组
    [names sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    return names;
}

+ (BOOL)isTableExists:(Class)cls uid:(NSString *)uid
{
    NSString *tableName = [NBModelTool tableName:cls];
    NSString *sql = @"select name from sqlite_master";
    NSArray <NSDictionary *>*resultSet = [NBSqliteTool querySql:sql uid:uid];
    __block BOOL isTableExists = NO;
    [resultSet enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj[@"name"] lowercaseString] isEqualToString:[tableName lowercaseString]]) {
            isTableExists = YES;
        }
    }];
    return isTableExists;
}

@end
