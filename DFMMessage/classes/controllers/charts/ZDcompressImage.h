//
//  ZDcompressImage.h
//  axdSMS
//
//  Created by louis on 16/3/30.
//  Copyright © 2016年 Zhi Duan Fingertip Tech. Co. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZDcompressImage : NSObject
+(NSData *) compressImage:(UIImage *)image toMaxLength:(NSInteger) maxLength;
@end
