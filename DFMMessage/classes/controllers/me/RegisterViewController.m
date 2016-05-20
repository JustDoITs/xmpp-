//
//  RegisterViewController.m
//  DFMMessage
//
//  Created by dangfm on 14-5-13.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

#import "RegisterViewController.h"
#import "AppDelegate.h"


@interface RegisterViewController()<XMPPChatDelegate,UIAlertViewDelegate,UITextFieldDelegate>{
    UIButton *_countryCode;
    UITextField *userNameTF;
    UITextField *passWoedTF;
    UIView *_registerView;
    NSString *_oldValue;
    UIButton *_loginBt;
    
    BOOL isup;//
}

@end

@implementation RegisterViewController

-(void)viewDidLoad{
    // 视图初始化
    [self initParams];
    [self initViews];
    isup=YES;
}
-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = YES;
    [XMPPServer sharedServer].chatDelegate = self;
}

#pragma mark ------------------------------初始化视图
-(void)initParams{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
#pragma mark 初始化
-(void)initViews{
    [self initNavigationWithTitle:@"注册" IsBack:YES ReturnType:1];
    // self.view.backgroundColor = UIColorWithHex(0xFFFFFF);
    _registerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    CGFloat h = 50;
    CGFloat x = 15;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y+10;
    CGFloat w = self.view.frame.size.width-2*x;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickViewAction)];
    [self.view addGestureRecognizer:tap];
    tap = nil;
    UIFont *font = [UIFont systemFontOfSize:16];
    
    // 请输入账号和密码
    UILabel *des = [[UILabel alloc] init];
    des.text = @"请输入账号和密码";
    des.textColor = UIColorWithHex(0x999999);
    des.font = font;
    [des sizeToFit];
    des.frame = CGRectMake((self.view.frame.size.width-des.frame.size.width)/2, y, des.frame.size.width, des.frame.size.height);
    y = des.frame.size.height + des.frame.origin.y+10;
    [_registerView addSubview:des];
    des = nil;
    

    //textfilde
    userNameTF=[[UITextField alloc]initWithFrame:CGRectMake(20, y+20, kScreenBounds.size.width-40, 40)];
    userNameTF.borderStyle=UITextBorderStyleRoundedRect;
    userNameTF.placeholder=@"账号";
    [self.view addSubview:userNameTF];
    passWoedTF=[[UITextField alloc]initWithFrame:CGRectMake(20, y+20+50, kScreenBounds.size.width-40, 40)];
    passWoedTF.borderStyle=UITextBorderStyleRoundedRect;
    passWoedTF.placeholder=@"密码";
    [self.view addSubview:passWoedTF];
    
    
    
    // 注册按钮
    x = 15;
    w = self.view.frame.size.width-2*x;
    UIButton *loginBt = [[UIButton alloc] initWithFrame:CGRectMake(x, y+140, w, h)];
    [loginBt setTitle:@"注册" forState:UIControlStateNormal];
    [loginBt setTitleColor:UIColorWithHex(0x90abbe) forState:UIControlStateNormal];
    [loginBt setBackgroundImage:[CommonOperation imageWithColor:kNavigationLineColor andSize:loginBt.frame.size] forState:UIControlStateHighlighted];
    loginBt.layer.backgroundColor = kNavigationBackgroundColor.CGColor;
    loginBt.layer.masksToBounds = YES;
    loginBt.layer.cornerRadius = h/2;
    [loginBt addTarget:self action:@selector(registButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [_registerView addSubview:loginBt];
    _loginBt = loginBt;
    loginBt = nil;
    
    
    [self.view addSubview:_registerView];
    [self.view sendSubviewToBack:_registerView];
}


#pragma mark ------------------------------视图响应方法
-(void)clickSelectCountryCode{
    [self clickViewAction];
}

-(void)registButtonAction{
    [self clickViewAction];
    if (userNameTF.text.length>0 ||passWoedTF.text.length>0) {

        // 连接服务器
        [[XMPPServer sharedServer] connect];
        [[LoadingView instance] start:@"正在验证..."];
        
        [XMPPHelper registerWithUserName:userNameTF.text Pass:passWoedTF.text];
    }else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"输入错误" message:@"请填写正确的账号和密码" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
            [alert show];
            alert = nil;
            return;
    }
}
    


