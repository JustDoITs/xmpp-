//
//  TalkViewController.m
//  DFMMessage
//
//  Created by dangfm on 14-5-17.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

#import "TalkViewController.h"
#import "AppDelegate.h"
#import "MessageViewController.h"
#import "LoginViewController.h"
#import "SWTableViewCell.h"
#import "MaskView.h"
#import "KxMenu.h"
#import "MIBadgeButton.h"
@interface TalkViewController ()<UITableViewDataSource,UITableViewDelegate,XMPPChatDelegate,SWTableViewCellDelegate>{
    UITableView *_tableView;
    NSMutableArray *_datas;
    NSMutableDictionary *_talksDic;
    CLLocation *_checkinLocation;
    NSString *jidUser;
    NSNotificationCenter *center;
    int num;
}


@end

@implementation TalkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [self initParams];
    [self initViews];
    [self titleWithName:@"消息"];
    center = [NSNotificationCenter defaultCenter];
    //添加当前类对象为一个观察者，name和object设置为nil，表示接收一切通知
    [center addObserver:self selector:@selector(removeFriend:) name:@"removeFriend" object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [XMPPServer sharedServer].chatDelegate = self;
        [super viewWillAppear:animated];
    if ([XMPPServer sharedServer].isLogin) {
        [self titleWithName:@"消息"];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}
-(void)removeFriend:(NSNotification *)not{
    
    for (int i=0; i<_datas.count; i++) {
        ETalks *mssage = [_datas objectAtIndex:i];
        if ([[not object] isEqualToString:mssage.jid]) {
            [DataOperation deleteWithManagedObject:[_datas objectAtIndex:i]];
            [DataOperation save];
            [_datas removeObjectAtIndex:i];
            [_tableView reloadData];
             [CommonOperation circleTipWithNumber:0 SuperView:[[self.footer subviews]firstObject] WithPoint:(iPhone5?CGPointMake(65, 0):(iPhone6?CGPointMake(70, 0):CGPointMake(80, 0)))];
        }
    }
}

-(void)dealloc{
    _tableView = nil;
    _datas = nil;
    _talksDic = nil;
     [[NSNotificationCenter defaultCenter]removeObserver:self name:@"removeFriend" object:nil];
}

-(void)initParams{
    [XMPPHelper sendVCardIQ];
}
-(void)initViews{
    [self initNavigationWithTitle:@"消息" IsBack:NO ReturnType:2];
    self.view.backgroundColor = KClearColor;
    self.view.userInteractionEnabled = YES;
    CGFloat x = 0;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y;
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height-y-self.header.frame.size.height;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(x,y,w,h) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = kBackgroundColor;
    _tableView.separatorColor = kCellBottomLineColor;
    _tableView.rowHeight = kImageCellHeight;
    //[_tableView setEditing:YES animated:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCellMoreButtons)];
    [_tableView addGestureRecognizer:tap];
    tap = nil;
    [self.view addSubview:_tableView];
    
}
-(void)initWithDatas{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *myJID = [CommonOperation getMyJID];
        _datas = [NSMutableArray arrayWithArray:[DataOperation select:@"ETalks" Where:[NSString stringWithFormat:@"myJID='%@'",myJID] orderBy:@"userName" sortType:YES]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_tableView) {
                [_tableView reloadData];
            }
        });
        
    });
}

-(void)addButtonView{
    CGFloat w = 44;
    CGFloat h = 44;
    CGFloat x = self.header.frame.size.width-w;
    CGFloat y = (self.header.frame.size.height-h)/2;
    UIButton *add = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
    [add setTitle:@"+" forState:UIControlStateNormal];
    add.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    add.titleLabel.textColor = kButtonColor;
    add.backgroundColor = KClearColor;
    [add addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:add];
    add = nil;
}




