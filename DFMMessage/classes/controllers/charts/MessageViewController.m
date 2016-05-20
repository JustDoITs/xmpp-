//
//  MessageViewController.m
//  DFMMessage
//
//  Created by dangfm on 14-5-6.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

#import "MessageViewController.h"
#import "MessageFrame.h"
#import "MessageCell.h"
#import "AppDelegate.h"
#import "XMPPFramework.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "LCVoice.h"
#import "SayView.h"
#import <AVFoundation/AVFoundation.h>
#import "FacialView.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "ZDcompressImage.h"
#import "NSData+Base64.h"
#define kChat_bottom_voice_nor [UIImage imageNamed:@"chat_bottom_voice_nor"]
#define kChat_bottom_voice_press [UIImage imageNamed:@"chat_bottom_voice_press"]
#define kChat_bottom_smile_nor [UIImage imageNamed:@"chat_bottom_smile_nor"]
#define kChat_bottom_smile_press [UIImage imageNamed:@"chat_bottom_smile_press"]
#define kChat_bottom_keyboard_nor [UIImage imageNamed:@"chat_bottom_keyboard_nor"]
#define kChat_bottom_keyboard_press [UIImage imageNamed:@"chat_bottom_keyboard_press"]

#define kKeyboradHeight 216


@interface MessageViewController ()
<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,XMPPChatDelegate,facialViewDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>
{
    NSMutableArray  *_allMessagesFrame;
    UIView *_toolView;
    UIButton *_pressSayButton;// 按住说话
    NSString *_userName;
    NSOperationQueue *_queue;
    int _page;
    BOOL _isLoadMore;
    UIActivityIndicatorView *_loadView;
    UILabel *_noMessageTipLb;
    UIScrollView *_scrollView;
    UIPageControl *_pageControl;
    UIButton *_faceButton;
    UIButton *_autio;
    UIButton *takePhotoBtn;
    NSData        *imageData;
    
}
@property(nonatomic,retain) LCVoice * voice;
@property (nonatomic,strong)UIImagePickerController *imagePicker;
@property (nonatomic,strong)UIImage                 *img;
@end

@implementation MessageViewController

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
    [self initViews];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [self initDatasWithPage];
     });
}

-(void)viewWillAppear:(BOOL)animated{
    [XMPPServer sharedServer].chatDelegate = self;
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
 //  [self free];
}

-(void)dealloc{
 //   [self free];
}

