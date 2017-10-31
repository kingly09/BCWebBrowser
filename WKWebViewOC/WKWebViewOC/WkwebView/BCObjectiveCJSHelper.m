//
//  BCObjectiveCJSHelper.m
//  WKWebViewOC
//
//  Created by kingly on 2017/10/31.
//  Copyright © 2017年 Bamboocloud Co., Ltd. All rights reserved.
//

#import "BCObjectiveCJSHelper.h"
#import <AddressBookUI/AddressBookUI.h>

@interface BCObjectiveCJSHelper()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,ABPeoplePickerNavigationControllerDelegate>
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
            }else if ([code isEqualToString:@"0003"]) {
                NSLog(@"打开通讯录");
                [self openAddressBook];
                return;
            }else {
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
   
    NSLog(@"%@",info);
    NSString *deviceId = [NSString stringWithFormat:@"该相册信息成功"];
    NSString *js = [NSString stringWithFormat:@"globalCallback(\'%@\')", deviceId];
    [self.webView evaluateJavaScript:js completionHandler:nil];
    
   [picker  dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
  
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - 打开通讯录

-(void)openAddressBook {
    
    ABPeoplePickerNavigationController *picker =[[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self.vc  presentViewController:picker animated:YES completion:nil];
}

//这个方法在用户取消选择时调用
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self.vc dismissViewControllerAnimated:YES completion:^{}];
}

//这个方法在用户选择一个联系人后调用
-(void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person{
    [self displayPerson:person];
    [self.vc dismissViewControllerAnimated:YES completion:^{}];
}

//获得选中person的信息
- (void)displayPerson:(ABRecordRef)person
{
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *middleName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSMutableString *nameStr = [NSMutableString string];
    if (lastname!=nil) {
        [nameStr appendString:lastname];
    }
    if (middleName!=nil) {
        [nameStr appendString:middleName];
    }
    if (firstName!=nil) {
        [nameStr appendString:firstName];
    }
    
    NSString* phone = nil;
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person,kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phoneNumbers) > 0) {
        phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    } else {
        phone = @"[None]";
    }
    
    //可以把-、+86、空格这些过滤掉
    NSString *phoneStr = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *deviceId = [NSString stringWithFormat:@"该%@的电话号码:%@",nameStr,phone];
    NSString *js = [NSString stringWithFormat:@"globalCallback(\'%@\')", deviceId];
    [self.webView evaluateJavaScript:js completionHandler:nil];
   
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
