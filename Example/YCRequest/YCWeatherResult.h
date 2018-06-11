//
//  YCWeatherResult.h
//  YCRequest_Example
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 ungacy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCWeatherResult : NSObject

@property (nonatomic, strong) NSDictionary *results;

@property (nonatomic, strong) NSNumber *count;

@property (nonatomic, copy) NSString *lang;

@property (nonatomic, copy) NSString *created;

@end

@interface YCWeatherResponse : NSObject

@property (nonatomic, strong) YCWeatherResult *query;

@end