-(void)free{
    self.voice = nil;
    _allMessagesFrame = nil;
    _pressSayButton = nil;
    [_queue cancelAllOperations];
    _queue = nil;
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

#pragma mark 参数初始化
-(void)initParams{
    _page = 0;
    [XMPPServer sharedServer].chatDelegate = self;
    _queue = [[NSOperationQueue alloc] init];
    _allMessagesFrame = [NSMutableArray new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    // Init LCVoice
    self.voice = [[LCVoice alloc] init];
}

#pragma mark 视图初始化
-(void)initViews{
    self.view.userInteractionEnabled = YES;
    NSString *tojid = [NSString stringWithFormat:@"%@@%@",self.toJID.user,self.toJID.domain];
    [self initNavigationWithTitle:[CommonOperation getUserNickNameWithJID:tojid] IsBack:YES ReturnType:2];
    if (!_toolView) {
        CGFloat h = self.header.frame.size.height;
        CGFloat x = 0;
        CGFloat y = self.view.frame.size.height-h;
        CGFloat w = self.view.frame.size.width;
        _toolView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
        _toolView.backgroundColor = UIColorWithHex(0x0b171f);
        _toolView.userInteractionEnabled = YES;
        [self.view addSubview:_toolView];
        //设置textField输入起始位置
        w = 185;
        h = 30;
        _messageField = [[UITextField alloc] initWithFrame:CGRectMake(50, 7, w, h)];
        _messageField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
        _messageField.leftViewMode = UITextFieldViewModeAlways;
        _messageField.delegate = self;
        _messageField.layer.cornerRadius = 3;
        _messageField.layer.backgroundColor = UIColorWithHex(0xFFFFFF).CGColor;
        _messageField.returnKeyType=UIReturnKeySend;
        [_toolView addSubview:_messageField];
        
        // 录音
        UIImage *autioImg_press = kChat_bottom_voice_nor;
        _autio = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 50, _toolView.frame.size.height)];
        [_autio setImage:autioImg_press forState:UIControlStateNormal];
        [_autio setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 12)];
        _autio.tag = 10;
        [_toolView addSubview:_autio];
        [_autio addTarget:self action:@selector(changeVoiceImg:) forControlEvents:UIControlEventTouchUpInside];
  
        // 表情
        UIImage *faceimg = kChat_bottom_smile_nor;
        UIImage *faceimg_press = kChat_bottom_smile_press;;
        _faceButton = [[UIButton alloc] initWithFrame:CGRectMake(kScreenBounds.size.width-40-faceimg.size.width, 5, faceimg.size.width, faceimg.size.height)];
        [_faceButton setImage:faceimg forState:UIControlStateNormal];
        [_faceButton setImage:faceimg_press forState:UIControlStateHighlighted];
        [_faceButton addTarget:self action:@selector(showFaceView:) forControlEvents:UIControlEventTouchUpInside];
        _faceButton.tag = 11;
        [_toolView addSubview:_faceButton];
 
        // 加号
        UIImage *addimg = [UIImage imageNamed:@"chat_bottom_up_nor"];
        UIImage *addimg_press = [UIImage imageNamed:@"chat_bottom_up_press"];
        UIButton *add = [[UIButton alloc] initWithFrame:CGRectMake(kScreenBounds.size.width-5-addimg.size.width, 5, addimg.size.width, addimg.size.height)];
        [add setImage:addimg forState:UIControlStateNormal];
        [add setImage:addimg_press forState:UIControlStateHighlighted];
        [add addTarget:self action:@selector(addMore:) forControlEvents:UIControlEventTouchUpInside];
        [_toolView addSubview:add];
        add = nil;
        
        
        
    }
    if (!self.tableView) {
        CGFloat x = 0;
        CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
        CGFloat w = self.view.frame.size.width;
        CGFloat h = self.view.frame.size.height-y-_toolView.frame.size.height;
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(x, y, w, h) style:UITableViewStylePlain];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.allowsSelection = NO;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        //self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bg_default.jpg"]];
        self.tableView.backgroundColor = KClearColor;
        [self.view insertSubview:self.tableView atIndex:0];
        if (_allMessagesFrame.count>0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyborad:)];
        [self.tableView addGestureRecognizer:tap];
        tap = nil;

    }
    
    if (!_pressSayButton) {
        CGRect frame = _messageField.frame;
        _pressSayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _pressSayButton.frame = frame;
        _pressSayButton.contentEdgeInsets = UIEdgeInsetsZero;
        [_pressSayButton setTitle:@"按住说话" forState:UIControlStateNormal];
        [_pressSayButton setTitle:@"松开结束" forState:UIControlStateHighlighted];
        _pressSayButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [_pressSayButton setTitleColor:UIColorWithHex(0xFFFFFF) forState:UIControlStateNormal];
        _pressSayButton.layer.cornerRadius = 3;
        _pressSayButton.layer.backgroundColor = kTinColor.CGColor;
        [_toolView addSubview:_pressSayButton];
        _pressSayButton.hidden = YES;
        // Set record start action for UIControlEventTouchDown
        [_pressSayButton addTarget:self action:@selector(recordStart) forControlEvents:UIControlEventTouchDown];
        // Set record end action for UIControlEventTouchUpInside
        [_pressSayButton addTarget:self action:@selector(recordEnd) forControlEvents:UIControlEventTouchUpInside];
        [_pressSayButton addTarget:self action:@selector(recordExit) forControlEvents:UIControlEventTouchDragExit];
        [_pressSayButton addTarget:self action:@selector(recordIn) forControlEvents:UIControlEventTouchDragInside];
        // Set record cancel action for UIControlEventTouchUpOutside
        [_pressSayButton addTarget:self action:@selector(recordCancel) forControlEvents:UIControlEventTouchUpOutside];
    }
    
    if (!_loadView) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, -30, _tableView.frame.size.width, 30)];
        headerView.backgroundColor = KClearColor;
        _loadView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGFloat h = _loadView.frame.size.height;
        CGFloat x = (self.view.frame.size.width-_loadView.frame.size.width)/2;
        CGFloat y = 0;
        CGFloat w = _loadView.frame.size.width;
        _loadView.frame = CGRectMake(x, y, w, h);
       // [headerView addSubview:_loadView];
       // [_tableView addSubview:headerView];
        headerView = nil;
        _loadView.hidden = YES;
        [_loadView stopAnimating];
        // 提示框
        _noMessageTipLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.5, _tableView.frame.size.width, 30)];
        _noMessageTipLb.backgroundColor = kTinColor;
        _noMessageTipLb.alpha = 0;
        _noMessageTipLb.text = @"已无更多聊天记录";
        _noMessageTipLb.font = [UIFont systemFontOfSize:14];
        _noMessageTipLb.textColor = UIColorWithHex(0xFFFFFF);
        _noMessageTipLb.textAlignment = NSTextAlignmentCenter;
        [_tableView addSubview:_noMessageTipLb];
        _noMessageTipLb.hidden = YES;
    }
    
    [self initFaceViews];
}