-(void)clickViewAction{
    [self.view endEditing:YES];
}

#pragma mark 键盘通知
-(void)keyboardWillShow:(NSNotification*)notification{
    
    if (isup==YES) {
         isup=NO;
        if (iPhone4) {
            
            CGRect nametf=userNameTF.frame;
            nametf.origin.y-=25;
            userNameTF.frame=nametf;
            
            CGRect passtf=passWoedTF.frame;
            passtf.origin.y-=25;
            passWoedTF.frame=passtf;
            
            CGRect logbtn=_loginBt.frame;
            logbtn.origin.y-=40;
            _loginBt.frame=logbtn;
            
        }else{
            
            CGRect rt = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
            UIButton *loginBt = [_registerView.subviews lastObject];
            CGFloat h = (self.view.frame.size.height-rt.size.height) - (loginBt.frame.origin.y+loginBt.frame.size.height);
            if (h<0) {
                CGRect frame = _registerView.frame;
                frame.origin = CGPointMake(frame.origin.x, h-20);
                [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
                    _registerView.frame = frame;
                } completion:^(BOOL isFinish){}];
            }
        }
    }
    
}

-(void)keyboardWillHide:(NSNotification*)notification{
    if (isup==NO) {
        isup=YES;
        if (iPhone4) {
            
            CGRect nametf=userNameTF.frame;
            nametf.origin.y+=25;
            userNameTF.frame=nametf;
            
            CGRect passtf=passWoedTF.frame;
            passtf.origin.y+=25;
            passWoedTF.frame=passtf;
            
            CGRect logbtn=_loginBt.frame;
            logbtn.origin.y+=40;
            _loginBt.frame=logbtn;
            
            
            
        }else{
    
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        _registerView.frame = frame;
    } completion:^(BOOL isFinish){}];
    
        }
    }
}


#pragma mark 文本框输入事件
-(void)textFieldDidChange:(UITextField *)textField{
    
    NSString *value = textField.text;
    int length = value.length;
    int kong = [value componentsSeparatedByString:@" "].count;
    kong --;
    length -= kong;
    int newLength = kong * 4 + 3;
    NSLog(@"%d==%d",length,newLength);
    if (length==newLength && ![_oldValue isEqualToString:[value stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
        value = [value stringByAppendingString:@" "];
    }
    textField.text = value;
    _oldValue = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([textField.text isEqualToString:@""]) {
        [_loginBt setTitleColor:UIColorWithHex(0x90abbe) forState:UIControlStateNormal];
        _loginBt.enabled = NO;
    }else{
        _loginBt.enabled = YES;
        [_loginBt setTitleColor:UIColorWithHex(0xFFFFFF) forState:UIControlStateNormal];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSLog(@"%@",string);
    return YES;
}

#pragma mark 消息代理
-(void)xmppServerConnectState:(int)state WithXMPPStream:(XMPPStream *)xmppStream{
    // 注册成功
    if (state==8) {
        [[LoadingView instance] stop:@"注册成功" time:2];
        [[XMPPServer sharedServer] disconnect];
        // 保存用户信息
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:userNameTF.text forKey:USERID];
        [defaults setObject:passWoedTF.text forKey:PASS];
        //保存
        [defaults synchronize];
        [[XMPPServer sharedServer]getOnline];
        [self dismissViewControllerAnimated:YES completion:^{
            NSNotification * notice = [NSNotification notificationWithName:@"registerMiss" object:nil userInfo:nil];
            [[NSNotificationCenter defaultCenter]postNotification:notice];
        }];
    }
    if (state==9) {
        [[LoadingView instance] stop:@"注册失败" time:0];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"注册失败" message:@"手机号冲突,请更换手机号或者用此手机号登录" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
        [alert show];
        alert = nil;
    }
}


@end
