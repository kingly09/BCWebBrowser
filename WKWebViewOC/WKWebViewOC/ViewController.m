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
    [self.navigationController pushViewController:web animated:YES];
}


#pragma mark 点击search跳到搜索结果页
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    WKWebViewController *web = [[WKWebViewController alloc] init];
    [web loadWebURLSring:searchBar.text];
    [self.navigationController pushViewController:web animated:YES];

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
}


@end