-(void)initFaceViews{
    CGFloat x = 0;
    CGFloat h = kKeyboradHeight;
    CGFloat w = self.view.frame.size.width;
    CGFloat y = kScreenBounds.size.height + h;
    //创建表情键盘
    if (_scrollView==nil) {
        _scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(x, y, w, h)];
        [_scrollView setBackgroundColor:[UIColor clearColor]];
        for (int i=0; i<9; i++) {
            FacialView *fview=[[FacialView alloc] initWithFrame:CGRectMake(12+w*i, 5, w, h)];
            [fview setBackgroundColor:[UIColor clearColor]];
            [fview loadFacialView:i size:CGSizeMake(33, 43)];
            fview.delegate=self;
            [_scrollView addSubview:fview];
            fview = nil;
        }
        
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        _scrollView.contentSize=CGSizeMake(w*9, h);
        _scrollView.pagingEnabled=YES;
        _scrollView.delegate=self;
        [self.view addSubview:_scrollView];
    }
    
    if (!_pageControl) {
        _pageControl=[[UIPageControl alloc]initWithFrame:CGRectMake(98, _scrollView.frame.size.height+5, 150, 30)];
        [_pageControl setCurrentPage:0];
        _pageControl.pageIndicatorTintColor = UIColorWithHex(0x333333);
        _pageControl.currentPageIndicatorTintColor= UIColorWithHex(0xFF0000);
        _pageControl.numberOfPages = 9;//指定页面个数
        [_pageControl setBackgroundColor:[UIColor clearColor]];
        [_pageControl sizeToFit];
        _pageControl.frame = CGRectMake(kScreenBounds.size.width/2-100,_scrollView.frame.size.height+5,200,30);
        //_pageControl.hidden=YES;
        [_pageControl addTarget:self action:@selector(changePage:)forControlEvents:UIControlEventValueChanged];
        [_toolView addSubview:_pageControl];
    }
    
    //拍照
    takePhotoBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    takePhotoBtn.frame=CGRectMake(15, kScreenBounds.size.height+50, 50, 50);
    [takePhotoBtn setTitle:@"照片" forState:UIControlStateNormal];
    takePhotoBtn.backgroundColor=[UIColor lightGrayColor];
    [takePhotoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
   // takePhotoBtn.hidden=YES;
    [takePhotoBtn addTarget:self action:@selector(takePhotoBtnCl:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePhotoBtn];
 
}

-(void)initDatasWithPage{
   
        [_queue addOperationWithBlock:^{
            //while (!_isLoadMore && _page!=0);
            _page ++;
            NSLog(@"进入BLOCK");
            NSString *tojid = [NSString stringWithFormat:@"%@@%@",self.toJID.user,self.toJID.domain];
            NSString *myJID = [CommonOperation getMyJID];
            NSArray *mArray = [DataOperation selectWithPage:_page TableName:@"EMessages" Where:[NSString stringWithFormat:@"(send_jid='%@' or receive_jid='%@') and myJID='%@'",tojid,tojid,myJID] orderBy:@"time" sortType:NO andPageSize:10];
            NSString *userName;
            NSString *previousTime;
            NSString *tiime;
            for (int i=0;i<mArray.count;i++) {
                EMessages *e = [mArray objectAtIndex:i];
                MessageFrame *messageFrame = [[MessageFrame alloc] init];
                userName = [CommonOperation getUserNickNameWithJID:e.send_jid];
                if (e.messageType ==0) {
                    userName = [CommonOperation getUserNickNameWithJID:e.receive_jid];
                }
                tiime = [CommonOperation toDescriptionStringWithTimestamp:e.time];
                
                messageFrame.showTime = !([tiime isEqualToString:previousTime]);
                messageFrame.message = e;
                e.isRead = YES;
                [DataOperation save];
                previousTime = tiime;
                
                // 把最早的放在最前面
                [_allMessagesFrame insertObject:messageFrame atIndex:0];
                
                messageFrame = nil;
                e = nil;
            }
            userName = nil;
            previousTime = nil;
            tiime = nil;
            
            int _currentCellIndex = mArray.count;
            if (_currentCellIndex<=0) {
                _page --;
            }
            if (_page>1) {
                _currentCellIndex ++;
            }
            mArray = nil;
        }];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    int page = _scrollView.contentOffset.x / 320;//通过滚动的偏移量来判断目前页面所对应的小白点
    _pageControl.currentPage = page; //pagecontroll响应值的变化
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    _isLoadMore = YES;
}

// + 更多功能
-(void)addMore:(id)sender{
    _scrollView.hidden=YES;
    _pageControl.hidden=YES;
    takePhotoBtn.hidden=NO;
    [_messageField resignFirstResponder];
    CGFloat ty = - kKeyboradHeight;
    CGFloat x = 0;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height-y-_toolView.frame.size.height+ty;
    [UIView animateWithDuration:0.3 animations:^{
        _tableView.frame = CGRectMake(x, y, w, h);
        _toolView.frame = CGRectMake(x, y+h, _toolView.frame.size.width, _toolView.frame.size.height);
        _scrollView.frame = CGRectMake(x, kScreenBounds.size.height-kKeyboradHeight, w, kKeyboradHeight);
    } completion:^(BOOL finish){
        // 滚动至当前行
        if (_allMessagesFrame.count>0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
    [UIView animateWithDuration:0.3 animations:^{
        takePhotoBtn.frame=CGRectMake(15, kScreenBounds.size.height-200, 50, 50);
    }];

}

//拍照/图片 点击
-(void)takePhotoBtnCl:(id)sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"选择图片"
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:@"拍照"
                                  otherButtonTitles:@"从相册选择",nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];

}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            [self selectStyle:0];
            break;
        case 1:
            [self selectStyle:1];
            break;
        default:
            break;
    }
}

