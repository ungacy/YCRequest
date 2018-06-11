//
//  NSObject+YCRequest.m
//  YCRequest_Example
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 ungacy. All rights reserved.
//

#import "NSObject+YCRequest.h"
#import <YCRequest/YCRequest.h>

@implementation NSObject (YCRequest)

- (nullable NSURLSessionDataTask *)requestWithCompletion:(YCRequestCompletionBlock)completion {
    return [self requestWithCustomBlock:nil completion:completion];
}

- (nullable NSURLSessionDataTask *)requestWithCustomBlock:(void (^)(AFHTTPSessionManager *, id))customBlock completion:(YCRequestCompletionBlock)completion {
    return [[YCRequest sharedInstance] request:self customBlock:customBlock completion:completion];
}

@end
