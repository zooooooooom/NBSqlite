//
//  NBTableTool.h
//  sqlite封装测试
//
//  Created by mac on 2017/9/27.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBTableTool : NSObject

/**
 获取排序好的表结构数组
 */
+ (NSArray *)tableSortedColumnNames:(Class)cls uid:(NSString *)uid;


/**
 判断表格是否存在
 */
+ (BOOL)isTableExists:(Class)cls uid:(NSString *)uid;

@end