//判断我们使用的是哪一种访问方式
- (void)selectStyle:(NSInteger)buttonIndex{
    // [self.orderNumTextField resignFirstResponder];
    //    //创建imagePicker控制器
    _imagePicker = [[UIImagePickerController alloc]init];
    //    //设置imagePicker的代理对象
    _imagePicker.delegate = self;
    BOOL canUserCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear|UIImagePickerControllerCameraDeviceFront];
    switch (buttonIndex) {
        case 0:
            if (canUserCamera) {
                _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                _imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
                _imagePicker.showsCameraControls = YES;
                NSString *mediaType = AVMediaTypeVideo;
                AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                NSString *msg = [NSString stringWithFormat:@"请在手机【设置】-【隐私】-【相机】选项中，允许【%@】访问您的相机",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
                if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
                    [alert show];
                    return;
                }
            }else{
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"警告" message:@"该设备不支持摄像头" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
            break;
        case 1:
            _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        default:
            break;
    }
    //    //跳转到ios相册视图上
    [self presentViewController:_imagePicker animated:YES completion:nil];

}



#pragma mark -UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSString *mediaType = [info objectForKey:@"UIImagePickerControllerMediaType"];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        if (_imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera||_imagePicker.sourceType ==UIImagePickerControllerSourceTypePhotoLibrary) {
            //如果我们是用摄像头拍照，除了将它展示之外，还需要将图片保存到相册中
            // UIImageWriteToSavedPhotosAlbum(self.img, nil, nil, nil);
            self.img = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
             imageData= [ZDcompressImage compressImage:self.img toMaxLength:50000];
        }
    }else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
    }
    [self dismissViewControllerAnimated:YES completion:^{
        NSMutableString *imgbase64= [[NSMutableString alloc]initWithString:@"base64Image"];
        [imgbase64 appendString:[imageData base64EncodedString]];
        NSString *guid = [self sendMessageToFriendWithContent:imgbase64 MessageType:0 second:0 SendTyep:2];
        [self sendMessageWithBody:imgbase64 type:@"chat" GUID:guid];
        [self keyborddiss];
       }];
   
    
}

