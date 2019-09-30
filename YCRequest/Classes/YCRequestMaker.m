//
//  YCRequestMaker.m
//  AFNetworking
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#import "YCRequestMaker.h"
#import "_YCRequestPrivateDefine.h"

#define kYCRequestMakerMethodDict @{                   \
    @(YCRequestMakerOperationMethodGET): @"GET",       \
    @(YCRequestMakerOperationMethodPOST): @"POST",     \
    @(YCRequestMakerOperationMethodPUT): @"PUT",       \
    @(YCRequestMakerOperationMethodDELETE): @"DELETE", \
}

#define kYCRequestMakerParamDict @{                                          \
    @(YCRequestMakerOperationParamQuery): kYCRequestConfigKeyParamTypeQuery, \
    @(YCRequestMakerOperationParamBody): kYCRequestConfigKeyParamTypeBody,   \
    @(YCRequestMakerOperationParamPath): kYCRequestConfigKeyParamTypePath,   \
    @(YCRequestMakerOperationParamForm): kYCRequestConfigKeyParamTypeForm,   \
    @(YCRequestMakerOperationParamHeader): kYCRequestConfigKeyParamTypeHeader,   \
}

@interface YCRequestMaker ()

@property (nonatomic, strong) NSMutableDictionary *dict;

@property (nonatomic, assign) YCRequestMakerOperation paramOperation;

@end

@implementation YCRequestMaker

- (instancetype)init {
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
        _dict[kYCRequestConfigKeyParam] = [NSMutableArray array];
    }
    return self;
}

- (NSDictionary *)srk_config {
    return [_dict copy];
}

+ (YCRequestMaker *)make:(void (^)(YCRequestMaker *make))block {
    YCRequestMaker *maker = [YCRequestMaker new];
    if (block) {
        block(maker);
    }
    return maker;
}

- (YCRequestMaker * (^)(YCRequestMakerOperation method))method {
    return ^YCRequestMaker *(YCRequestMakerOperation method) {
        self.dict[kYCRequestConfigKeyMethod] = kYCRequestMakerMethodDict[@(method)];
        return self;
    };
}

- (YCRequestMaker * (^)(NSString *path))mapping {
    return ^YCRequestMaker *(NSString *path) {
        self.dict[kYCRequestConfigKeyPath] = path;
        return self;
    };
}

- (YCRequestMaker * (^)(NSString *url))url {
    return ^YCRequestMaker *(NSString *url) {
        self.dict[kYCRequestConfigKeyUrl] = url;
        return self;
    };
}

- (YCRequestMaker * (^)(NSString *response))response {
    return ^YCRequestMaker *(NSString *response) {
        self.dict[kYCRequestConfigKeyDeserialization] = response;
        return self;
    };
}

- (YCRequestMaker * (^)(YCRequestMakerOperation operation))paramType {
    return ^YCRequestMaker *(YCRequestMakerOperation operation) {
        self.paramOperation = operation;
        return self;
    };
}

- (YCRequestMaker * (^)(NSDictionary *param))param {
    YCRequestMakerOperation paramOperation = self.paramOperation;
    if (paramOperation == YCRequestMakerOperationNone) {
        paramOperation = YCRequestMakerOperationParamQuery;
    }
    return ^YCRequestMaker *(NSDictionary *param) {
        NSMutableArray *paramArray = self.dict[kYCRequestConfigKeyParam];
        [param enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key,
                                                   id _Nonnull obj,
                                                   BOOL *_Nonnull stop) {
            [paramArray addObject:@{
                kYCRequestConfigKeyParamType: kYCRequestMakerParamDict[@(paramOperation)],
                kYCRequestConfigKeyParamKey: key,
                kYCRequestConfigKeyParamValue: obj,
            }];
        }];
        return self;
    };
}

- (YCRequestMaker * (^)(NSString *path))put {
    return self.method(YCRequestMakerOperationMethodPUT).mapping;
}

- (YCRequestMaker * (^)(NSString *path))delete {
    return self.method(YCRequestMakerOperationMethodDELETE).mapping;
}

- (YCRequestMaker * (^)(NSString *path))get {
    return self.method(YCRequestMakerOperationMethodGET).mapping;
}

- (YCRequestMaker * (^)(NSString *path))post {
    return self.method(YCRequestMakerOperationMethodPOST).mapping;
}

- (YCRequestMaker * (^)(NSDictionary *param))header {
    return self.paramType(YCRequestMakerOperationParamHeader).param;
}

- (YCRequestMaker * (^)(NSDictionary *param))pathVariable {
    return self.paramType(YCRequestMakerOperationParamPath).param;
}

- (YCRequestMaker * (^)(NSDictionary *param))query {
    return self.paramType(YCRequestMakerOperationParamQuery).param;
}

- (YCRequestMaker * (^)(NSDictionary *param))body {
    return self.paramType(YCRequestMakerOperationParamBody).param;
}

@end
