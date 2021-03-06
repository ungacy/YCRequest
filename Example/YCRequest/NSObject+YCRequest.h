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

- (NSURLSessionDataTask *)requestWithCompletion:(void (^)(BOOL isSuccess, id result))completion;

- (NSURLSessionDataTask *)requestWithCustomBlock:(void (^)(AFHTTPSessionManager *manager, id api))customBlock
                                      completion:(void (^)(BOOL isSuccess, id result))completion;

@end
