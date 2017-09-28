//
//  NBSqliteModelTool.m
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "NBSqliteModelTool.h"
#import "NBModelTool.h"
#import "NBModelProtocol.h"
#import "NBSqliteTool.h"
#import "NBTableTool.h"

// 关于这个工具类的封装
// 实现方案 2
// 1. 基于配置
// 2. runtime动态获取
@implementation NBSqliteModelTool

/**
 根据类名创建表

 @param cls 类名
 @param uid 用户标识
 */
+ (BOOL)createTable:(Class)cls uid:(NSString *)uid
{
    // 1. 创建表格的sql语句给拼接出来
    // 尽可能多的, 能够自己获取, 就自己获取, 实在判定不了用的意图的, 只能让用户来告诉我们

    // create table if not exists 表名(字段1 字段1类型, 字段2 字段2类型 (约束),...., primary key(字段))
    // 1.1 获取表格名称
    NSString *tableName = [NBModelTool tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSAssert([cls respondsToSelector:@selector(primaryKey)], @"模型需要遵循协议, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    
    // 1.2 获取一个模型里面所有的字段, 以及类型
    NSString *primaryKey = [cls primaryKey];
    
    // 1.2 获取一个模型里面所有的字段, 以及类型
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))", tableName, [NBModelTool columnNamesAndTypesStr:cls], primaryKey];
    
    // 2. 执行
    return [NBSqliteTool deal:createTableSql uid:uid];
}

/**
 判断是否需要更新表
 */
+ (BOOL)isTableRequiredUpdate:(Class)cls uid:(NSString *)uid
{
    NSArray *modelNames = [NBModelTool allTableSortedIvarNames:cls];
    NSArray *tableNames = [NBTableTool tableSortedColumnNames:cls uid:uid];
    
    return ![modelNames isEqualToArray:tableNames];
}

/**
 更新表
 */
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid
{
    // 1. 创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
    NSString *tmpTableName = [NBModelTool tmpTableName:cls];
    NSString *tableName = [NBModelTool tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSAssert([cls respondsToSelector:@selector(primaryKey)], @"模型需要遵循协议, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    
    // 保存需要操作的语句
    NSMutableArray *execSqls = [NSMutableArray array];
    NSString *primaryKey = [cls primaryKey];
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))", tmpTableName, [NBModelTool columnNamesAndTypesStr:cls], primaryKey];
    [execSqls addObject:createTableSql];
    
    // 2. 根据主键, 插入数据
    // insert into xmgstu_tmp(stuNum) select stuNum from xmgstu;
    NSString *insertPrimaryKeyData = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@;", tmpTableName, primaryKey, primaryKey, tableName];
    [execSqls addObject:insertPrimaryKeyData];
    // 3. 根据主键, 把所有的数据更新到新表里面
    NSArray *oldNames = [NBTableTool tableSortedColumnNames:cls uid:uid];
    NSArray *newNames = [NBModelTool allTableSortedIvarNames:cls];
    
    // 4. 获取更名字典
    NSDictionary *newNameToOldNameDic = @{};
    //  @{@"age": @"age2"};
    if ([cls respondsToSelector:@selector(newNameToOldNameDic)]) {
        newNameToOldNameDic = [cls newNameToOldNameDic];
    }

    
    for (NSString *columnName in newNames) {
        NSString *oldName = columnName;
        // 找映射的旧的字段名称
        if ([newNameToOldNameDic[columnName] length] != 0) {
            oldName = newNameToOldNameDic[columnName];
        }
        // 如果老表包含了新的列明, 应该从老表更新到临时表格里面
        if ((![oldNames containsObject:columnName] && ![oldNames containsObject:oldName]) || [columnName isEqualToString:primaryKey]) {
            continue;
        }
        // update 临时表 set 新字段名称 = (select 旧字段名 from 旧表 where 临时表.主键 = 旧表.主键)
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@)", tmpTableName, columnName, oldName, tableName, tmpTableName, primaryKey, tableName, primaryKey];
        [execSqls addObject:updateSql];
    }
    
    NSString *deleteOldTable = [NSString stringWithFormat:@"drop table if exists %@", tableName];
    [execSqls addObject:deleteOldTable];
    
    NSString *renameTableName = [NSString stringWithFormat:@"alter table %@ rename to %@", tmpTableName, tableName];
    [execSqls addObject:renameTableName];
    
    // 执行语句
    return [NBSqliteTool dealSqls:execSqls uid:uid];
}

