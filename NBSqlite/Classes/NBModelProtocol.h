//
//  NBModelProtocol.h
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBModelProtocol <NSObject>
@required // 必须实现

/**
 告诉我作为主键的字段
 */
+ (NSString *)primaryKey;

@optional

/**
 需要忽略的属性名
 */
+ (NSArray *)ignoreColumnNames;

/**
 新字段名称-> 旧的字段名称的映射表格
 
 @return 映射表格
 */
+ (NSDictionary *)newNameToOldNameDic;

@end
