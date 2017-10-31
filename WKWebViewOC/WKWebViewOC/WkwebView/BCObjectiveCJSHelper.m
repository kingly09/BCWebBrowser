//
//  BCObjectiveCJSHelper.m
//  WKWebViewOC
//
//  Created by kingly on 2017/10/31.
//  Copyright © 2017年 Bamboocloud Co., Ltd. All rights reserved.
//

#import "BCObjectiveCJSHelper.h"

@interface BCObjectiveCJSHelper()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, weak) UIViewController *vc;
@end

@implementation BCObjectiveCJSHelper

- (instancetype)initWithDelegate:(id<BCObjectiveCJSHelperDelegate>)delegate vc:(UIViewController *)vc; {
    if (self = [super init]) {
        self.delegate = delegate;
        self.vc = vc;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%@, %s", self.class, __func__);
}

#pragma mark - WKScriptMessageHandler 拦截执行网页中的JS方法

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *dic = [NSDictionary dictionaryWithDictionary:message.body];
    NSLog(@"JS交互参数：%@", dic);
    //服务器固定格式写法 window.webkit.messageHandlers.名字.postMessage(内容);
    //客户端写法 message.name isEqualToString:@"名字"]
    if ([message.name isEqualToString:KWebGetDeviceID] && [dic isKindOfClass:[NSDictionary class]]) {
        
        NSLog(@"currentThread  ------   %@", [NSThread currentThread]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *code = dic[@"code"];
            if ([code isEqualToString:@"0001"]) {
                NSString *deviceId = [NSString stringWithFormat:@"该设备的deviceId:%@",[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
                NSString *js = [NSString stringWithFormat:@"globalCallback(\'%@\')", deviceId];
                [self.webView evaluateJavaScript:js completionHandler:nil];
            }else if ([code isEqualToString:@"0002"]) {
                NSLog(@"打开摄像头");
                [self openCamera];
                return;
            }  else {
                return;
            }
        });
    } else {
        return;
    }
}


/**
 打开app的摄像头
 */
-(void)openCamera {
    
    UIImagePickerController *imagePicker=[[UIImagePickerController alloc] init];
    imagePicker.delegate =self;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        imagePicker.sourceType=UIImagePickerControllerSourceTypeCamera;
    }
    [self.vc presentViewController:imagePicker animated:YES completion:^{
        
    }];
}

#pragma mark - UINavigationControllerDelegate,UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker  dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"%@",info);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
  
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

//- (NSString *)UUID {
//    KeychainItemWrapper *keyChainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"MYAppID" accessGroup:@"com.test.app"];
//    NSString *UUID = [keyChainWrapper objectForKey:(__bridge id)kSecValueData];
//
//    if (UUID == nil || UUID.length == 0) {
//        UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
//        [keyChainWrapper setObject:UUID forKey:(__bridge id)kSecValueData];
//    }
//
//    return UUID;
//}

@end