/**
 保存模型
 */
+ (BOOL)saveOrUpdateModel:(id)model uid:(NSString *)uid
{
    // 如果用户再使用过程中, 直接调用这个方法, 去保存模型
    // 保存一个模型
    Class cls = [model class];
    
    // 1. 判断表格是否存在, 不存在, 则创建
    if (![NBTableTool isTableExists:cls uid:uid]) {
        [self createTable:cls uid:uid];
    }
    
    // 2. 检测表格是否需要更新, 需要, 更新
    if ([self isTableRequiredUpdate:cls uid:uid]) {
        [self updateTable:cls uid:uid];
    }
    
    // 3. 判断记录是否存在, 主键
    // 从表格里面, 按照主键, 进行查询该记录, 如果能够查询到
    NSString *tableName = [NBModelTool tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    NSString *primaryKey = [cls primaryKey];
    id primaryValue = [model valueForKeyPath:primaryKey];

    NSString *checkSql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'", tableName, primaryKey, primaryValue];
    
    NSArray *result = [NBSqliteTool querySql:checkSql uid:uid];
    
    // 获取字段数组
    NSArray *columnNames = [NBModelTool classIvarNameTypeDic:cls].allKeys;

    // 获取值数组
    // model keyPath:
    NSMutableArray *values = [NSMutableArray array];
    for (NSString *columnName in columnNames) {
        id value = [model valueForKeyPath:columnName];
        
        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            // 在这里, 把字典或者数组, 处理成为一个字符串, 保存到数据库里面去
            
            // 字典/数组 -> data
            NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
            
            // data -> nsstring
            value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        [values addObject:value];
    }

    NSInteger count = columnNames.count;
    NSMutableArray *setValueArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSString *name = columnNames[i];
        id value = values[i];
        NSString *setStr = [NSString stringWithFormat:@"%@='%@'", name, value];
        [setValueArray addObject:setStr];
    }
    
    // 更新
    // 字段名称, 字段值
    // update 表名 set 字段1=字段1值,字段2=字段2的值... where 主键 = '主键值'
    NSString *execSql = @"";
    if (result.count > 0) {
        execSql = [NSString stringWithFormat:@"update %@ set %@  where %@ = '%@'", tableName, [setValueArray componentsJoinedByString:@","], primaryKey, primaryValue];
        
        
    }else {
        // insert into 表名(字段1, 字段2, 字段3) values ('值1', '值2', '值3')
        // '   值1', '值2', '值3   '
        // 插入
        // text sz 'sz' 2 '2'
        execSql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')", tableName, [columnNames componentsJoinedByString:@","], [values componentsJoinedByString:@"','"]];
    }
    
    return [NBSqliteTool deal:execSql uid:uid];
}

/**
 删除模型
 */
+ (BOOL)deleteModel:(id)model uid:(NSString *)uid
{
    Class cls = [model class];
    NSString *tableName = [NBModelTool tableName:cls];
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    
    NSString *primaryKey = [cls primaryKey];
    id primaryValue = [model valueForKeyPath:primaryKey];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'", tableName, primaryKey, primaryValue];
    
    return [NBSqliteTool deal:deleteSql uid:uid];
    
}

/**
 根据条件删除模型
 */