-(void)createMoreButtonsViewWithIndex:(int)index{
    NSLog(@"%d",index);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    SWTableViewCell *cell = (SWTableViewCell*)[_tableView cellForRowAtIndexPath:indexPath];
    MaskView *mask = [[MaskView alloc] initWithAlpha:0.5 Height:220];
    mask.sportView.backgroundColor = kBackgroundColor;
    mask.sportView.tag = index;
    CGFloat h = 40;
    CGFloat y = mask.sportView.frame.size.height - h - 10;
    CGFloat w = mask.sportView.frame.size.width - 20;
    CGFloat x = 10;
    // 取消按钮
    UIButton *bt = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
    bt.backgroundColor = KClearColor;
    [bt setTitle:@"取   消" forState:UIControlStateNormal];
    [bt setTitleColor:UIColorWithHex(0xFFFFFF) forState:UIControlStateNormal];
    [bt setTitleColor:UIColorWithHex(0xCCCCCC) forState:UIControlStateHighlighted];
    bt.layer.cornerRadius = 5;
    bt.layer.backgroundColor = kNavigationBackgroundColor.CGColor;
    [bt addTarget:mask action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [mask.sportView addSubview:bt];
    bt = nil;
    //三个按钮
    NSArray *titles = @[@"标为未读",@"置顶聊天",@"屏蔽消息"];
    y = 10;
    
    for (int i=0; i<titles.count; i++) {
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
        b.tag = i;
        [b setTitle:[titles objectAtIndex:i] forState:UIControlStateNormal];
        [b setTitleColor:kFontColor forState:UIControlStateNormal];
        [b setTitleColor:kFontColor forState:UIControlStateHighlighted];
        //[b setBackgroundImage:[CommonOperation imageWithColor:KClearColor andSize:CGSizeMake(w, h)] forState:UIControlStateNormal];
        [b setBackgroundImage:[CommonOperation imageWithColor:kCellBottomLineColor andSize:CGSizeMake(w, h)] forState:UIControlStateHighlighted];
        b.layer.masksToBounds = YES;
        b.layer.cornerRadius = 5;
        b.layer.backgroundColor = kButtonBackgroundColor.CGColor;
        b.layer.borderColor = kCellBottomLineColor.CGColor;
        b.layer.borderWidth = 0.5;
        [b addTarget:self action:@selector(clickMoreButtonWithIndex:) forControlEvents:UIControlEventTouchUpInside];
        [mask.sportView addSubview:b];
        b = nil;
        y += h + 10;
    }
    [mask show:nil];
    mask.hideFinishBlock = ^{
        [cell hideUtilityButtonsAnimated:YES];
    };
    mask = nil;
    cell = nil;
    titles = nil;
}
#pragma mark 点击 标为未读，置顶，屏蔽消息按钮
-(void)clickMoreButtonWithIndex:(UIButton*)button{
    UIView *superView = [button superview];
    int cellIndex = superView.tag;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cellIndex inSection:0];
    SWTableViewCell *cell = (SWTableViewCell*)[_tableView cellForRowAtIndexPath:indexPath];
    MaskView *mask = (MaskView*)[superView superview];
    mask.hideFinishBlock = ^{
        [cell hideUtilityButtonsAnimated:YES];
        NSLog(@"%d-%d",button.tag,cellIndex);
    };
    // 处理按钮事件
    switch (button.tag) {
        case 0:
            // 标为未读
            break;
        case 1:
            // 标为置顶
            break;
        case 2:
            // 标为屏蔽
            break;
            
        default:
            break;
    }
    
    [mask hide];
    mask = nil;
    cell = nil;
    indexPath = nil;
    
}

#pragma mark 所有的CELL
-(void)hideCellMoreButtons{
    for (int i=0; i<_datas.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        SWTableViewCell *cell = (SWTableViewCell*)[_tableView cellForRowAtIndexPath:indexPath];
        [cell hideUtilityButtonsAnimated:YES];
        cell = nil;
    }
}


- (void)showMenu:(UIButton *)sender
{
    UIImage *qunliao = [CommonOperation imageWithTintColor:kButtonColor blendMode:kCGBlendModeDestinationIn WithImageObject:[UIImage imageNamed:@"qunliao"]];
    
    UIImage *guangbo = [CommonOperation imageWithTintColor:kButtonColor blendMode:kCGBlendModeDestinationIn WithImageObject:[UIImage imageNamed:@"guangbo"]];
    
    UIImage *paizhao = [CommonOperation imageWithTintColor:kButtonColor blendMode:kCGBlendModeDestinationIn WithImageObject:[UIImage imageNamed:@"paizhao"]];
    
    UIImage *chayicha = [CommonOperation imageWithTintColor:kButtonColor blendMode:kCGBlendModeDestinationIn WithImageObject:[UIImage imageNamed:@"chayicha"]];
    
    NSArray *menuItems =
    @[
      
      [KxMenuItem menuItem:@"发起群聊"
                     image:qunliao
                    target:self
                    action:@selector(pushMenuItem:)],
      
      [KxMenuItem menuItem:@"附近广播"
                     image:guangbo
                    target:self
                    action:@selector(pushMenuItem:)],
      [KxMenuItem menuItem:@"拍照分享"
                     image:paizhao
                    target:self
                    action:@selector(pushMenuItem:)],
      [KxMenuItem menuItem:@"查一查"
                     image:chayicha
                    target:self
                    action:@selector(pushMenuItem:)],
      ];
    
    KxMenuItem *first = menuItems[0];
    first.foreColor = UIColorWithHex(0xFFFFFF);
    first.alignment = NSTextAlignmentCenter;
    KxMenuItem *second = menuItems[1];
    second.foreColor = UIColorWithHex(0xFFFFFF);
    second.alignment = NSTextAlignmentCenter;
    KxMenuItem *three = menuItems[2];
    three.foreColor = UIColorWithHex(0xFFFFFF);
    three.alignment = NSTextAlignmentCenter;
    KxMenuItem *fore = menuItems[3];
    fore.foreColor = UIColorWithHex(0xFFFFFF);
    fore.alignment = NSTextAlignmentCenter;
    
    
    CGRect frame = sender.frame;
    if (kSystemVersion>=7) {
        frame.origin.y = self.header.frame.origin.y + 2;
        frame.origin.x = frame.origin.x - 10;
    }else{
        frame.origin.y = frame.origin.y + 2;
    }
    
    [KxMenu setTintColor:kNavigationBackgroundColor];
    [KxMenu setTitleFont:[UIFont systemFontOfSize:14]];
    
    [KxMenu showMenuInView:self.view
                  fromRect:frame
                 menuItems:menuItems];
    
    
}

