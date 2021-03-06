//
//  YCRequest.h
//  YCRequest
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#import "YCRequestDefine.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPSessionManager;

/**
Example for `serialization` & `deserialization` base on [YYModel](https://github.com/ibireme/YYModel)

@code
YCRequest *request = [YCRequest sharedInstance];
request.serialization = ^id(id jsonObject, NSString *className) {
    if (!jsonObject) {
        return nil;
    }
    Class class = NSClassFromString(className);
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *result = [NSArray modelArrayWithClass:class json:jsonObject];
        return result;
    }
    return [class modelWithDictionary:jsonObject];
};
request.deserialization = ^id(id object) {
    return [object modelToJSONObject];
};
request.timeout = 10;
request.baseUri = @"192.168.1.111";

**/
@interface YCRequest : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy, nullable) NSDictionary *linkDict;

@property (nonatomic, copy) NSString *baseUri;

@property (nonatomic, copy) NSString *configKey;

@property (nonatomic, assign) NSTimeInterval timeout;

@property (nonatomic, assign) BOOL verbose;

- (nullable NSURLSessionDataTask *)request:(id)api
                               customBlock:(void (^)(AFHTTPSessionManager *manager, id api))customBlock
                                completion:(YCRequestCompletionBlock)completion;
#pragma mark - Error Handler

- (void)setErrorHandler:(void (^)(id api, NSError *error))errorHandler;

#pragma mark - Log Handler

- (void)setLogHandler:(void (^)(NSString *log, NSDictionary *param, NSDictionary *config))logHandler;

#pragma mark - Monitor Handler

- (void)setMonitorHandler:(void (^)(id api, YCRequestStatus status, CGFloat duration, NSDictionary *config))monitorHandler;

#pragma mark - Serialization

@property (nonatomic, copy) id (^serialization)(id jsonObject, NSString *className);

@property (nonatomic, copy) id (^deserialization)(id object);

#pragma mark - Custom

@property (nonatomic, copy) id (^customBlock)(AFHTTPSessionManager *manager, id api);

@property (nonatomic, copy) AFHTTPSessionManager * (^customSessionBlock)(void);

#pragma mark - DataTask

- (NSURLSessionDataTask *)dataTaskForAPI:(id)api;

@end

NS_ASSUME_NONNULL_END

@interface NSObject (YCRequestStorage)
/**
 If `value` is nil, return value of key, otherwize will save value of key
 If `key` is nil, return all keys of `value`
 */
- (id _Nullable (^_Nullable)(NSString *_Nullable key, id _Nullable value))ycr_store;

@end
