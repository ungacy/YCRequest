//
//  YCWeather.m
//  YCRequest_Example
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 ungacy. All rights reserved.
//

#import "YCWeather.h"

@implementation YCWeather

- (NSDictionary *)yc_config {
    return @{
        @"method": @"GET",
        @"summary": @"Weather in Some Place",
        @"param": @[
            @{
               @"paramType": @"query",
               @"key": @"q",
               @"type": @"string",
               @"required": @"true",
            },
            @{
               @"paramType": @"query",
               @"key": @"format",
               @"type": @"int64",
               @"required": @"string",
            },
        ],
        @"consumes": @"application/json",
        @"response": @"YCWeatherResponse",
        @"path": @"/v1/public/yql",
    };
}

@end
