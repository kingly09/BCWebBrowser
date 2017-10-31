//
//  WKWebViewController.m
//  WKWebViewOC

#import "WKWebViewController.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WebKit.h>

typedef enum{
    loadWebURLString = 0,
    loadLocalWebHTMLString,
    POSTWebURLString,
    automaticLoginWebURLSring,
}wkWebLoadType;

static void *WkwebBrowserContext = &WkwebBrowserContext;

@interface WKWebViewController ()
<WKNavigationDelegate,
WKUIDelegate,
WKScriptMessageHandler,
UINavigationControllerDelegate,
UINavigationBarDelegate,
UIScrollViewDelegate>

@property (nonatomic, strong) WKWebView *wkWebView;
//设置加载进度条
@property (nonatomic,strong) UIProgressView *progressView;
//仅当第一次的时候加载本地JS
@property(nonatomic,assign) BOOL needLoadJSPOST;
//是否需要注入js代码
@property(nonatomic,assign) BOOL needInjectJS;
//设置字体大小
@property(nonatomic,assign) float minimumFontSize;
//网页加载的类型
@property(nonatomic,assign) wkWebLoadType loadType;
//保存的网址链接
@property (nonatomic, copy) NSString *URLString;
//保存POST请求体
@property (nonatomic, copy) NSString *postData;
//注入js代码
@property (nonatomic, copy) NSString *injectJSCode;
//保存请求链接
@property (nonatomic)NSMutableArray* snapShotsArray;
//返回按钮
@property (nonatomic)UIBarButtonItem* customBackBarItem;
//关闭按钮
@property (nonatomic)UIBarButtonItem* closeButtonItem;

@end

@implementation WKWebViewController

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //加载web页面
    [self webViewloadURLType];
    
    //添加到主控制器上
    [self.view addSubview:self.wkWebView];
    
    //添加进度条
    [self.view addSubview:self.progressView];
    
    //添加右边刷新按钮
    UIBarButtonItem *roadLoad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(roadLoadClicked)];
    self.navigationItem.rightBarButtonItem = roadLoad;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (_isNavHidden == YES) {
        self.navigationController.navigationBarHidden = YES;
        //创建一个高20的假状态栏
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
        //设置成绿色
        statusBarView.backgroundColor=[UIColor whiteColor];
        // 添加到 navigationBar 上
        [self.view addSubview:statusBarView];
    }else{
        self.navigationController.navigationBarHidden = NO;
    }
}
-(void)viewWillDisappear:(BOOL)animated{
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"WXPay"];
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
}

//注意，观察的移除
-(void)dealloc {
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [self.wkWebView removeObserver:self forKeyPath:@"title"];
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"WXPay"];
}


// 清理缓存的方法，这个方法会清除缓存类型为HTML类型的文件
- (void)clearHtmlCache {
    /* 取得Library文件夹的位置*/
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)[0];
    /* 取得bundle id，用作文件拼接用*/
    NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleIdentifier"];
    /*
     * 拼接缓存地址，具体目录为App/Library/Caches/你的APPBundleID/fsCachedData
     */
    NSString *webKitFolderInCachesfs = [NSString stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
    
    NSError *error;
    /* 取得目录下所有的文件，取得文件数组*/
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //    NSArray *fileList = [[NSArray alloc] init];
    //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:webKitFolderInCachesfs error:&error];
    /* 遍历文件组成的数组*/
    for(NSString * fileName in fileList){
        /* 定位每个文件的位置*/
        NSString * path = [[NSBundle bundleWithPath:webKitFolderInCachesfs] pathForResource:fileName ofType:@""];
        /* 将文件转换为NSData类型的数据*/
        NSData * fileData = [NSData dataWithContentsOfFile:path];
        /* 如果FileData的长度大于2，说明FileData不为空*/
        if(fileData.length >2){
            /* 创建两个用于显示文件类型的变量*/
            int char1 =0;
            int char2 =0;
            
            [fileData getBytes:&char1 range:NSMakeRange(0,1)];
            [fileData getBytes:&char2 range:NSMakeRange(1,1)];
            /* 拼接两个变量*/
            NSString *numStr = [NSString stringWithFormat:@"%i%i",char1,char2];
            /* 如果该文件前四个字符是6033，说明是Html文件，删除掉本地的缓存*/
            if([numStr isEqualToString:@"6033"]){
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",webKitFolderInCachesfs,fileName]error:&error];
                continue;
            }
        }
    }
}

#pragma mark - 加载方式／私有方法

