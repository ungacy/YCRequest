//
//  NSObject+YCRequest.h
//  YCRequest_Example
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 ungacy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AFHTTPSessionManager;

@interface NSObject (YCRequest)

- (nullable NSURLSessionDataTask *)requestWithCompletion:(void (^__nullable)(BOOL isSuccess, __nullable id result))completion;

- (nullable NSURLSessionDataTask *)requestWithCustomBlock:(void (^__nullable)(AFHTTPSessionManager *manager, id api))customBlock
                                               completion:(void (^__nullable)(BOOL isSuccess, __nullable id result))completion;

@end
