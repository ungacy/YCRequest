//
//  _YCRequestPrivateDefine.h
//  YCRequest
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#ifndef _YCRequestPrivateDefine_h
#define _YCRequestPrivateDefine_h

#pragma mark - Config Key

static NSString *const kYCRequestConfigKeyUrl = @"url"; // like `http://192.168.1.100:8888/response_code_list`

static NSString *const kYCRequestConfigKeyPath = @"path"; // like `/user`

static NSString *const kYCRequestConfigKeyMethod = @"method"; // like `get` or `post`

static NSString *const kYCRequestConfigKeyParam = @"param";

static NSString *const kYCRequestConfigKeyLink = @"link";

static NSString *const kYCRequestConfigKeyConsumes = @"consumes";

static NSString *const kYCRequestConfigKeyParamKey = @"key";

static NSString *const kYCRequestConfigKeyParamValue = @"value";

static NSString *const kYCRequestConfigKeyParamRename = @"rename";

static NSString *const kYCRequestConfigKeyParamType = @"paramType";

static NSString *const kYCRequestConfigKeyParamTypeQuery = @"query"; // add to url

static NSString *const kYCRequestConfigKeyParamTypeBody = @"body"; // add to post body

static NSString *const kYCRequestConfigKeyParamTypePath = @"path"; // in url like `/user/{id}`

static NSString *const kYCRequestConfigKeyParamTypeHeader = @"header"; // add to header

static NSString *const kYCRequestConfigKeyParamTypeForm = @"form"; // upload file

static NSString *const kYCRequestConfigKeyDeserialization = @"response"; // too long ,just `response`

//TODO
typedef NS_ENUM(NSUInteger, YCRequestConfigKeyParamType) {
    YCRequestConfigKeyParamTypeQuery,
    YCRequestConfigKeyParamTypeBody,
    YCRequestConfigKeyParamTypePath,
};

#ifdef DEBUG

#define YCDLog(s, ...) NSLog(@"< %@:(%d) > %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

#else

#define YCDLog(s, ...)

#endif

#endif /* _YCRequestPrivateDefine_h */