- (void)webViewloadURLType{
    switch (self.loadType) {
        case loadWebURLString:{
            [self loadWebWithURLString:self.URLString];
            break;
        }
        case loadLocalWebHTMLString:{
            //加载本地的HTML
            [self loadLocalHtmlString:self.URLString];
            break;
        }
        case POSTWebURLString:{
            //JS发送POST的Flag，为真的时候会调用JS的POST方法
            self.needLoadJSPOST = YES;
            //POST使用预先加载本地JS方法的html实现，请确认WKJSPOST存在
            [self loadLocalHtmlString:@"WKJSPOST"];
            break;
        }
        case automaticLoginWebURLSring:{
            //为真的时候会调用JS的注入js代码
            self.needInjectJS = YES;
            [self loadWebWithURLString:self.URLString];
            break;
        }
    }
}
// 加载一个WEB的URL地址网页
-(void) loadWebWithURLString:(NSString *)url {
    //创建一个NSURLRequest 的对象,加入缓存机制，缓存时间为30s
    NSURLRequest * Request_zsj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    //加载网页
    [self.wkWebView loadRequest:Request_zsj];
}
// 加载一个本地HTML网页
- (void)loadLocalHtmlString:(NSString *)url{
    //获取JS所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"html"];
    //获得html内容
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //加载js
    [self.wkWebView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
}

// 调用JS发送POST请求
- (void)postRequestWithJS {
    // 拼装成调用JavaScript的字符串
    NSString *jscript = [NSString stringWithFormat:@"post('%@','%@');", self.URLString, self.postData];
    // 调用JS代码
    [self.wkWebView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
    }];
}
// 给所有的video添加 webkit-playsinline（在这个属性是ios 10中设置可以让视频在小窗内播放）
-(void)addWebkitplaysinlineJsCode {
    // 拼装成调用JavaScript的字符串
    NSString *jscript = [NSString stringWithFormat:@"var eles = document.getElementsByTagName('video');if(eles.length > 0){for (var i = 0; i < eles.length; i++) {document.getElementsByTagName('video')[i].setAttribute('webkit-playsinline','true'); }}"];
    // 调用JS代码
    [self.wkWebView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
        
    }];
}

// 调用JS发送提示框请求
- (void)alertRequestWithJS {
    // 拼装成调用JavaScript的字符串
    NSString *jscript = [NSString stringWithFormat:@"testAlert();"];
    // 调用JS代码
    [self.wkWebView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
        
    }];
}
// 调用JS发送注入js代码请求
-(void)requestInjectJSCode {
    if (self.injectJSCode.length == 0 || self.injectJSCode == nil) {
        return;
    }
    //设置JS
//    NSString *inputValueJS = @"var psel = document.getElementById('uin');psel.value = '测试自动输入账号121';var pswd = document.getElementById('pwd');pswd.value = '123';";
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //执行JS
        [self.wkWebView evaluateJavaScript:self.injectJSCode completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            NSLog(@"value: %@ error: %@", response, error);
        }];
//    });
}

#pragma mark - 点击事件

- (void)roadLoadClicked{
    [self.wkWebView reload];
}

-(void)customBackItemClicked{
    if (self.wkWebView.goBack) {
        [self.wkWebView goBack];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
-(void)closeItemClicked{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 自定义返回/关闭按钮

-(void)updateNavigationItems{
    if (self.wkWebView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;

        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.customBackBarItem,self.closeButtonItem] animated:NO];
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
    }
}
//请求链接处理
-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request{
        NSLog(@"push with request %@",request);
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapShotsArray lastObject] objectForKey:@"request"];
    
    //如果url是很奇怪的就不push
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        NSLog(@"about blank!! return");
        return;
    }
   
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    UIView* currentSnapShotView = [self.wkWebView snapshotViewAfterScreenUpdates:YES];
    [self.snapShotsArray addObject:
     @{@"request":request,@"snapShotView":currentSnapShotView}];
}
#pragma mark - KVO监听事件
//KVO监听进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
                
            }];
        }
    }else if ([keyPath isEqualToString:@"title"]) {
        self.title = self.wkWebView.title;
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 委托方法
#pragma mark - WKNavigationDelegate

//这个是网页加载完成，导航的变化
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"页面加载完成");
    /*
     主意：这个方法是当网页的内容全部显示（网页内的所有图片必须都正常显示）的时候调用（不是出现的时候就调用），，否则不显示，或则部分显示时这个方法就不调用。
     */
    // 判断是否需要加载（仅在第一次加载）
    if (self.needLoadJSPOST) {
        // 调用使用JS发送POST请求的方法
        [self postRequestWithJS];
        // 提示一个框
        //[self alertRequestWithJS];
        //给所有的video添加 webkit-playsinline支持小窗口播放
        [self addWebkitplaysinlineJsCode];
        // 将Flag置为NO（后面就不需要加载了）
        self.needLoadJSPOST = NO;
    }
    // 获取加载网页的标题
    self.title = self.wkWebView.title;
    // 是否需要注入js（仅注入一次）
    if (self.needInjectJS) {
        [self requestInjectJSCode];
        // 将Flag置为NO（后面就不需要加载了）
        self.needInjectJS = NO;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
}