- (void) pushMenuItem:(id)sender
{
    NSLog(@"%@", sender);
}


#pragma mark 表格代理实现

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kImageCellHeight;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return _datas.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.001;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int row = indexPath.row;
    static NSString *cellIdentifier = @"cell";
    SWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        [rightUtilityButtons addUtilityButtonWithColor:UIColorWithHex(0xacb4b8)
                                                 title:@"更多"];
        [rightUtilityButtons addUtilityButtonWithColor:UIColorWithHex(0xFF0000)
                                                 title:@"删除"];
        
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier
                                  containingTableView:_tableView // Used for row height and selection
                                   leftUtilityButtons:nil
                                  rightUtilityButtons:rightUtilityButtons];
        
        cell.delegate = self;
        
        
        [cell setBackgroundColor:kCellBackground];
        cell.contentView.backgroundColor = kCellBackground;
        cell.backgroundColor = kCellBackground;
        
        UIView *view = [[UIView alloc] initWithFrame:cell.contentView.frame];
        view.backgroundColor = kCellPressBackground;
        cell.selectedBackgroundView = view;
        view = nil;
        
        CGRect frame = cell.bounds;
        frame.origin.y = kImageCellHeight;
        frame.size.height = 0.5;
        frame = cell.bounds;
        // imageview
        UIImage *face = [UIImage imageNamed:@"noface"];
        UIImageView *faceView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, kImageWidth, kImageHeight)];
        faceView.image = face;
        faceView.layer.cornerRadius = 3;
        faceView.layer.masksToBounds = YES;
        faceView.backgroundColor = KClearColor;
        [cell.contentView addSubview:faceView];
        // title
        CGFloat x = faceView.frame.size.width+faceView.frame.origin.x+10;
        CGFloat w = cell.frame.size.width - x;
        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(x, 20, w, 30)];
        t.backgroundColor = KClearColor;
        t.textColor = kFontColor;
        t.font=[UIFont systemFontOfSize:18];
        [cell.contentView addSubview:t];
        // description
        UILabel *d = [[UILabel alloc] initWithFrame:CGRectMake(x, 50, w, 30)];
        d.backgroundColor = KClearColor;
        d.textColor = UIColorWithHex(0x999999);
        d.font = [UIFont systemFontOfSize:15];
        [cell.contentView addSubview:d];
        // time
        UILabel *time = [[UILabel alloc] initWithFrame:CGRectMake(kScreenBounds.size.width-120,cell.contentView.frame.size.height-30, 100, 30)];
        time.textColor = UIColorWithHex(0x999999);
        time.font = [UIFont systemFontOfSize:14];
        time.textAlignment = NSTextAlignmentRight;
        time.backgroundColor = KClearColor;
        [cell.contentView addSubview:time];
        
      

        faceView = nil;
        face = nil;
        t = nil;
        d = nil;
        time = nil;
        
    }
    
    NSLog(@"%@",_datas);
    
    if (row<_datas.count) {
        for (int i; i<_datas.count; i++) {
        }
        ETalks *mssage = [_datas objectAtIndex:row];
        XMPPJID *toJID = [XMPPJID jidWithString:mssage.jid];
        NSArray *views = [cell.contentView subviews];
        // face
        UIImageView *faceView = [views firstObject];
        faceView.image = [XMPPHelper xmppUserPhotoForJID:[XMPPJID jidWithString:mssage.jid]];
        // title
        UILabel *t = [views objectAtIndex:1];
        t.text = mssage.userName;
        
        if (t.text.length<1) {
            t.text = toJID.user;
        }
        [t sizeToFit];
        t = nil;
        // description
        UILabel *d = [views objectAtIndex:2];
        d.text = mssage.content;
        if ([mssage.content hasPrefix:@"base64"]) {
            if ([[mssage.content substringWithRange:NSMakeRange(0, 11)] isEqualToString:@"base64Audio"]) {
               d.text = @"语音";
            }else{
               d.text = @"图片";
            
            }
        }
        [d sizeToFit];
        d = nil;
        // time
        UILabel *time = [views objectAtIndex:3];
        time.text = [CommonOperation toDescriptionStringWithTimestamp:mssage.time];
        time = nil;
        MIBadgeButton *btn1 = [MIBadgeButton buttonWithType:UIButtonTypeCustom];
        [btn1 setFrame:CGRectMake(kScreenBounds.size.width-60, 60, 10, 10)];
        [btn1 setBadgeBackgroundColor:[UIColor redColor]];
        [btn1 setBadgeTextColor:[UIColor whiteColor]];
        [cell.contentView addSubview:btn1];

        if (num>0) {
           [btn1 setBadgeString:[NSString stringWithFormat:@"%d",num]];
        }else if(num==0){
            for (UIButton *btn in cell.contentView.subviews) {
                if ([btn isKindOfClass:[ MIBadgeButton class]]) {
                    [btn removeFromSuperview];
                }
            }
        }
        mssage = nil;
        toJID = nil;
    }
        return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int row = indexPath.row;
    ETalks *mssage = [_datas objectAtIndex:row];
    MessageViewController *ms = [[MessageViewController alloc] init];
    XMPPJID *toJID = [XMPPJID jidWithString:mssage.jid];
    ms.toJID = toJID;
    toJID = nil;
    [self performSelector:@selector(pushViewController:) withObject:ms afterDelay:0.1];
    ms = nil;
  
}
-(void)pushViewController:(NSObject*)sender{
    MessageViewController *ms  = (MessageViewController*)sender;
    [self.navigationController pushViewController:ms animated:YES];
    num=0;
    [_tableView reloadData];
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

#pragma mark - SWTableViewDelegate

- (void)swippableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
            NSLog(@"left button 0 was pressed");
            break;
        case 1:
            NSLog(@"left button 1 was pressed");
            break;
        case 2:
            NSLog(@"left button 2 was pressed");
            break;
        case 3:
            NSLog(@"left btton 3 was pressed");
        default:
            break;
    }
}

