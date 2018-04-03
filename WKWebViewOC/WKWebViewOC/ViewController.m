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

#define JS_CODE @"function setInputVal(pswVal,userName){var bodyDom=document.getElementsByTagName('body')[0];var inputDoms=bodyDom.getElementsByTagName('input');for(var i=0;i<inputDoms.length;i++){if(inputDoms[i].type=='password'&&inputDoms[i].style.display!='none'){inputDoms[i].value=pswVal;for(var j=i;j>0;j--){if(inputDoms[j].type!='password'&&inputDoms[j].type!='hidden'&&inputDoms[j].style.display!='none'){inputDoms[j].value=userName}}}}};"

#import "BCButtonModel.h"
#import <YYKit/YYKit.h>

@interface ViewController ()<UISearchBarDelegate>{
    
     NSMutableArray *menuButtonList; //推荐达人
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (assign,nonatomic) BOOL isPost;
//设置字体大小
@property(nonatomic,assign) float minimumFontSize;
@property (weak, nonatomic) IBOutlet UITextField *UserName;
@property (weak, nonatomic) IBOutlet UITextField *PassWordTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"BC WebBrowser浏览器";
    
    [self getMenuButtonList];
}

-(void)getMenuButtonList {
    
    NSArray *lists = [NSArray modelArrayWithClass:[BCButtonModel class] json:[NSData dataNamed:[NSString stringWithFormat:@"menuList.geojson"]]];
    menuButtonList = [NSMutableArray arrayWithArray:lists];
    
    NSLog(@"menuButtonList ::%@",menuButtonList);
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
    
    
    NSString *inputValueJS = [NSString stringWithFormat:@"%@ var psel = '%@';var pswd = '%@';  setInputVal (pswd,psel)",JS_CODE,_UserName.text,_PassWordTextField.text];
    [web automaticLoginWebURLSring:@"https://plogin.m.jd.com/user/login.action?appid=100&kpkey=&returnurl=https%3A%2F%2Fm.jd.com%3Findexloc%3D1%26sid%3D31b5f2f81de00144a039fe20e1d93f03" injectJSCode:inputValueJS];
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
    [web loadWebURLSring:@"http://10.100.0.83:8080/docs/test/qingjia.html"];
    [web setupMinimumFontSize:self.minimumFontSize];
    [self.navigationController pushViewController:web animated:YES];

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
}


@end
