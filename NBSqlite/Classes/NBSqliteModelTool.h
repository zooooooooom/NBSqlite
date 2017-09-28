//
//  NBSqliteModelTool.h
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NBColumnNameToValueRelationType) {
    NBColumnNameToValueRelationTypeMore,    // 大于
    NBColumnNameToValueRelationTypeLess,    // 小于
    NBColumnNameToValueRelationTypeEqual,   //等于
    NBColumnNameToValueRelationTypeMoreEqual,   // 大于等于
    NBColumnNameToValueRelationTypeLessEqual,   // 小于等于
};

@interface NBSqliteModelTool : NSObject

/**
 根据类名创建表
 */
+ (BOOL)createTable:(Class)cls uid:(NSString *)uid;

/**
 判断是否需要更新表格
 */
+ (BOOL)isTableRequiredUpdate:(Class)cls uid:(NSString *)uid;

/**
 更新数据库表
 */
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid;

/**
 保存或者更新模型
 */
+ (BOOL)saveOrUpdateModel:(id)model uid:(NSString *)uid;

/**
 删除指定的模型
 */
+ (BOOL)deleteModel:(id)model uid:(NSString *)uid;

/**
 根据条件来删除
  age > 19
  score <= 10 and xxx
 */
+ (BOOL)deleteModel:(Class)cls whereStr:(NSString *)whereStr uid:(NSString *)uid;


// score > 10 or name = 'xx'

/**
 根据关系删除

 @param cls 类名
 @param name 列名(也就是属性名)
 @param relation 关系
 @param value 值
 @param uid 用户
 @return 是否成功
 */
+ (BOOL)deleteModel:(Class)cls columnName:(NSString *)name relation:(NBColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid;

// @[@"score", @"name"] @[@">", @"="] @[@"10", @"xx"]  notandnone
//+ (BOOL)deleteModels:(Class)cls columnNames:(NSArray *)names relations:(NSArray *)relations values:(NSArray *)values naos:(NSArray *)naos uid:(NSArray *)uid;


/**
 根据sql语句删除
 */
+ (BOOL)deleteWithSql:(NSString *)sql uid:(NSString *)uid;

/**
 查询所有的模型
 */
+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid;

/**
 要查询的模型类

 @param cls 类名
 @param name 列名
 @param relation 关系
 @param value 对应的值
 @param uid 用户机制
 @return 查询的结果
 */
+ (NSArray *)queryModels:(Class)cls columnName:(NSString *)name relation:(NBColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid;

/**
 根据sql语句去查询结果
 */
+ (NSArray *)queryModels:(Class)cls WithSql:(NSString *)sql uid:(NSString *)uid;

@end
