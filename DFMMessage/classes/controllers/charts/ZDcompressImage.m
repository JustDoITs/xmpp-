//
//  ZDcompressImage.m
//  axdSMS
//
//  Created by louis on 16/3/30.
//  Copyright © 2016年 Zhi Duan Fingertip Tech. Co. Ltd. All rights reserved.
//

#import "ZDcompressImage.h"

@implementation ZDcompressImage
+(NSData *) compressImage:(UIImage *)image toMaxLength:(NSInteger) maxLength{
    CGSize newSize    = [self scaleImage:image withLength:500];
    UIImage *newImage = [self resizeImage:image withNewSize:newSize];
    CGFloat compress  = 0.9f;
    NSData *data      = UIImageJPEGRepresentation(newImage, compress);
    while (data.length > maxLength && compress > 0.01) {
        compress          -= 0.02f;
        data              = UIImageJPEGRepresentation(newImage, compress);
    }
    return data;
}
+(UIImage *) resizeImage:(UIImage *) image withNewSize:(CGSize) newSize{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(CGSize) scaleImage:(UIImage *) image withLength:(CGFloat) imageLength{
    CGFloat newWidth  = 0.1f;
    CGFloat newHeight = 0.1f;
    CGFloat width     = image.size.width;
    CGFloat height    = image.size.height;
    if (width > imageLength || height > imageLength){
        if (width > height) {
            newWidth          = imageLength;
            newHeight         = newWidth * height / width;
        }else if(height > width){
            newHeight         = imageLength;
            newWidth          = newHeight * width / height;
        }else{
            newWidth  = imageLength;
            newHeight = imageLength;
        }
    }
    return CGSizeMake(newWidth, newHeight);
}
@end
