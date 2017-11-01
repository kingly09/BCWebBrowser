//
//  Util.h
//  LocalCache
//
//  Created by Cobb on 15/7/13.
//  Copyright (c) 2015年 Hu Zhiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

+ (NSString *)sha1:(NSString *)str;
+ (NSString *)md5Hash:(NSString *)str;

@end
