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
#import <AFNetworking/AFNetworking.h>

NSErrorDomain const YCRequestErrorDomain = @"com.ungacy.request.error";

const NSInteger YCRequestErrorCode = -1;

const NSTimeInterval YCRequestDefaultTimeout = 5;

@interface YCRequest ()

@property (nonatomic, strong) NSMutableDictionary *container;

@property (nonatomic, strong) NSMutableArray *queue;

@property (nonatomic, copy) void (^errorHandler)(NSError *error);

@property (nonatomic, copy) void (^logHandler)(NSString *log);

@property (nonatomic, copy) void (^monitorHandler)(id api, YCRequestStatus status, CGFloat duration);

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

/**
 反序列化返回数据,有可能是数组
 @param responseData 服务器返回的字典数据
 @param className 类对应的class
 @return 成功,返回model, 失败,返回错误
 */
static inline id yc_deserializationResponse(id responseData, NSString *className) {
    if (!responseData) {
        return nil;
    }
    if ([responseData isKindOfClass:[NSArray class]] || [responseData isKindOfClass:[NSDictionary class]]) {
        return [YCRequest sharedInstance].serialization(responseData, className);
    } else if ([responseData isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([responseData isKindOfClass:[NSString class]] || [responseData isKindOfClass:[NSNumber class]]) {
        return responseData;
    }
    //unkown class, assert first
    NSCAssert(NO, NSStringFromClass([responseData class]));
    return nil;
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

static inline void yc_wrapFormParam(NSString *key, UIImage *value, NSMutableDictionary *param) {
    NSData *imageData;
    if (UIImagePNGRepresentation(value)) {
        imageData = UIImagePNGRepresentation(value);
    } else {
        imageData = UIImageJPEGRepresentation(value, 1);
    }
    if (imageData.length > 1024 * 1024) {
        //如果图片大于1M，则压缩
        imageData = UIImageJPEGRepresentation(value, 0.7);
    }
    param[key] = imageData;
    param[kYCRequestConfigKeyParamType] = kYCRequestConfigKeyParamTypeForm;
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
        } else if ([type isEqualToString:kYCRequestConfigKeyParamTypeForm]) {
            yc_wrapFormParam(key, value, param);
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

- (void)logResult:(BOOL)isSuccess responseObject:(id)responseObject uri:(NSMutableString *)uri {
    if (isSuccess) {
        NSString *log = [NSString stringWithFormat:@"\n%@\nresponse:\n%@", uri, yc_prettyJson(responseObject)];
        if (self.logHandler) {
            self.logHandler(log);
        } else {
            YCDLog(@"%@", log);
        }
    } else {
        NSError *error = responseObject;
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *log = [NSString stringWithFormat:@"Failure: path [%@] error:\n[%@]", uri, string];
        if (self.logHandler) {
            self.logHandler(log);
        } else {
            YCDLog(@"%@", log);
        }
    }
}

- (nullable NSURLSessionDataTask *)request:(id)model
                               customBlock:(void (^)(AFHTTPSessionManager *manager, id api))customBlock
                                completion:(YCRequestCompletionBlock)completion {
    //必须要自定义序列化与反序列化的方法
    NSParameterAssert(self.deserialization && self.serialization);
    //取出config
    SEL configSelector = NSSelectorFromString(self.configKey);
    NSParameterAssert([model respondsToSelector:configSelector]);
    NSMethodSignature *signature = [[model class] instanceMethodSignatureForSelector:configSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:model];
    [invocation setSelector:configSelector];
    __autoreleasing NSDictionary *config;
    [invocation invoke];
    [invocation getReturnValue:&config];
    NSString *consumes = config[kYCRequestConfigKeyConsumes];
    _YCRequestUnit *unit = [_YCRequestUnit unitWithManager:self.customSessionBlock timeout:self.timeout consumes:consumes];
    __weak typeof(model) weak_model = model;
    __weak typeof(self) weak_self = self;
    __weak typeof(unit.manager) weak_manager = unit.manager;
    //AOP
    unit.customBlock = ^(AFHTTPSessionManager *manager) {
        if (!weak_self.customBlock) {
            return;
        }
        weak_self.customBlock(manager, weak_model);
    };

    if (customBlock) {
        unit.customBlock = ^(AFHTTPSessionManager *manager) {
            customBlock(manager, weak_model);
        };
    }
    NSString *method = [config[kYCRequestConfigKeyMethod] uppercaseString];
    NSString *path = config[kYCRequestConfigKeyPath];
    NSString *url = config[kYCRequestConfigKeyUrl];
    NSArray *paramTemplate = config[kYCRequestConfigKeyParam];
    NSString *deserialization = config[kYCRequestConfigKeyDeserialization];
    NSMutableString *uri = [NSMutableString string];
    if (url) {
        [uri appendString:url];
    } else {
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
    NSMutableDictionary *param = yc_wrapParam(paramTemplate, model, uri, header);
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
            self.logHandler(log);
        } else {
            YCDLog(@"%@", log);
        }
    }
    if (self.monitorHandler) {
        self.monitorHandler(model, YCRequestStatusBegin, 0);
    }
    NSURLSessionDataTask *task =
        [unit requestWithMethod:method
                            uri:uri
                         header:header
                          param:param
                     completion:^(BOOL isSuccess, id responseObject, NSURLResponse *response) {
                         __strong typeof(self) self = weak_self;
                         if (self.verbose) {
                             [self logResult:isSuccess responseObject:responseObject uri:uri];
                         }
                         if (self.monitorHandler) {
                             self.monitorHandler(model, isSuccess ? YCRequestStatusFinish : YCRequestStatusFailed, unit.duration);
                         }
                         if (!completion) {
                             return;
                         }
                         //请求失败,直接返回
                         if (!isSuccess) {
                             [self dispatchError:responseObject];
                             completion(NO, responseObject);
                             return;
                         }
                         if (![responseObject isKindOfClass:[NSDictionary class]]) {
                             completion(YES, responseObject);
                             return;
                         }
                         id result = yc_deserializationResponse(responseObject, deserialization);
                         completion(YES, result ?: responseObject);
                         [self.queue removeObject:unit];
                     }];
    [self.queue addObject:unit];
    return task;
}

- (void)dispatchError:(NSError *)error {
    if ([error isKindOfClass:[NSError class]] && self.errorHandler) {
        self.errorHandler(error);
    }
}

@end
