//
//  YCViewController.m
//  YCRequest
//
//  Created by ungacy on 06/11/2018.
//  Copyright (c) 2018 ungacy. All rights reserved.
//

#import "YCViewController.h"
#import "YCWeather.h"
#import <YYModel/YYModel.h>
#import <YCRequest/YCRequest.h>
#import "NSObject+YCRequest.h"

@interface YCViewController ()

@end

@implementation YCViewController

- (void)setup {
    YCRequest *request = [YCRequest sharedInstance];
    request.configKey = @"yc_config";
    request.serialization = ^id(id jsonObject, NSString *className) {
//        NSNumber *code = responseObject[kYCRequestResponseCode];
//        if (code.integerValue != kYCRequestResponseOK) {
//            NSError *error = [NSError errorWithDomain:YCRequestErrorDomain code:code != nil ? code.integerValue : -1 userInfo:responseObject];
//            [self dispatchError:error];
//            completion(NO, error);
//            return;
//        }
//        //取出服务器数据中`data`字段对应数据
//        id responseData = responseObject[kYCRequestResponseData];
//        //无需反序列化,直接返回服务器数据中`data`字段对应数据
//        if (!responseData) {
//            completion(YES, responseObject);
//            return;
//        }
        Class class = NSClassFromString(className);
        if ([jsonObject isKindOfClass:[NSArray class]]) {
            NSArray *result = [NSArray yy_modelArrayWithClass:class json:jsonObject];
            return result;
        }
        return [class yy_modelWithDictionary:jsonObject];
    };
    request.deserialization = ^id(id object) {
        return [object yy_modelToJSONObject];
    };
    request.timeout = 5;
    request.baseUri = @"https://query.yahooapis.com";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    YCWeather *api = [YCWeather new];
    api.q = @"select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\"nanjing\")";
    api.format = @"json";
    [api requestWithCompletion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            NSLog(@"%@", [result yy_modelDescription]);
        }
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

@end
