//
//  BCButtonModel.m
//  WKWebViewOC
//
//  Created by kingly on 2017/11/2.
//  Copyright © 2017年 Bamboocloud Co., Ltd. All rights reserved.
//

#import "BCButtonModel.h"
#import <YYKit/YYKit.h>

@implementation BCButtonModel

/**
 * @brief 重写json转换方法
 */
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    
    _sub_button    =  [NSArray modelArrayWithClass:[BCSubButtonModel class] json:dic[@"sub_button"]];

    return YES;
}

@end
