//
//  MainViewController.m
//  dapai
//
//  Created by dangfm on 14-4-6.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

#import "MainViewController.h"
#import "FriendsViewController.h"
#import "LoginViewController.h"
#import "MessageViewController.h"
#import "TalkViewController.h"

#import "UsersViewController.h"
#import "CommonOperation.h"

@interface MainViewController ()
{
    BaseViewController *_currentController;
    UIView *_contentView;
    NSArray *_tabTitles;
    NSArray *_tabImgs;
    NSArray *_tabImgs_highlights;
    UILabel *_cricle;
    NSNotificationCenter * center;
    
}
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initParams];
    // 初始化视图
    [self initViews];
    // 初始化控制器
    [self initControllers];
    
    
    
    center = [NSNotificationCenter defaultCenter];
    //添加当前类对象为一个观察者，name和object设置为nil，表示接收一切通知
    [center addObserver:self selector:@selector(logmiss) name:@"logmiss" object:nil];
    
    
}
-(void)logmiss{
    [self changeControllersWithTag:0];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (![CommonOperation getMyJID]) {
        [self presentViewController:[[LoginViewController alloc]init] animated:YES completion:nil];
    }
    //隐藏标题栏
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

-(void)dealloc{
    _currentController = nil;
    _contentView = nil;
    _tabTitles = nil;
    _tabImgs_highlights = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"logmiss" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ---------------------------------自定义的方法--------------------------
-(void)initParams{
    _tabTitles = [NSArray arrayWithObjects:@"消息",@"通讯录",@"我", nil];

}
#pragma mark 初始化栏目控制器
-(void)initControllers{
    // current talk
    TalkViewController *talks = [[TalkViewController alloc] init];
    [self addChildViewController:talks];
   
    // 朋友列表
    FriendsViewController *more = [[FriendsViewController alloc] init];
    [self addChildViewController:more];

    // User
    UsersViewController *user = [[UsersViewController alloc] init];
    [self addChildViewController:user];
    
    // 当前controller
    _currentController = talks;
    CGFloat h = kScreenBounds.size.height-kTabBarNavigationHeight;
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, h)];
    _contentView.backgroundColor = kBackgroundColor;
    [_contentView addSubview:_currentController.view];
    _currentController.view.frame = _contentView.bounds;
    [self.view addSubview:_contentView];
    // 点击第一个
    [self changeControllersWithTag:0];
}

#pragma mark 初始化视图
-(void)initViews{
    // 底部导航栏
    UIView *tab = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenBounds.size.height-kTabBarNavigationHeight, self.view.frame.size.width, kTabBarNavigationHeight)];
    tab.backgroundColor = kTabBarBackgroundColor;
    // 导航栏栏目
    CGFloat x = 0;
    CGFloat y = 5;
    CGFloat w = tab.frame.size.width/_tabTitles.count;
    CGFloat h = tab.frame.size.height;
    for (int i=0; i<_tabTitles.count; i++) {
        UIImage *img = [UIImage imageNamed:[_tabImgs objectAtIndex:i]];
        img = [CommonOperation imageWithTintColor:kMain_imgColor blendMode:kCGBlendModeDestinationIn WithImageObject:img];
        UIImage *img_press = [CommonOperation imageWithTintColor:kMain_imgHighlightColor blendMode:kCGBlendModeDestinationIn WithImageObject:img];
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
       // [b setImage:img forState:UIControlStateNormal];
        //[b setImage:img_press forState:UIControlStateHighlighted];
        [b setImageEdgeInsets:UIEdgeInsetsMake(0, 15, 20, 0)];
        NSString *title = [_tabTitles objectAtIndex:i] ;
        [b setTitle:title forState:UIControlStateNormal];
        [b setTitleColor:kMain_imgColor forState:UIControlStateNormal];
        //[b setTitleColor:kTinColor forState:UIControlStateHighlighted];
        b.titleLabel.textAlignment = NSTextAlignmentCenter;
        b.titleLabel.font = [UIFont systemFontOfSize:15];
        if (i==1) {
            [b setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 2, 0)];
        }
        if (i==0) {
            [b setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            b.selected=YES;
        }
        b.tag = i;
        [b addTarget:self action:@selector(clickTabButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [tab addSubview:b];
        b = nil;
        x += w;
        img_press = nil;
        img = nil;
    }
    [CommonOperation drawLineAtSuperView:tab andTopOrDown:0 andHeight:0.5 andColor:kTabBarLineColor];
    self.footer = tab;
    tab = nil;
    [self.view addSubview:self.footer];
    if (kSystemVersion<7) {
        CGRect frame=self.footer.frame;
        frame.origin.y-=20;
        self.footer.frame=frame;
    }
}

#pragma mark 点击切换按钮
-(void)clickTabButtonAction:(UIButton*)button{
    int tag = button.tag;
    [self changeControllersWithTag:tag];
    NSArray *buttons = [self.footer subviews];
    for (int i=0; i<buttons.count; i++) {
        UIButton *b = [buttons objectAtIndex:i];
        if ([[b class] isSubclassOfClass:[UIButton class]]) {
            UIImage *img = [UIImage imageNamed:[_tabImgs objectAtIndex:i]];
            img = [CommonOperation imageWithTintColor:kMain_imgColor blendMode:kCGBlendModeDestinationIn WithImageObject:img];
           // [b setImage:img forState:UIControlStateNormal];
            [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            b.backgroundColor = KClearColor;
            img = nil;
        }
        b = nil;
    }
    UIImage *img = [UIImage imageNamed:[_tabImgs objectAtIndex:tag]];
    UIImage *img_press = [CommonOperation imageWithTintColor:kMain_imgHighlightColor blendMode:kCGBlendModeDestinationIn WithImageObject:img];
   // [button setImage:img_press forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor]forState:UIControlStateNormal];

    img = nil;
    img_press = nil;
}


#pragma mark 切换控制器
-(void)changeControllersWithTag:(int)tag{
    if (tag>=self.childViewControllers.count) {
        return;
    }
    BaseViewController *c = [self.childViewControllers objectAtIndex:tag];
    c.footer = self.footer;
    c.view.frame = _contentView.bounds;
    [self.view bringSubviewToFront:self.footer];
    if (_currentController==c) {
        return;
    }
    [_contentView addSubview:c.view];
    // 移除旧视图
    [_currentController.view removeFromSuperview];
    _currentController = c;
    
}



@end
