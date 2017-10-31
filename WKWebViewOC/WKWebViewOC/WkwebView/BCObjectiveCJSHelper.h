//
//  BCObjectiveCJSHelper.h
//  WKWebViewOC
//
//  Created by kingly on 2017/10/31.
//  Copyright © 2017年 Bamboocloud Co., Ltd.. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#define KWebGetDeviceID @"timefor"      //获取APP的端的设备ID

@protocol BCObjectiveCJSHelperDelegate <NSObject>
@optional
@end

@interface BCObjectiveCJSHelper : NSObject<WKScriptMessageHandler>
@property (nonatomic, weak) id<BCObjectiveCJSHelperDelegate> delegate;
@property (nonatomic, weak) WKWebView *webView;

/**
 指定初始化方法
 
 @param delegate 代理
 @param vc 实现WebView的VC
 @return 返回自身实例
 */
- (instancetype)initWithDelegate:(id<BCObjectiveCJSHelperDelegate>)delegate vc:(UIViewController *)vc;

@end
