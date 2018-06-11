//
//  YCRequestMaker.h
//  AFNetworking
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, YCRequestMakerOperation) {
    YCRequestMakerOperationNone = 0,
    YCRequestMakerOperationParamMask = 0x0F,
    YCRequestMakerOperationParamQuery = 0x01,
    YCRequestMakerOperationParamBody = 0x02,
    YCRequestMakerOperationParamPath = 0x03,
    YCRequestMakerOperationParamForm = 0x04,

    YCRequestMakerOperationMethodMask = 0xF0,
    YCRequestMakerOperationMethodGET = 0x10,
    YCRequestMakerOperationMethodPOST = 0x20,
    YCRequestMakerOperationMethodPUT = 0x30,
    YCRequestMakerOperationMethodDELETE = 0x40,
};

@interface YCRequestMaker : NSObject

+ (YCRequestMaker *)make:(void (^)(YCRequestMaker *make))block;

@property (nonatomic, readonly) NSDictionary *srk_config;

- (YCRequestMaker * (^)(YCRequestMakerOperation method))method;

- (YCRequestMaker * (^)(NSString *path))path;

- (YCRequestMaker * (^)(void))get;

- (YCRequestMaker * (^)(void))post;

- (YCRequestMaker * (^)(NSString *url))url;

- (YCRequestMaker * (^)(NSString *link))link;

- (YCRequestMaker * (^)(NSString *response))response;

- (YCRequestMaker * (^)(YCRequestMakerOperation operation))paramType;

- (YCRequestMaker * (^)(NSDictionary *param))param;

@end
