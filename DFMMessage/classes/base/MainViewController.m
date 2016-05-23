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
    UIButton *messageBtn;
    UIButton *peopleBtn;
    UIButton *meBtn;
    
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
    [center addObserver:self selector:@selector(setViewmiss) name:@"setViewmiss" object:nil];
    
    
}
-(void)setViewmiss{
 [self changeControllersWithTag:0];
 [self changeBtnState:messageBtn btn1Color:[UIColor redColor] btn1Size:15 btn2:peopleBtn btn2Color:[UIColor whiteColor] btn2Size:12  btn3:meBtn btn3Color:[UIColor whiteColor] btn3Size:12 changeControllersWithTag:0];
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
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"setViewmiss" object:nil];
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
    messageBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    messageBtn.frame=CGRectMake(0, 0, 100, tab.frame.size.height);
    [messageBtn setTitle:@"消息" forState:UIControlStateNormal];
    [messageBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [messageBtn addTarget:self action:@selector(messageBtn) forControlEvents:UIControlEventTouchUpInside];
    messageBtn.selected=YES;
    messageBtn.titleLabel.font=[UIFont systemFontOfSize:16];
    [tab addSubview:messageBtn];
    
    peopleBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    peopleBtn.frame=CGRectMake(kScreenBounds.size.width/2-50, 0, 100, tab.frame.size.height);
    [peopleBtn setTitle:@"通讯录" forState:UIControlStateNormal];
    peopleBtn.titleLabel.font=[UIFont systemFontOfSize:13];
    [peopleBtn addTarget:self action:@selector(peopleBtn) forControlEvents:UIControlEventTouchUpInside];
    [tab addSubview:peopleBtn];

    meBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    meBtn.frame=CGRectMake(kScreenBounds.size.width-100, 0, 100, tab.frame.size.height);
    [meBtn setTitle:@"我" forState:UIControlStateNormal];
    meBtn.titleLabel.font=[UIFont systemFontOfSize:13];
    [meBtn addTarget:self action:@selector(meBtn) forControlEvents:UIControlEventTouchUpInside];
    [tab addSubview:meBtn];

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
-(void)messageBtn{
    [self changeBtnState:messageBtn btn1Color:[UIColor redColor] btn1Size:16 btn2:peopleBtn btn2Color:[UIColor whiteColor] btn2Size:13  btn3:meBtn btn3Color:[UIColor whiteColor] btn3Size:13 changeControllersWithTag:0];

}
-(void)peopleBtn{
    [self changeBtnState:peopleBtn btn1Color:[UIColor redColor] btn1Size:16 btn2:messageBtn btn2Color:[UIColor whiteColor] btn2Size:13 btn3:meBtn btn3Color:[UIColor whiteColor] btn3Size:13 changeControllersWithTag:1];
    
}
-(void)meBtn{
     [self changeBtnState:peopleBtn btn1Color:[UIColor whiteColor] btn1Size:13 btn2:messageBtn btn2Color:[UIColor whiteColor] btn2Size:13 btn3:meBtn btn3Color:[UIColor redColor] btn3Size:16 changeControllersWithTag:2];
}

-(void)changeBtnState:(UIButton *)btn1  btn1Color:(UIColor *)c1  btn1Size:(int)btn1Size  btn2:(UIButton *)btn2 btn2Color:(UIColor *)c2  btn2Size:(int)btn2Size btn3:(UIButton *)btn3 btn3Color:(UIColor *)c3 btn3Size:(int)btn3Size changeControllersWithTag:(int)tag{
    [btn1 setTitleColor:c1 forState:UIControlStateNormal];
    btn1.titleLabel.font=[UIFont systemFontOfSize:btn1Size];
    [btn2 setTitleColor:c2 forState:UIControlStateNormal];
    btn2.titleLabel.font=[UIFont systemFontOfSize:btn2Size];
    [btn3 setTitleColor:c3 forState:UIControlStateNormal];
    btn3.titleLabel.font=[UIFont systemFontOfSize:btn3Size];
    [self changeControllersWithTag:tag];

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