//开始加载
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    //开始加载的时候，让加载进度条显示
    self.progressView.hidden = NO;
    NSLog(@"页面开始加载");
}
// 加载内容
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"内容正在加载当中");
}

//接收到服务器重新配置请求之后再执行(接收到服务器跳转请求之后调用)
-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
     NSLog(@"接收到服务器重新配置请求之后再执行");
}

//API是根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转（在发送请求之前，决定是否跳转）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSLog(@"API是根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转");
//    NSString* orderInfo = [[AlipaySDK defaultService]fetchOrderInfoFromH5PayUrl:[navigationAction.request.URL absoluteString]];
//    if (orderInfo.length > 0) {
//        [self payWithUrlOrder:orderInfo];
//    }
//    //拨打电话
//    //兼容安卓的服务器写法:<a class = "mobile" href = "tel://电话号码"></a>
//    NSString *mobileUrl = [[navigationAction.request URL] absoluteString];
//    mobileUrl = [mobileUrl stringByRemovingPercentEncoding];
//    NSArray *urlComps = [mobileUrl componentsSeparatedByString:@"://"];
//    if ([urlComps count]){
//        
//        if ([[urlComps objectAtIndex:0] isEqualToString:@"tel"]) {
//            
//            UIAlertController *mobileAlert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"拨号给 %@ ？",urlComps.lastObject] preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *suerAction = [UIAlertAction actionWithTitle:@"拨号" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mobileUrl]];
//            }];
//            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//                return ;
//            }];
//            
//            [mobileAlert addAction:suerAction];
//            [mobileAlert addAction:cancelAction];
//            
//            [self presentViewController:mobileAlert animated:YES completion:nil];
//        }
//    }
    
    
    switch (navigationAction.navigationType) {
        case WKNavigationTypeLinkActivated: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        case WKNavigationTypeFormSubmitted: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        case WKNavigationTypeBackForward: {
            break;
        }
        case WKNavigationTypeReload: {
            break;
        }
        case WKNavigationTypeFormResubmitted: {
            break;
        }
        case WKNavigationTypeOther: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        default: {
            break;
        }
    }
    [self updateNavigationItems];
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
    //不允许跳转
    //decisionHandler(WKNavigationActionPolicyCancel);
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSLog(@"decidePolicyForNavigationResponse   ====    %@", navigationResponse);
    decisionHandler(WKNavigationResponsePolicyAllow);
}

// 加载 HTTPS 的链接，需要权限认证时调用  \  如果 HTTPS 是用的证书在信任列表中这不要此代理方法
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

// 内容加载失败时候调用
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"页面加载超时");
}

//跳转失败的时候调用
-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
}

//进度条
-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    
    
}

#pragma mark - WKUIDelegate

// 获取js 里面的提示
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

// js 信息的交流
-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

// runJavaScriptTextInput
// 要求用户输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS 大家注意这个回调的completionHandler参数是字符串
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入框" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor blackColor];
        textField.placeholder = defaultText;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(nil);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
   

}

#pragma mark - WKScriptMessageHandler 拦截执行网页中的JS方法

//拦截执行网页中的JS方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{

    //服务器固定格式写法 window.webkit.messageHandlers.名字.postMessage(内容);
    //客户端写法 message.name isEqualToString:@"名字"]
    if ([message.name isEqualToString:@"WXPay"]) {
        NSLog(@"%@", message.body);
        //调用微信支付方法
//        [self WXPayWithParam:message.body];
    }
}

#pragma mark - 初始化URL/对外扩展方法

- (void)loadWebURLSring:(NSString *)string{
    self.URLString = string;
    self.loadType = loadWebURLString;
}

- (void)loadLocalWebHTMLString:(NSString *)string{
    self.URLString = string;
    self.loadType = loadLocalWebHTMLString;
}

- (void)POSTWebURLSring:(NSString *)string postData:(NSString *)postData{
    self.URLString = string;
    self.postData = postData;
    self.loadType = POSTWebURLString;
}