- (void)swippableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            
            NSLog(@"More button was pressed");
            NSIndexPath *cellIndexPath = [_tableView indexPathForCell:cell];
            [self createMoreButtonsViewWithIndex:cellIndexPath.row];
            cellIndexPath = nil;
            
            break;
        }
        case 1:
        {
            // 从数据源中删除
            // 从列表中删除
            // 删除数据
            NSIndexPath *cellIndexPath = [_tableView indexPathForCell:cell];
            [DataOperation deleteWithManagedObject:[_datas objectAtIndex:cellIndexPath.row]];
            [_datas removeObjectAtIndex:cellIndexPath.row];
            // 删除单元格
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] withRowAnimation:UITableViewAutomaticDimension];

            break;
        }
        default:
            break;
    }
}

#pragma mark 消息代理
-(void)didReceiveMessage:(XMPPMessage *)xmppMessage WithXMPPStream:(XMPPStream *)xmppStream andEMessage:(EMessages *)em{
    XMPPJID *jid = [xmppMessage from];
    jidUser=jid.user;
    NSLog(@"strstrstr %@",jidUser);
     NSLog(@"strstrstr %@",_datas);
    
    if (_datas.count==0) {
        [self initWithDatas];
        ++num;
        [_tableView reloadData];

}else{
    for (int i=0; i<_datas.count; i++) {
      ETalks *mssage = [_datas objectAtIndex:i];
        if ([jidUser isEqualToString:mssage.userName]) {
            ++num;
            [_tableView reloadData];
            
        }
        [self initWithDatas];
    }
  }
}
-(void)xmppServerConnectState:(int)state WithXMPPStream:(XMPPStream *)xmppStream{
    NSString *stateString = [CommonOperation stateWithType:state];
    NSLog(@"%@",stateString);
    
    if (state==7) {
        [self titleWithName:@"消息"];
    }else if(state==0){
        [self titleWithName: [NSString stringWithFormat:@"消息(未连接)"]];
    }else if(state==1){
        [self titleWithName: [NSString stringWithFormat:@"消息(连接中...)"]];
    }else if (state==5){
        [self presentViewController:[[LoginViewController alloc]init] animated:YES completion:nil];
    
    }
}

-(void)friendWhenSendAddAction:(XMPPJID *)friendJID Subscription:(NSString *)subscription
{

}


@end
