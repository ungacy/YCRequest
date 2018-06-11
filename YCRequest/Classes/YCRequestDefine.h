//
//  YCRequestDefine.h
//  YCRequest
//
//  Created by Ye Tao on 2018/6/11.
//  Copyright © 2018年 Ungacy. All rights reserved.
//

#ifndef YCRequestDefine_h
#define YCRequestDefine_h

#pragma mark - Result Block

#import <Foundation/Foundation.h>

typedef void (^YCRequestCompletionBlock)(BOOL isSuccess, id result);

FOUNDATION_EXPORT NSErrorDomain const YCRequestErrorDomain;

FOUNDATION_EXPORT const NSInteger YCRequestErrorCode;

FOUNDATION_EXPORT const NSTimeInterval YCRequestDefaultTimeout;

FOUNDATION_EXPORT NSString *YCRequestURLEncode(id /*NSString or NSNumber*/ value);

typedef NS_ENUM(NSUInteger, YCRequestStatus) {
    YCRequestStatusBegin,
    YCRequestStatusFinish,
    YCRequestStatusFailed,
};

#endif /* YCRequestDefine_h */