+ (BOOL)deleteModel:(Class)cls whereStr:(NSString *)whereStr uid:(NSString *)uid
{
    NSString *tableName = [NBModelTool tableName:cls];
    
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@", tableName];
    if (whereStr.length > 0) {
        deleteSql = [deleteSql stringByAppendingFormat:@" where %@", whereStr];
    }
    
    return [NBSqliteTool deal:deleteSql uid:uid];
}

/**
 根据关系删除模型
 */
+ (BOOL)deleteModel:(Class)cls columnName:(NSString *)name relation:(NBColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid
{
    NSString *tableName = [NBModelTool tableName:cls];
    
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ %@ '%@'", tableName, name, self.ColumnNameToValueRelationTypeDic[@(relation)], value];
    
    // 假设肯定传
    return [NBSqliteTool deal:deleteSql uid:uid];
}

/**
根据sql语句删除
 */
+ (BOOL)deleteWithSql:(NSString *)sql uid:(NSString *)uid
{
    return [NBSqliteTool deal:sql uid:uid];
}

/**
 查询所有的模型
 */
+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid
{
    NSString *tableName = [NBModelTool tableName:cls];
    // 1. sql
    NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
    
    // 2. 执行查询,
    // key value
    // 模型的属性名称, 和属性值
    NSArray <NSDictionary *>*results = [NBSqliteTool querySql:sql uid:uid];
    
    // 3. 处理查询的结果集 -> 模型数组
    return [self parseResults:results withClass:cls];
}

+ (NSArray *)queryModels:(Class)cls columnName:(NSString *)name relation:(NBColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid
{
    NSString *tableName = [NBModelTool tableName:cls];
    // 1. 拼接sql语句
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@' ", tableName, name, self.ColumnNameToValueRelationTypeDic[@(relation)], value];
    
    
    // 2. 查询结果集
    NSArray <NSDictionary *>*results = [NBSqliteTool querySql:sql uid:uid];
    
    return [self parseResults:results withClass:cls];
    
}

+ (NSArray *)queryModels:(Class)cls WithSql:(NSString *)sql uid:(NSString *)uid {
    
    // 2. 查询结果集
    NSArray <NSDictionary *>*results = [NBSqliteTool querySql:sql uid:uid];
    
    return [self parseResults:results withClass:cls];
}

/**
 处理查询的结果
 */
+ (NSArray *)parseResults:(NSArray <NSDictionary *>*)results withClass:(Class)cls {
    
    // 属性名称 -> 类型 dic
    NSDictionary *nameTypeDic = [NBModelTool classIvarNameTypeDic:cls];
    
    // 3. 处理查询的结果集 -> 模型数组
    NSMutableArray *models = [NSMutableArray array];
    for (NSDictionary *modelDic in results) {
        id model = [[cls alloc] init];
        [models addObject:model];
        
        
        [modelDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            // xx NSMutableArray
            // oo NSDictionary
            //            [
            //            "2",
            //            "3"
            //            ]
            NSString *type = nameTypeDic[key];
            //            NSArray
            //            NSMutableArray
            //            NSDictionary
            //            NSMutableDictionary
            id resultValue = obj;
            if ([type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSDictionary"]) {
                
                // 字符串 ->
                NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
                resultValue = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                
            }else if ([type isEqualToString:@"NSMutableArray"] || [type isEqualToString:@"NSMutableDictionary"]) {
                NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
                resultValue = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            }
            
            [model setValue:resultValue forKeyPath:key];
            
        }];

    }
    
    return models;
}

/**
 枚举值的映射(swift中可以直接指定string类型的枚举)
 */
+ (NSDictionary *)ColumnNameToValueRelationTypeDic {
    return @{
             @(NBColumnNameToValueRelationTypeMore):@">",
             @(NBColumnNameToValueRelationTypeLess):@"<",
             @(NBColumnNameToValueRelationTypeEqual):@"=",
             @(NBColumnNameToValueRelationTypeMoreEqual):@">=",
             @(NBColumnNameToValueRelationTypeLessEqual):@"<="
             };
}


@end
