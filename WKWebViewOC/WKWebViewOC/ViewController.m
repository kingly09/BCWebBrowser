//
//  ViewController.m
//  WKWebViewOC


#import "ViewController.h"
#import "WKWebViewController.h"

#define POST_JS @"function my_post(path, params) {\
var method = \"POST\";\
var form = document.createElement(\"form\");\
form.setAttribute(\"method\", method);\
form.setAttribute(\"action\", path);\
for(var key in params){\
if (params.hasOwnProperty(key)) {\
var hiddenFild = document.createElement(\"input\");\
hiddenFild.setAttribute(\"type\", \"hidden\");\
hiddenFild.setAttribute(\"name\", key);\
hiddenFild.setAttribute(\"value\", params[key]);\
}\
form.appendChild(hiddenFild);\
}\
document.body.appendChild(form);\
form.submit();\
}"


@interface ViewController ()<UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (assign,nonatomic) BOOL isPost;
//设置字体大小
@property(nonatomic,assign) float minimumFontSize;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"BC WebBrowser浏览器";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadingAction:(UIButton *)sender {
    
    NSString *postData = @"{\"name\": \"libin\",\"password\": \"libin\"}";
    WKWebViewController *web = [[WKWebViewController alloc] init];
    [web POSTWebURLSring:_searchBar.text postData:postData];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];
}

/**
 腾讯企业邮箱自动登录

 @param sender UIButton
 */
- (IBAction)OnClickQiyeEmail:(id)sender {
    
    WKWebViewController *web = [[WKWebViewController alloc] init];
    NSString *inputValueJS = @"var psel = document.getElementById('uin');psel.value = '测试自动输入账号121';var pswd = document.getElementById('pwd');pswd.value = '123';";
    [web automaticLoginWebURLSring:@"https://m.exmail.qq.com/cgi-bin/loginpage" injectJSCode:inputValueJS];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];
}

/**
 设置字体的大小

 @param sender 设置文字的大小
 */
- (IBAction)siderChange:(UISlider *)sender {
   
    self.minimumFontSize = sender.value;
}
/**
 读取本地的HTML文件
 */
- (IBAction)onClicklocalHtml:(id)sender {
    
    WKWebViewController *web = [[WKWebViewController alloc] init];
    [web loadLocalWebHTMLString:@"test"];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];    
}
// 30 s随机数
- (IBAction)OnClickRandomNumber:(id)sender {
    
    WKWebViewController *web = [[WKWebViewController alloc] init];
    
    NSString *metaJScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width,initial-scale=1.0,maximum-scale=1.0,minimum-scale=1.0,user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);document.getElementsByTagName('body')[0].setAttribute('style','margin:0 auto;text-align:center;');document.getElementsByTagName('html')[0].setAttribute('manifest','demo_html.appcache');";
    
    NSString *randomNumJS = @"function randomNum(Min,Max){var Range = Max - Min;var Rand =  Math.random();return(Min + Math.round(Rand * Range));} document.getElementsByTagName('title')[0].innerHTML = '测试随机数';document.getElementsByTagName('p')[0].innerHTML = '测试3s随机数';var num = randomNum(1000000,100000000);  document.getElementsByTagName('p')[1].innerHTML = num;function randomNumInnerHTML() { var num = randomNum(1000000,100000000);  document.getElementsByTagName('p')[1].innerHTML = num; } setInterval('randomNumInnerHTML();', 3000); ";
    
    NSString *inputValueJS = [NSString stringWithFormat:@"%@%@",metaJScript,randomNumJS];
    
    [web automaticLoginWebURLSring:@"http://www.runoob.com/try/demo_source/tryhtml5_html_manifest.htm" injectJSCode:inputValueJS];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];
    
}
- (IBAction)cacheBaiduHtml:(id)sender {

    WKWebViewController *web = [[WKWebViewController alloc] init];
    
    NSString *metaJScript = @"document.getElementsByTagName('html')[0].setAttribute('manifest','demo_html.appcache');";
    
    NSString *randomNumJS = @"function randomNum(Min,Max){var Range = Max - Min;var Rand =  Math.random();return(Min + Math.round(Rand * Range));} document.getElementsByTagName('title')[0].innerHTML = '测试随机数';document.getElementsByTagName('p')[0].innerHTML = '测试3s随机数';var num = randomNum(1000000,100000000);  document.getElementsByTagName('p')[1].innerHTML = num;function randomNumInnerHTML() { var num = randomNum(1000000,100000000);  document.getElementsByTagName('p')[1].innerHTML = num; } setInterval('randomNumInnerHTML();', 3000); ";
    
    NSString *inputValueJS = [NSString stringWithFormat:@"%@%@",metaJScript,randomNumJS];
    
    [web automaticLoginWebURLSring:@"https://m.baidu.com/" injectJSCode:inputValueJS];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];
    
}

#pragma mark 点击search跳到搜索结果页
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    WKWebViewController *web = [[WKWebViewController alloc] init];
    [web loadWebURLSring:searchBar.text];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
}


@end
