//
//  _YCRequestUnit.h
//  YCRequest
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#import "YCRequestDefine.h"
#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;
@interface _YCRequestUnit : NSObject

+ (instancetype)unitWithManager:(AFHTTPSessionManager * (^)(void))managerBlock timeout:(NSTimeInterval)timeout consumes:(NSString *)consumes;

- (nullable NSURLSessionDataTask *)requestWithMethod:(NSString *)method
                                                 uri:(NSString *)uri
                                              header:(NSDictionary *)header
                                               param:(NSDictionary *)param
                                          completion:(void (^)(BOOL isSuccess, id result, NSURLResponse *response))completion;

@property (nonatomic, copy) void (^customBlock)(AFHTTPSessionManager *manager);

@property (nonatomic, readonly, strong) AFHTTPSessionManager *manager;

@property (nonatomic, readonly) NSTimeInterval duration;

@end
