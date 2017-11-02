//
//  BCButtonModel.h
//  WKWebViewOC
//
//  Created by kingly on 2017/11/2.
//  Copyright © 2017年 Bamboocloud Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCSubButtonModel.h"

@protocol BCButtonModel <NSObject>

@end
/**
 一级菜单的模型对象
 */
@interface BCButtonModel : NSObject

@property (nonatomic,copy) NSString  *type;         // 顶级菜单的button的类型
@property (nonatomic,copy) NSString  *name;         // 菜单名称
@property (nonatomic,copy) NSString  *key;          // 菜单对应的key值
@property (nonatomic,copy) NSArray   *sub_button;   // 是有子菜单

@end
