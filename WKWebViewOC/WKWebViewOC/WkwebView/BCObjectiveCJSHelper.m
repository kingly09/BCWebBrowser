//
//  BCObjectiveCJSHelper.m
//  WKWebViewOC
//
//  Created by kingly on 2017/10/31.
//  Copyright © 2017年 Bamboocloud Co., Ltd. All rights reserved.
//

#import "BCObjectiveCJSHelper.h"
#import <AddressBookUI/AddressBookUI.h>
 #import <CoreLocation/CoreLocation.h>

@interface BCObjectiveCJSHelper()
<UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
ABPeoplePickerNavigationControllerDelegate,
CLLocationManagerDelegate>

@property (nonatomic, weak) UIViewController *vc;
@end

@implementation BCObjectiveCJSHelper {
    
    // 地理位置
    CLLocationManager *myLocationManager;
    CLLocation *myLocation;             //当前位置
    NSString *sLocation;                //当前定位城市
    double longitude;                   //经度，refProgramId有效时可空
    double latitude;                    //纬度，refProgramId有效时可空
    NSString *locationString;           //位置信息
    
}

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
            }else if ([code isEqualToString:@"0004"]) {
                NSLog(@"打开app的定位信息");
                [self openPositioning];
                return;
            }else if ([dic[@"functionName"] isEqualToString:@"showUserInfo"]) {
                NSLog(@"打开app的定位信息");
                NSString *jsFuction = dic[@"functionName"];
                NSString *uid = [NSString stringWithFormat:@"uid111111"];
                NSString *js = [NSString stringWithFormat:@"%@(\'%@\')",jsFuction,uid];
                [self.webView evaluateJavaScript:js completionHandler:nil];
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
    
   [self.vc  dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
  
    [self.vc dismissViewControllerAnimated:YES completion:^{
        
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

#pragma mark - 打开app的定位信息
-(void)openPositioning {
    if ([CLLocationManager locationServicesEnabled]) {
        myLocationManager = [[CLLocationManager alloc]init];
        [myLocationManager requestWhenInUseAuthorization];//设置请求位置权限
        myLocationManager.delegate = self;
        myLocationManager.desiredAccuracy = kCLLocationAccuracyBest;//定位方式为最优的状态
        myLocationManager.distanceFilter = 1000.f;
        [myLocationManager startUpdatingLocation];
    }
}

#pragma mark - 定位CLLocationManagerDelegate
/**
 * 获取位置信息的协议
 */
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            if ([myLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [myLocationManager requestWhenInUseAuthorization];
            }
            break;
            
        default:
            break;
    }
}
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    myLocation = [locations lastObject];//更新位置
    CLGeocoder *myGeocoder = [[CLGeocoder alloc]init];
    [myGeocoder reverseGeocodeLocation:myLocation completionHandler:^(NSArray *placeMark,NSError *error){
        
        
        //String to hold address
        CLPlacemark *curPlaceMark = [placeMark firstObject];
        //国家
        NSString *country = curPlaceMark.country;
        if ([country containsString:@"中国"])  {
            country = @"";
        }
        
        NSString *stateString;
        NSArray *stateArr = [curPlaceMark.administrativeArea componentsSeparatedByString:@"省"];
        if ([curPlaceMark.administrativeArea containsString:@"省"]) {
            stateString = [stateArr firstObject];
            if (stateString.length >0 ) {
                stateString = [NSString stringWithFormat:@"%@省 ",stateString];
            }
            
        }else{
            stateString = curPlaceMark.administrativeArea;
        }
        NSString *cityString;
        NSArray *cityArr = [curPlaceMark.locality componentsSeparatedByString:@"市"];
        if ([curPlaceMark.locality containsString:@"市"]) {
            cityString = [cityArr firstObject];
            if (cityString.length >0 ) {
                cityString = [NSString stringWithFormat:@"%@市 ",cityString];
            }
        }else{
            cityString = curPlaceMark.locality;
        }
        
        
        NSString *quyuString = curPlaceMark.subLocality;
        if (quyuString.length <=0) {
            quyuString = @"";
        }
        if ([self isBlankString:stateString]) {
            sLocation = @"";
        }else{
            sLocation = [NSString stringWithFormat:@"%@%@%@%@",country,stateString,cityString,quyuString];
        }
        if (sLocation.length>0) {
            
           sLocation =  [self calculateLengthWithString:sLocation];//计算、调整长度
            
        }else{
            
            sLocation = [self calculateLengthWithString:@"迷路中"];//计算、调整长度
        }
        
        NSString *deviceId = [NSString stringWithFormat:@"当前地址为：%@",sLocation];
        NSString *js = [NSString stringWithFormat:@"globalCallback(\'%@\')", deviceId];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    }];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
   sLocation =  [self calculateLengthWithString:@"迷路中"];//计算、调整长度
    NSString *deviceId = [NSString stringWithFormat:@"当前地址为：%@",sLocation];
    NSString *js = [NSString stringWithFormat:@"globalCallback(\'%@\')", deviceId];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

/**
 * @brief 判断字符串为空和只为空格解决办法
 */
- (BOOL)isBlankString:(NSString *)string
{
    if (string == nil) {
        
        return YES;
        
    }
    
    if (string == NULL) {
        
        return YES;
        
    }
    
    if ([string isKindOfClass:[NSNull class]]) {
        
        return YES;
        
    }
    
    if ([string isEqual:[NSNull null]]) {
        
        return YES;
        
    }
    
    if (string.length > 0) {
        if ([[string lowercaseString] isEqualToString:@"<null>"]) {
            return YES;
        }
        
        if ([[string lowercaseString] isEqualToString:@"(null)"]) {
            return YES;
        }
    }
    //去除两端的空格
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0) {
        
        return YES;
        
    }
    
    return NO;
}


/**
 位置字段计算字符串长度、并且调整fram
 */
-(NSString *)calculateLengthWithString:(NSString *)address {
    
    NSString *locationString = @"迷路中";
  
    if (address.length==0) {
        locationString = @"迷路中";
    }else{
        locationString = address;
    }
    return locationString;
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
