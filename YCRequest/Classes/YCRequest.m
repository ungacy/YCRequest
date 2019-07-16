//
//  YCRequest.m
//  YCRequest
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#import "YCRequest.h"
#import "YCRequestMaker.h"
#import "_YCRequestPrivateDefine.h"
#import "_YCRequestUnit.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFURLSessionManager.h>
#import <objc/runtime.h>

NSErrorDomain const YCRequestErrorDomain = @"com.ungacy.request.error";

const NSInteger YCRequestErrorCode = -1;

const NSTimeInterval YCRequestDefaultTimeout = 5;

@interface YCRequest ()

@property (nonatomic, strong) NSMutableDictionary *container;

@property (nonatomic, strong) NSMutableArray *queue;

@property (nonatomic, copy) void (^errorHandler)(id api, NSError *error);

@property (nonatomic, copy) void (^logHandler)(NSString *log, NSDictionary *param, NSDictionary *config);

@property (nonatomic, copy) void (^monitorHandler)(id api, YCRequestStatus status, CGFloat duration, NSDictionary *config);

@property (nonatomic, strong) NSMutableCharacterSet *escapeSet;

@end

@implementation YCRequest

+ (instancetype)sharedInstance {
    static dispatch_once_t once = 0;
    static id instance = nil;

    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //防止反复修改容器大小
        _container = [NSMutableDictionary dictionaryWithCapacity:3];
        _queue = [NSMutableArray arrayWithCapacity:3];
        _timeout = YCRequestDefaultTimeout;
        _verbose = YES;
        _escapeSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [_escapeSet removeCharactersInString:@"+;&=$,"];
    }
    return self;
}

NSString *YCRequestURLEncode(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return value;
    }
    value = [value stringByRemovingPercentEncoding];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:[YCRequest sharedInstance].escapeSet];
}

static inline void yc_wrapBodyParam(NSString *key, id value, NSMutableDictionary *param) {
    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
        param[key] = value;
    } else {
        NSDictionary *dict = [YCRequest sharedInstance].deserialization(value);
        if (dict && [dict isKindOfClass:[NSDictionary class]]) {
            [dict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key,
                                                      id _Nonnull obj,
                                                      BOOL *_Nonnull stop) {
                param[key] = obj;
            }];
        }
    }
}

static inline void yc_wrapQueryParam(NSString *key, id value, NSMutableString *uri) {
    [uri appendFormat:@"%@=%@&", key, YCRequestURLEncode(value)];
}

static inline void yc_wrapPathParam(NSString *key, id value, NSMutableString *uri) {
    if ([value isKindOfClass:[NSNumber class]]) {
        value = [NSString stringWithFormat:@"%@", value];
    }
    NSString *temp = [NSString stringWithFormat:@"{%@}", key];
    [uri replaceOccurrencesOfString:temp
                         withString:value
                            options:NSCaseInsensitiveSearch
                              range:NSMakeRange(0, [uri length])];
}

static inline NSMutableDictionary *yc_wrapParam(NSArray *paramTemplate,
                                                id model,
                                                NSMutableString *uri,
                                                NSMutableDictionary *header) {
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithCapacity:paramTemplate.count];
    [paramTemplate enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj,
                                                NSUInteger idx,
                                                BOOL *_Nonnull stop) {
        NSCAssert([obj isKindOfClass:[NSDictionary class]], @"Failed to read param in config");
        NSString *key = obj[kYCRequestConfigKeyParamKey];
        NSString *keyPath = obj[kYCRequestConfigKeyParamRename] ?: key;
        NSString *type = obj[kYCRequestConfigKeyParamType];
        id value = obj[kYCRequestConfigKeyParamValue];
        if (!value) {
            if ([model respondsToSelector:NSSelectorFromString(keyPath)]) {
                value = [model valueForKeyPath:keyPath]; // TODO : keyPath exception
            }
            if (!value) {
                return;
            }
        }
        if ([type isEqualToString:kYCRequestConfigKeyParamTypeQuery]) { // add it to uri TODO : default value
            yc_wrapQueryParam(key, value, uri);
        } else if ([type isEqualToString:kYCRequestConfigKeyParamTypeBody]) {
            yc_wrapBodyParam(key, value, param);
        } else if ([type isEqualToString:kYCRequestConfigKeyParamTypePath]) {
            yc_wrapPathParam(key, value, uri);
        } else if ([type isEqualToString:kYCRequestConfigKeyParamTypeHeader]) {
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [NSString stringWithFormat:@"%@", value];
            }
            header[key] = value;
        } else {
            NSCAssert(!type, @"Who are you here!");
        }
    }];
    return param;
}