-(void)keyborddiss{
    CGFloat x = 0;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height-y-_toolView.frame.size.height;
    [UIView animateWithDuration:0.3 animations:^{
        if (_faceButton.tag==11) {
            _tableView.frame = CGRectMake(x, y, w, h);
            _toolView.frame = CGRectMake(x, y+h, _toolView.frame.size.width, _toolView.frame.size.height);
            _scrollView.frame = CGRectMake(x, kScreenBounds.size.height+kKeyboradHeight, w, kKeyboradHeight);
        }else{
            _scrollView.frame = CGRectMake(x, kScreenBounds.size.height-kKeyboradHeight, w, kKeyboradHeight);
        }
        [UIView animateWithDuration:0.5 animations:^{
            takePhotoBtn.frame=CGRectMake(15, kScreenBounds.size.height+50, 50, 50);
        }];
    } completion:^(BOOL finish){
        // 滚动至当前行
        if (_allMessagesFrame.count>0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
   
}

//取消图片选择
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    NSLog(@"我不需要选择任何东西");
    [self dismissViewControllerAnimated:YES completion:nil];
}



-(void)showFaceView:(UIButton*)button{
    if (button.tag==11) {
        [button setImage:kChat_bottom_keyboard_nor forState:UIControlStateNormal];
        button.tag = 110;
        // 显示语音按钮
        _pressSayButton.hidden = YES;
        _messageField.hidden = NO;
        _scrollView.hidden=NO;
        _pageControl.hidden=NO;
        takePhotoBtn.hidden=YES;
        [_autio setImage:kChat_bottom_voice_nor forState:UIControlStateNormal];
        
        [_messageField resignFirstResponder];
        CGFloat ty = - kKeyboradHeight;
        CGFloat x = 0;
        CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
        CGFloat w = self.view.frame.size.width;
        CGFloat h = self.view.frame.size.height-y-_toolView.frame.size.height+ty;
        [UIView animateWithDuration:0.3 animations:^{
            _tableView.frame = CGRectMake(x, y, w, h);
            _toolView.frame = CGRectMake(x, y+h, _toolView.frame.size.width, _toolView.frame.size.height);
            _scrollView.frame = CGRectMake(x, kScreenBounds.size.height-kKeyboradHeight, w, kKeyboradHeight);
        } completion:^(BOOL finish){
            // 滚动至当前行
            if (_allMessagesFrame.count>0) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }];
        
    }else{
        button.tag = 11;
        [button setImage:kChat_bottom_smile_nor forState:UIControlStateNormal];
        [_messageField becomeFirstResponder];
    }
    
    
}

#pragma mark 表情代理
-(void)selectedFacialView:(NSString *)str{
    NSLog(@"%@",str);
    _messageField.text = [_messageField.text stringByAppendingString:str];
}

#pragma mark pagecontroll的委托方法
- (void)changePage:(id)sender {
    int page = _pageControl.currentPage;//获取当前pagecontroll的值
    _pageControl.pageIndicatorTintColor = UIColorWithHex(0x333333);
    _pageControl.currentPageIndicatorTintColor= UIColorWithHex(0xFF0000);
    [_scrollView setContentOffset:CGPointMake(320 * page, 0)];//根据pagecontroll的值来改变scrollview的滚动位置，以此切换到指定的页面
}


#pragma mark - 键盘处理
#pragma mark 键盘即将显示
- (void)keyBoardWillShow:(NSNotification *)note{
    
    CGRect rect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat ty = - rect.size.height;
    CGFloat x = 0;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height-y-_toolView.frame.size.height+ty;
    [UIView animateWithDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        _tableView.frame = CGRectMake(x, y, w, h);
        _toolView.frame = CGRectMake(x, y+h, _toolView.frame.size.width, _toolView.frame.size.height);
    } completion:^(BOOL finish){
        // 滚动至当前行
        if (_allMessagesFrame.count>0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
    
}
#pragma mark 键盘即将退出
- (void)keyBoardWillHide:(NSNotification *)note{
    CGFloat x = 0;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height-y-_toolView.frame.size.height;
    [UIView animateWithDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        
        if (_faceButton.tag==11) {
            _tableView.frame = CGRectMake(x, y, w, h);
            _toolView.frame = CGRectMake(x, y+h, _toolView.frame.size.width, _toolView.frame.size.height);
            _scrollView.frame = CGRectMake(x, kScreenBounds.size.height+kKeyboradHeight, w, kKeyboradHeight);
        }else{
            _scrollView.frame = CGRectMake(x, kScreenBounds.size.height-kKeyboradHeight, w, kKeyboradHeight);

        }
        [UIView animateWithDuration:0.5 animations:^{
           takePhotoBtn.frame=CGRectMake(15, kScreenBounds.size.height+50, 50, 50);
        }];
          } completion:^(BOOL finish){
        // 滚动至当前行
        if (_allMessagesFrame.count>0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

-(void)hideKeyborad:(UIButton*)sender{
    _faceButton.tag = 11;
    [_faceButton setImage:kChat_bottom_smile_nor forState:UIControlStateNormal];
    if (_scrollView.frame.origin.y<kScreenBounds.size.height) {
        [_messageField becomeFirstResponder];
    }
    
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

-(NSString*)sendMessageToFriendWithContent:(NSString*)content MessageType:(int)messageType second:(CGFloat)second SendTyep:(int)sendTyep{
    NSString *guid;
    // 1、增加数据源
    double time = [CommonOperation getTimestamp];
    guid = [self addMessageWithContent:content time:time MessageType:messageType second:second SendTyep:sendTyep];
    // 2、刷新表格
        [self.tableView reloadData];
       NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
       [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    // 3、滚动至当前行
     return guid;
}
#pragma mark - 文本框代理方法
#pragma mark 点击textField键盘的回车按钮
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSString *guid = [self sendMessageToFriendWithContent:textField.text MessageType:0 second:0 SendTyep:0];
    [self sendMessageWithBody:_messageField.text type:@"chat" GUID:guid];
    _messageField.text = nil;
    return YES;
}
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    _faceButton.tag = 11;
    [_faceButton setImage:kChat_bottom_smile_nor forState:UIControlStateNormal];
}

#pragma mark 给数据源增加内容
- (NSString*)addMessageWithContent:(NSString *)content time:(double)time MessageType:(int)messageType second:(CGFloat)second SendTyep:(int)sendTyep{
    if ([content isEqualToString:@""]) {
        return @"";
    }
    __block NSString *guid;
    // 存储
    [DataOperation addUsingBlock:^(NSManagedObjectContext *context){
        guid = [CommonOperation guid];
        EMessages *message = [NSEntityDescription insertNewObjectForEntityForName:@"EMessages" inManagedObjectContext:context];
        message.send_jid = [CommonOperation getMyJID];
        message.receive_jid = [NSString stringWithFormat:@"%@@%@",self.toJID.user,self.toJID.domain];
        message.content = content;
        message.time = time;
        message.second = second;
        message.myJID = [CommonOperation getMyJID];
        message.messageType = messageType;
        message.isRead = YES;
        message.guid = guid;
        message.isSend = NO;
        message.sendTyep=sendTyep;
        [DataOperation save];
        MessageFrame *mf = [[MessageFrame alloc] init];
        mf.message = message;
        [_allMessagesFrame addObject:mf];
        mf = nil;
        message = nil;
    }];
    return guid;
}

- (void)sendMessageWithBody:(NSString*)body type:(NSString*)type GUID:(NSString*)guid{
    if (!type) {
        type = @"chat";
    }
    NSLog(@"%lu",(unsigned long)body.length);
    if (body.length<1)
        return;
        XMPPMessage *message = [XMPPMessage messageWithType:type to:self.toJID];
        [message addBody:body];
        XMPPElementReceipt *receipt;
        NSLog(@"开始发送...");
        // 加坐标
        EMe *me = [XMPPHelper my];
        // allInfo
        NSXMLElement *allInfo = [NSXMLElement elementWithName:@"allInfo" stringValue:me.allInfo];
        [message addChild:allInfo];
        allInfo = nil;
        [[XMPPServer sharedServer].xmppStream sendElement:message andGetReceipt:&receipt];
        NSArray *mesArray = [DataOperation select:@"EMessages" Where:[NSString stringWithFormat:@"guid='%@'",guid] orderBy:nil sortType:NO];
        if (mesArray.count>0) {
            EMessages *mes = [mesArray firstObject];
            // If you later want to wait until the element has been sent:
            if ([receipt wait:-1]) {
                // Element was sent
                mes.isSend = YES;
                [DataOperation save];
                NSLog(@"发送成功");
            } else {
                // Element failed to send due to disconnection
                NSLog(@"发送失败");
            }
        }
        
        message = nil;
        receipt = nil;
}



#pragma mark 点击语音变换交流状态
-(void)changeVoiceImg:(UIButton*)sender{
    // 点击了语音图标
    if (sender.tag==10) {
        // 更换图标
        if (_messageField.hidden==NO) {
            _faceButton.tag = 11;
            [_faceButton setImage:kChat_bottom_smile_nor forState:UIControlStateNormal];
            // 显示键盘图标
            [sender setImage:kChat_bottom_keyboard_nor forState:UIControlStateNormal];
            _messageField.hidden = YES;
            // 显示语音按钮
            _pressSayButton.hidden = NO;
            // 隐藏键盘
            [self hideKeyborad:nil];
            
        }else{
            // 显示语音图标
            [sender setImage:kChat_bottom_voice_nor forState:UIControlStateNormal];
            _messageField.hidden = NO;
            // 隐藏语音按钮
            _pressSayButton.hidden = YES;
            [_messageField becomeFirstResponder];
        }
    }
}



-(void) recordStart
{
    _pressSayButton.layer.backgroundColor = UIColorWithHex(0x006e95).CGColor;
    NSString *fileName = [NSString stringWithFormat:@"%f",[CommonOperation getTimestamp]];
    NSLog(@"文件名：%@",fileName);
    [self.voice startRecordWithPath:[NSString stringWithFormat:@"%@/Documents/%@.caf", NSHomeDirectory(),fileName]];
}

-(void) recordEnd
{
    _pressSayButton.layer.backgroundColor = kTinColor.CGColor;
    NSLog(@"recordEnd");
    [self.voice stopRecordWithCompletionBlock:^{
        
        if (self.voice.recordTime > 0.0f) {
            [self.voice cancelled];
            [self VoiceRecorderBaseVCRecordFinishWithfileName:self.voice.recordPath second:self.voice.recordTime];
            
            NSLog(@"多少秒：%f",self.voice.recordTime);
        }
        
    }];
}

-(void)recordIn{
    [self.voice showExitViews:NO];
}

-(void) recordExit{
    [self.voice showExitViews:YES];
}

-(void) recordCancel
{
    _pressSayButton.layer.backgroundColor = kTinColor.CGColor;
    NSLog(@"recordCancel");
    [self.voice cancelled];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"取消了" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    [alert show];
    alert = nil;
    
}

//录音完成回调，转换并发送数据
- (void)VoiceRecorderBaseVCRecordFinishWithfileName:(NSString*)_fileName second:(CGFloat)second{
    NSString *path = _fileName ;//[[_fileName stringByAppendingString:@".amr"] stringByReplacingOccurrencesOfString:@".caf" withString:@""];
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    if ([fileManager fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSString *base64 = [data base64EncodedString];
        [self sendAudio:base64 withName:_fileName second:second];
    }
}
-(void)sendAudio:(NSString *)base64String withName:(NSString *)audioName second:(CGFloat)second{
    NSMutableString *soundString = [[NSMutableString alloc]initWithString:@"base64Audio"];
    [soundString appendString:base64String];
    NSString *guid = [self sendMessageToFriendWithContent:soundString MessageType:0 second:second SendTyep:1];
    [self sendMessageWithBody:soundString type:@"chat" GUID:guid];
}


#pragma mark - tableView数据源方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _allMessagesFrame.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSString *CellIdentifier = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    
    
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // 设置数据
    cell.messageFrame = _allMessagesFrame[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [_allMessagesFrame[indexPath.row] cellHeight];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - 代理方法

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _faceButton.tag = 11;
    [_faceButton setImage:kChat_bottom_smile_nor forState:UIControlStateNormal];
    [self.view endEditing:YES];
}

#pragma mark 消息代理
-(void)didReceiveMessage:(XMPPMessage *)xmppMessage WithXMPPStream:(XMPPStream *)xmppStream andEMessage:(EMessages *)em{
    MessageFrame *messageFrame = [[MessageFrame alloc] init];
    messageFrame.message = em;
    [_allMessagesFrame addObject:messageFrame];
    messageFrame = nil;
    [_tableView reloadData];
    if (_allMessagesFrame.count>0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}
@end