-(void)automaticLoginWebURLSring:(NSString *)string injectJSCode:(NSString *)JSCode {
    
    self.URLString    = string;
    self.injectJSCode = JSCode;
    self.loadType     = automaticLoginWebURLSring;
    
}

-(void)setupMinimumFontSize:(float)fontSize {
    
    self.minimumFontSize = fontSize;
}

#pragma mark - setter and getter 方法
#pragma mark - 懒加载

- (WKWebView *)wkWebView{
    if (!_wkWebView) {
        
        //设置网页的配置文件
        WKWebViewConfiguration * Configuration = [[WKWebViewConfiguration alloc]init];
        //这个值决定了从这个页面是否可以Air Play
        Configuration.allowsAirPlayForMediaPlayback = YES;
        // 允许在线播放 ,默认使NO。这个值决定了用内嵌HTML5播放视频还是用本地的全屏控制。为了内嵌视频播放，不仅仅需要在这个页面上设置这个属性，还必须的是在HTML中的video元素必须包含webkit-playsinline属性。
       if (@available(iOS 11.0, *)) {
            Configuration.allowsInlineMediaPlayback = YES;
       }else{
            Configuration.allowsInlineMediaPlayback = NO;
       }
        Configuration.allowsInlineMediaPlayback = YES;
        // 创建设置对象
        WKPreferences *preference = [[WKPreferences alloc]init];
        // 设置字体大小(最小的字体大小)
        preference.minimumFontSize = self.minimumFontSize;
        // 设置偏好设置对象
        Configuration.preferences = preference;
        
        // 在iPhone和iPad上默认使YES。这个值决定了HTML5视频可以自动播放还是需要用户去启动播放
        Configuration.requiresUserActionForMediaPlayback = NO;
        // 允许可以与网页交互，选择视图
        Configuration.selectionGranularity = YES;
        // web内容处理池
        Configuration.processPool = [[WKProcessPool alloc] init];
        
        //自定义配置,一般用于 js调用oc方法(OC拦截URL中的数据做自定义操作)
        WKUserContentController * UserContentController = [[WKUserContentController alloc]init];
        // 添加消息处理，注意：self指代的对象需要遵守WKScriptMessageHandler协议，结束时需要移除
        [UserContentController addScriptMessageHandler:self name:@"WXPay"];
        
        //客户端添加meta标签
//        NSString *metaJScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width,initial-scale=1.0,maximum-scale=1.0,minimum-scale=1.0,user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);";
//        WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:metaJScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
//        [UserContentController addUserScript:wkUScript];
        // 是否支持记忆读取
//        Configuration.suppressesIncrementalRendering = YES;
        // 允许用户更改网页的设置
        Configuration.userContentController = UserContentController;
        
        
        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:Configuration];
        _wkWebView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0];
        // 设置代理
        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;
        _wkWebView.scrollView.delegate = self;
        
        NSKeyValueObservingOptions observingOptions = NSKeyValueObservingOptionNew;
        // KVO 监听属性，除了下面列举的两个，还有其他的一些属性，具体参考 WKWebView 的头文件
        //kvo 添加进度监控
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:observingOptions context:WkwebBrowserContext];
        [_wkWebView addObserver:self forKeyPath:@"title" options:observingOptions context:nil];
        
        //开启手势触摸
        _wkWebView.allowsBackForwardNavigationGestures = YES;
        
        // 设置 可以前进 和 后退
        //适应你设定的尺寸
        [_wkWebView sizeToFit];
    }
    return _wkWebView;
}

-(UIBarButtonItem *)customBackBarItem{
    if (!_customBackBarItem) {
        UIImage* backItemImage = [[UIImage imageNamed:@"backItemImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage* backItemHlImage = [[UIImage imageNamed:@"backItemImage-hl"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIButton* backButton = [[UIButton alloc] init];
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [backButton setImage:backItemImage forState:UIControlStateNormal];
        [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
        [backButton sizeToFit];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        if (_isNavHidden == YES) {
            _progressView.frame = CGRectMake(0, 20, self.view.bounds.size.width, 3);
        }else{
            _progressView.frame = CGRectMake(0, 64, self.view.bounds.size.width, 3);
        }
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor greenColor];
    }
    return _progressView;
}

-(UIBarButtonItem *)closeButtonItem{
    if (!_closeButtonItem) {
        _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemClicked)];
    }
    return _closeButtonItem;
}

-(NSMutableArray*)snapShotsArray{
    if (!_snapShotsArray) {
        _snapShotsArray = [NSMutableArray array];
    }
    return _snapShotsArray;
}

@end
