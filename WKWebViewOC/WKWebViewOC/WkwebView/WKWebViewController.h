//
//  WKWebViewController.h
//  WKWebViewOC

#import <UIKit/UIKit.h>

@interface WKWebViewController : UIViewController

/** 是否显示Nav */
@property (nonatomic,assign) BOOL isNavHidden;

/**
 加载纯外部链接网页

 @param string URL地址
 */
- (void)loadWebURLSring:(NSString *)string;

/**
 加载本地网页
 
 @param string 本地HTML文件名
 */
- (void)loadLocalWebHTMLString:(NSString *)string;

/**
 加载外部链接POST请求(注意检查 XFWKJSPOST.html 文件是否存在 )
 postData请求块 注意格式：@"\"username\":\"xxxx\",\"password\":\"xxxx\""
 
 @param string 需要POST的URL地址
 @param postData post请求块
 */
- (void)POSTWebURLSring:(NSString *)string postData:(NSString *)postData;

/**
 加载自动登录的链接请求，注入js代码

 @param string 需要登录的表单地址
 @param JSCode 需要植入的js代码,注意js代码不能加入空格 例如： @"var psel = document.getElementById(\"uin\");psel.value = \"测试自动输入账号121\";var pswd = document.getElementById(\"pwd\");pswd.value = '123';"
 */
-(void)automaticLoginWebURLSring:(NSString *)string injectJSCode:(NSString *)JSCode;

@end
