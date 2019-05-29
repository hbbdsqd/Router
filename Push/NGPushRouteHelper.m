//
//  NGPushRouteHelper.m
//  iOSProject
//
//  Created by 苏秋东 on 2019/3/27.
//  Copyright © 2019 苏秋东. All rights reserved.
//

#import "NGPushRouteHelper.h"

@implementation NGPushRouteHelper
+ (instancetype)manager
{
    static NGPushRouteHelper* instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
+ (void)handleUserInfo:(NSDictionary *)userinfo{
    [NGPushRouteHelper manager].userinfo = userinfo;
    [NGPushRouteHelper manager].rootViewController = nil;
    [[NGPushRouteHelper manager] changeLinkType:[userinfo getValueForKey:@"url"]];
    [[NGPushRouteHelper manager] gotoVC];
}

+ (void)handleUserInfo:(NSDictionary *)userinfo andRootViewController:(NGBaseViewController *)rootVC{
    [NGPushRouteHelper manager].userinfo = userinfo;
    [NGPushRouteHelper manager].rootViewController = rootVC;
    [[NGPushRouteHelper manager] changeLinkType:[userinfo getValueForKey:@"url"]];
    [[NGPushRouteHelper manager] gotoVC];
}

- (void)gotoVC{
    if ([self.linkType isEqualToString:@"AppLink"]) {
        NGBaseViewController * pushVC = [self applinkVC];
        if (!pushVC || pushVC == nil) {
            NSString* errorStr = [NSString stringWithFormat:@"无效的跳转链接 moduleName = %@", self.moduleName];
            NSLog(@"%@",errorStr);
        }else{
            [self loadRootViewController];
            [self pushToAppVC:pushVC parameters:self.parameters rootController:self.rootViewController];
        }
    }else if ([self.linkType isEqualToString:@"HttpLink"]){
        NSURL* urls = [[NSURL alloc] initWithString:self.httpUrl];
        [[UIApplication sharedApplication] openURL:urls];
    }else if ([self.linkType isEqualToString:@"OtherLink"]){
        
    }else{
        
    }
}

- (void)pushToAppVC:(NGBaseViewController*)pushVC
         parameters:(NSDictionary*)parameters
     rootController:(UIViewController*)rootController
{
    if (pushVC) {
        dispatch_async(dispatch_get_main_queue(), ^{
            unsigned int outCount = 0;
            objc_property_t * properties = class_copyPropertyList(pushVC.class , &outCount);
            for (int i = 0; i < outCount; i++) {
                objc_property_t property = properties[i];
                NSString *key = [NSString stringWithUTF8String:property_getName(property)];
                NSString *param = parameters[key];
                if (param != nil) {
                    [pushVC setValue:param forKey:key];
                }
            }
            [rootController.navigationController pushViewController:pushVC animated:NO];
        });
    }
}

- (void)loadRootViewController{
    if (self.rootViewController) {
        return;
    }
    AppDelegate * app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.tabbarVC = [[NGTabBarViewController alloc]init];
    app.window.rootViewController = app.tabbarVC;
    [app.tabbarVC setupViewControllers];
    
    app.tabbarVC.selectedIndex = 0;
    NGBaseNavViewController * navc = (NGBaseNavViewController *)app.tabbarVC.selectedViewController;
    self.rootViewController = (NGBaseViewController *)navc.topViewController;
}

- (NGBaseViewController*)applinkVC
{
    id resultVC = nil;
    NSString* className = self.moduleName;
    Class pushVCClass = NSClassFromString(className);
    BOOL isSubClass = [pushVCClass isSubclassOfClass:[NGBaseViewController class]];
    if (isSubClass) {
        resultVC = (NGBaseViewController*)[[pushVCClass alloc] init];
    }
    return resultVC;
}

- (void)changeLinkType:(NSString *)url{
    
    self.linkType = @"OtherLink";
    self.parameters = [NSDictionary dictionary];
    self.moduleName = @"";
    
    if ([CommonTools isBlankString:url]) {
        NSString* errorStr = [NSString stringWithFormat:@"无效的跳转链接 url = %@", url];
        NSLog(@"%@",errorStr);
        self.linkType = @"OtherLink";
    }else{
        
        NSDictionary * dic = [self dictionaryWithJsonString:url];
        NSLog(@"跳转链接 %@", url);
        
        NSString *router = [CommonTools getStringWithDic:dic key:@"router"];
        NSDictionary *param = [dic valueForKey:@"param"];
        
        if ([router isEqualToString:@"app"]) {
            NSArray * allValuesArray = [param allValues];
            self.linkType = @"AppLink";
            //模块名称
            NSString* theModuleName = [CommonTools getStringWithDic:dic key:@"action"];
            //有参数
            if (allValuesArray.count > 0) {
                if ([CommonTools isBlankString:theModuleName]) {
                    self.linkType = @"OtherLink";
                    NSString* errorStr = [NSString stringWithFormat:@"无效的跳转链接 url = %@", url];
                    NSLog(@"%@",errorStr);
                }else{
                    self.parameters = param;
                    self.moduleName = theModuleName;
                }
                
            }
            //无参数
            else {
                if ([CommonTools isBlankString:theModuleName]) {
                    self.linkType = @"OtherLink";
                    NSString* errorStr = [NSString stringWithFormat:@"无效的跳转链接 url = %@", url];
                    NSLog(@"%@",errorStr);
                }else{
                    self.moduleName = theModuleName;
                }
            }
        }else if ([router isEqualToString:@"web"]){
            self.linkType = @"HttpLink";
            self.httpUrl = [CommonTools getStringWithDic:param key:@"url"];
        }else{
            self.linkType = @"OtherLink";
            NSString* errorStr = [NSString stringWithFormat:@"无效的跳转链接 url = %@", url];
            NSLog(@"%@",errorStr);
        }
    }
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return [NSDictionary dictionary];
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return [NSDictionary dictionary];
    }
    return dic;
}
- (NSDictionary*)pushParametersWithFormEncodedData:(NSString*)formData
{
    NSArray* params = [formData componentsSeparatedByString:@"&"];
    
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    for (NSString* param in params) {
        NSArray* pv = [param componentsSeparatedByString:@"="];
        NSString* v = @"";
        if ([pv count] == 2) {
            v = [self decodeURIComponent:[pv objectAtIndex:1]];
            [result setObject:v forKey:[pv objectAtIndex:0]];
        }
    }
    return result;
}

- (NSString *)decodeURIComponent:(NSString *)str
{
    NSString *result =
    CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                              kCFAllocatorDefault,
                                                                              (CFStringRef)str,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8));
    return result;
}



//        {
//            "router":"web",
//            "action":"",
//        param:{
//            "url":"https://www.jianshu.com/p/8b6b40198473",
//        }
//        }

//        {
//            "router":"app",
//            "action":"",
//        param:{
//            "a":"123",
//            "b":"cici",
//            "c":"nv",
//        }
//        }
@end
