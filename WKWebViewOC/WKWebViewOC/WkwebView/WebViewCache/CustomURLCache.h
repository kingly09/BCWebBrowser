//
//  CustomURLCache.h
//  LocalCache
//
//  Created by Cobb on 15/7/13.
//  Copyright (c) 2015年 Hu Zhiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Util.h"

@interface CustomURLCache : NSURLCache

@property(nonatomic, assign) NSInteger cacheTime;
@property(nonatomic, retain) NSString *diskPath;
@property(nonatomic, retain) NSMutableDictionary *responseDictionary;

- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path cacheTime:(NSInteger)cacheTime;

@end