static inline NSString *yc_prettyJson(NSDictionary *object) {
    if (!object) {
        return nil;
    }
    if (![object isKindOfClass:[NSDictionary class]]) {
        return [object description];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData.length == 0) {
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)logResult:(BOOL)isSuccess responseObject:(id)responseObject uri:(NSMutableString *)uri config:(NSDictionary *)config {
    if (isSuccess) {
        NSString *log = [NSString stringWithFormat:@"\n%@\nresponse:\n%@", uri, yc_prettyJson(responseObject)];
        if (self.logHandler) {
            self.logHandler(log, nil, config);
        } else {
            YCDLog(@"%@", log);
        }
    } else {
        NSError *error = responseObject;
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *log = [NSString stringWithFormat:@"Failure: path [%@] error:\n[%@]", uri, string];
        if (self.logHandler) {
            self.logHandler(log, nil, config);
        } else {
            YCDLog(@"%@", log);
        }
    }
}

- (NSDictionary *)configForApi:(id)api {
    SEL configSelector = NSSelectorFromString(self.configKey);
    NSParameterAssert([api respondsToSelector:configSelector]);
    NSMethodSignature *signature = [[api class] instanceMethodSignatureForSelector:configSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:api];
    [invocation setSelector:configSelector];
    __autoreleasing NSDictionary *tmp;
    [invocation invoke];
    [invocation getReturnValue:&tmp];
    return [tmp copy];
}

- (nullable NSURLSessionDataTask *)request:(NSObject *)api
                               customBlock:(void (^)(AFHTTPSessionManager *manager, id api))customBlock
                                completion:(YCRequestCompletionBlock)completion {
    //deserialization & serialization are both required
    NSParameterAssert(self.deserialization && self.serialization);
    //config
    NSDictionary *config = [self configForApi:api];
    //consumes
    NSString *consumes = config[kYCRequestConfigKeyConsumes];
    NSNumber *timeoutValue = api.ycr_store(@"timeout", nil);
    CGFloat timeout = timeoutValue ? timeoutValue.floatValue : self.timeout;
    _YCRequestUnit *unit = [_YCRequestUnit unitWithManager:self.customSessionBlock timeout:timeout consumes:consumes];

    __weak typeof(api) weak_api = api;
    __weak typeof(self) weak_self = self;
    __weak typeof(unit.manager) weak_manager = unit.manager;
    //AOP
    unit.customBlock = ^(AFHTTPSessionManager *manager) {
        if (!weak_self.customBlock) {
            return;
        }
        weak_self.customBlock(manager, weak_api);
    };

    if (customBlock) {
        unit.customBlock = ^(AFHTTPSessionManager *manager) {
            customBlock(manager, weak_api);
        };
    }
    //request needs
    NSString *method = [config[kYCRequestConfigKeyMethod] uppercaseString];
    NSString *path = config[kYCRequestConfigKeyPath];
    NSString *url = config[kYCRequestConfigKeyUrl];
    NSArray *paramTemplate = config[kYCRequestConfigKeyParam];
    NSMutableString *uri = [NSMutableString string];
    if (url) {
        [uri appendString:url];
    } else {
        //link
        if (config[kYCRequestConfigKeyLink]) {
            NSString *linkId = config[kYCRequestConfigKeyLink];
            NSString *linkUrl = self.linkDict[linkId];
            NSParameterAssert(linkUrl);
            [uri appendString:linkUrl];
        } else {
            [uri appendString:self.baseUri];
        }
        if (path) {
            [uri appendString:path];
        }
    }
    [uri appendString:@"?"];
    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    NSMutableDictionary *param = yc_wrapParam(paramTemplate, api, uri, header);
    if ([uri hasSuffix:@"&"]) {
        [uri deleteCharactersInRange:NSMakeRange(uri.length - 1, 1)];
    }
    if ([uri hasSuffix:@"?"]) {
        [uri deleteCharactersInRange:NSMakeRange(uri.length - 1, 1)];
    }
    if (_verbose && !param[kYCRequestConfigKeyParamType]) {
        NSMutableDictionary *allHeader = [weak_manager.requestSerializer.HTTPRequestHeaders mutableCopy];
        [allHeader setValuesForKeysWithDictionary:header];
        NSString *log = [NSString stringWithFormat:@"\n[%@]\n%@\nheader\n%@\nparam\n%@", method, uri, yc_prettyJson(allHeader), yc_prettyJson(param)];
        if (self.logHandler) {
            self.logHandler(log, param, config);
        } else {
            YCDLog(@"%@", log);
        }
    }
    if (self.monitorHandler) {
        self.monitorHandler(api, YCRequestStatusBegin, 0, config);
    }
    NSURLSessionDataTask *task =
        [unit requestWithMethod:method
                            uri:uri
                         header:header
                          param:param
                     completion:^(BOOL isSuccess, id responseObject, NSURLResponse *response) {
                         __strong typeof(self) self = weak_self;
                         [self.queue removeObject:unit];
                         if (self.verbose) {
                             [self logResult:isSuccess responseObject:responseObject uri:uri config:config];
                         }
                         if (self.monitorHandler) {
                             self.monitorHandler(api, isSuccess ? YCRequestStatusFinish : YCRequestStatusFailed, unit.duration, config);
                         }
                         [self responsePipeline:isSuccess
                                            api:api
                                 responseObject:responseObject
                                       response:response
                                         config:config
                                     completion:completion];
                     }];
    [self.queue addObject:unit];
    return task;
}

- (void)responsePipeline:(BOOL)isSuccess
                     api:(NSObject *)api
          responseObject:(id)responseObject
                response:(NSURLResponse *)response
                  config:(NSDictionary *)config
              completion:(YCRequestCompletionBlock)completion {
    if (!completion) {
        return;
    }
    //request failed
    if (!isSuccess) {
        [self errorPipeline:responseObject api:api];
        completion(NO, responseObject);
        return;
    }
    NSString *deserialization = api.ycr_store(kYCRequestConfigKeyDeserialization, nil) ?: config[kYCRequestConfigKeyDeserialization];
    id result = [self deserializationResponse:responseObject className:deserialization];
    completion(YES, result ?: responseObject);
}

/**
 override point

 @param error error form http
 */
- (void)errorPipeline:(NSError *)error api:(id)api {
    if ([error isKindOfClass:[NSError class]] && self.errorHandler) {
        self.errorHandler(api, error);
    }
}

/**
 反序列化返回数据,有可能是数组
 @param responseData 服务器返回的字典数据
 @param className 类对应的class
 @return 成功,返回model, 失败,返回错误
 */
- (id)deserializationResponse:(id)responseData className:(NSString *)className {
    if (!responseData) {
        return nil;
    }
    if ([responseData isKindOfClass:[NSArray class]] || [responseData isKindOfClass:[NSDictionary class]]) {
        return self.serialization(responseData, className);
    } else if ([responseData isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([responseData isKindOfClass:[NSString class]] || [responseData isKindOfClass:[NSNumber class]]) {
        return responseData;
    }
    //unkown class, assert first
    NSCAssert(NO, NSStringFromClass([responseData class]));
    return nil;
}

@end

static void *YCRequestStorageKey = &YCRequestStorageKey;

@implementation NSObject (YCRequestStorage)

- (void)setYcr_storage:(NSMutableDictionary *)ycr_storage {
    objc_setAssociatedObject(self, &YCRequestStorageKey, ycr_storage, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary *)ycr_storage {
    NSMutableDictionary *storage = objc_getAssociatedObject(self, &YCRequestStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        [self setYcr_storage:storage];
    }
    return storage;
}

- (id (^)(NSString *, id))ycr_store {
    id (^block)(NSString *key, id value) = ^id(NSString *key, id value) {
        if (key && value) {
            self.ycr_storage[key] = value;
        }
        if (key && !value) {
            return self.ycr_storage[key];
        }
        if (!key && value) {
            return [self.ycr_storage allKeysForObject:value];
        }
        return self;
    };
    return block;
}

@end
