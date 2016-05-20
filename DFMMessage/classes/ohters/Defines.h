//
//  Defines.h
//  dapai
//
//  Created by dangfm on 14-4-6.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

// 函数
#define UIColorWithHex(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define kSystemVersion [[UIDevice currentDevice].systemVersion floatValue]

#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)

// 公共视图尺寸定义
#define kTabBarNavigationHeight 50
#define kNavigationHeight 44
#define kCellHeight 50
#define kScreenBounds [UIScreen mainScreen].bounds
#define kImageWidth 68
#define kImageHeight 68
#define kImageCellHeight 88
// 颜色
#define kBackgroundImage [UIImage imageNamed:@"bg"]
#define kBackgroundColor [UIColor colorWithPatternImage:kBackgroundImage]

// 导航颜色
#define kTabBarBackgroundColor UIColorWithHex(0x0b171f)
#define kTabBarLineColor UIColorWithHex(0x0b171f)
#define kNavigationBackgroundColor UIColorWithHex(0x0b171f)
#define kNavigationLineColor UIColorWithHex(0x0b171f)
// 导航图标颜色
#define kMain_imgColor UIColorWithHex(0x999999)
#define kMain_imgHighlightColor UIColorWithHex(0x6F88DA)

#define KClearColor [UIColor clearColor]
// CELL的颜色
#define kCellBackground UIColorWithHex(0xFFFFFF)
#define kCellPressBackground UIColorWithHex(0xDDDDDD)
#define kCellBottomLineColor UIColorWithHex(0xDDDDDD)


#define kTinColor UIColorWithHex(0x14aff5)
#define kFontColor UIColorWithHex(0x131825)
#define kButtonColor UIColorWithHex(0xFFFFFF)
#define kButtonBackgroundColor UIColorWithHex(0xFFFFFF)

// XMPP
//本机地址 louisdemac-mini.local   192.168.3.10
//服务器地址  win-b1i94klqos0      103.44.145.248  :14263 //可以配置服外网服务器 设置好映射端口 就可以访问了
#define kROSTER @"ios"
#define kHostName @"louisdemac-mini.local"//
#define kServerName @"192.168.3.10"//:
#define kFilePort @"7777"

// 用户键名
#define USERID @"user_id"
#define NICKNAME @"nickName"
#define PASS @"pass"
#define SERVER @"server"
#define BODY @"body"
#define PHOTO @"photo"
#define TIME @"time"
#define TALKLIST @"talkList"

// 地图精度
#define kPrecision 12





#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)

