//
//  FriendsViewController.m
//  DFMMessage
//
//  Created by dangfm on 14-5-13.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

#import "FriendsViewController.h"
#import "AppDelegate.h"
#import "MessageViewController.h"
#import "AddFriendsViewController.h"
#import "ContactFriendsViewController.h"
#import "NearUsersViewController.h"
#import "MJRefresh.h"
@interface FriendsViewController()<UITableViewDataSource,UITableViewDelegate,XMPPChatDelegate,MJRefreshBaseViewDelegate>{
    UITableView *_tableView;
    NSMutableArray *_datas;
    NSMutableArray *_groupNames;
    NSMutableDictionary *_groupDatas;
    MJRefreshHeaderView *headerRF;
}

@end

@implementation FriendsViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self initParams];
    [self initViews];
    
     NSNotificationCenter *cnter = [NSNotificationCenter defaultCenter];
    //添加当前类对象为一个观察者，name和object设置为nil，表示接收一切通知
    [cnter addObserver:self selector:@selector(addFriendPOP) name:@"addFriendPOP" object:nil];
    
}
-(void)addFriendPOP{

[headerRF beginRefreshing];
    [self initDatas];

}
-(void)viewWillAppear:(BOOL)animated{
    [XMPPServer sharedServer].chatDelegate = self;

}


-(void)dealloc{
    _tableView = nil;
    _datas = nil;
    _groupDatas = nil;
    _groupNames = nil;
    [headerRF free];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"addFriendPOP" object:nil];
    
}

-(void)initParams{
    [self initDatas];
    
}
-(void)initViews{
    [self initNavigationWithTitle:@"通讯录" IsBack:NO ReturnType:2];
    [self addTables];
    [self addFriendsButton];
}

-(void)addTables{
    CGFloat x = 0;
    CGFloat y = self.header.frame.size.height+self.header.frame.origin.y+5;
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height-y-self.header.frame.size.height;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(x,y,w,h) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = kBackgroundColor;
    _tableView.separatorColor = kCellBottomLineColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
    if (kSystemVersion>=7) {
        
        _tableView.sectionIndexBackgroundColor = KClearColor;
    }
    [self.view addSubview:_tableView];
    
    headerRF = [MJRefreshHeaderView header];
    headerRF.delegate=self;
    headerRF.scrollView =_tableView;
    
}

-(void)addFriendsButton{
    CGFloat w = 70;
    CGFloat h = 30;
    CGFloat x = self.header.frame.size.width-10-w;
    CGFloat y = (self.header.frame.size.height-h)/2;
    UIButton *addFriends = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
    addFriends.backgroundColor = KClearColor;
    [addFriends setTitle:@"添加朋友" forState:UIControlStateNormal];
    [addFriends setTitleColor:UIColorWithHex(0xFFFFFF) forState:UIControlStateNormal];
    [addFriends setTitleColor:UIColorWithHex(0xCCCCCC) forState:UIControlStateHighlighted];
    addFriends.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [addFriends addTarget:self action:@selector(pushToAddFriendsView) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:addFriends];
    addFriends = nil;
}

-(void)initDatas{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *myJID = [XMPPServer sharedServer].xmppStream.myJID.bare;
        _groupNames = [NSMutableArray new];
        _groupDatas = [[NSMutableDictionary alloc] init];
        // 第一个为新朋友和群聊
        [_groupNames addObject:@""];
        NSMutableArray *oneData = [[NSMutableArray alloc] initWithObjects:@"新朋友", nil];
        [_groupDatas setObject:oneData forKey:@""];
        oneData = nil;

        _datas = [[NSMutableArray alloc] initWithArray:[DataOperation select:@"EFriends" Where:[NSString stringWithFormat:@"myJID='%@' and (isDelete=0 or isDelete=null)",myJID] orderBy:@"firstChar" sortType:YES]];
        
        for (EFriends *item in _datas) {
            int i = [_groupNames indexOfObject:item.firstChar];
            if (i>_groupNames.count) {
                if (item.firstChar) {
                    [_groupNames addObject:item.firstChar];
                    NSMutableArray *tempData = [NSMutableArray arrayWithArray:[DataOperation select:@"EFriends" Where:[NSString stringWithFormat:@"myJID='%@' and firstChar='%@'",myJID,item.firstChar] orderBy:nil sortType:NO]];
                    [_groupDatas setObject:tempData forKey:item.firstChar];
                    tempData = nil;
                }
            }
            
        }
        NSLog(@"%@",_groupNames);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_tableView) {
                [_tableView reloadData];
            }
        });
        [headerRF endRefreshing];
    });
}

-(void)pushToAddFriendsView{
    AddFriendsViewController *af = [[AddFriendsViewController alloc] init];
    [self.navigationController pushViewController:af animated:YES];
    af = nil;
}


#pragma mark 表格代理实现
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kCellHeight;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger count = ((NSArray*)[_groupDatas objectForKey:[_groupNames objectAtIndex:section]]).count;
    return count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _groupNames.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [[_groupNames objectAtIndex:section] uppercaseString];
}

#pragma mark 返回索引
-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    return _groupNames;
}
#pragma mark 点击索引
-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{

    NSInteger count = [_groupNames indexOfObject:title];
    if (count<_groupNames.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:count];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else{
    
    }
    
    return count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return 0;
    }
    return 30;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 30)];
    view.backgroundColor = KClearColor;
    CGRect frame = view.frame;
    frame.origin.x = 10;
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.backgroundColor = KClearColor;
    l.text = [[_groupNames objectAtIndex:section] uppercaseString];
    l.textColor = UIColorWithHex(0x666666);
    l.font = [UIFont boldSystemFontOfSize:14];
    [view addSubview:l];
    l = nil;
    return view;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int row = indexPath.row;
    static NSString *cellIdentifier = @"cell";
    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[MyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = kCellBackground;
        CGRect frame = cell.bounds;
        frame.origin.y = kCellHeight;
        frame.size.height = 0.5;
        frame = cell.bounds;
        // imageview
        UIImage *face = [UIImage imageNamed:@"noface"];
        UIImageView *faceView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, face.size.width, face.size.height)];
        faceView.image = face;
        faceView.backgroundColor = KClearColor;
        [cell.contentView addSubview:faceView];
        // title
        CGFloat x = faceView.frame.size.width+faceView.frame.origin.x+10;
        CGFloat w = cell.frame.size.width - x;
        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, kCellHeight)];
        t.font = [UIFont systemFontOfSize:16];
        t.textColor = kFontColor;
        t.backgroundColor = KClearColor;
        [cell.contentView addSubview:t];

        faceView = nil;
        face = nil;
        t = nil;
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeight-0.5, self.view.frame.size.width, 0.5)];
        line.backgroundColor = kCellBottomLineColor;
        [cell addSubview:line];
        line = nil;
    }
    if (indexPath.section<_groupNames.count) {
        NSArray *data = [_groupDatas objectForKey:[_groupNames objectAtIndex:indexPath.section]];
        if (indexPath.section==0) {
            NSArray *views = [cell.contentView subviews];
            // face
            UIImageView *faceView = [views firstObject];
            faceView.image = [UIImage imageNamed:@"noface"];
            faceView = nil;
            // title
            UILabel *t = [views objectAtIndex:1];
            t.text = [data objectAtIndex:row];
            if (row==0) {
             [CommonOperation circleTipWithNumber:[CommonOperation numberWithAddFriendRequest] SuperView:cell.contentView WithPoint:CGPointMake(kScreenBounds.size.width-45, 15)];
            }
            t = nil;
        }else{
            
            if (row<data.count) {
                EFriends *friend = [data objectAtIndex:row];
                NSArray *views = [cell.contentView subviews];
                // face
                UIImageView *faceView = [views firstObject];
                faceView.image = [XMPPHelper xmppUserPhotoForJID:[XMPPJID jidWithString:friend.jid]];;
                faceView = nil;
                // title
                UILabel *t = [views objectAtIndex:1];
                t.text = friend.nickName;
                t = nil;
            }
            data = nil;
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            ContactFriendsViewController *contacts = [[ContactFriendsViewController alloc] init];
            [self.navigationController pushViewController:contacts animated:YES];
            MyTableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
            [CommonOperation circleTipWithNumber:0 SuperView:cell.contentView WithPoint:CGPointMake(kScreenBounds.size.width-45, 15)];
            contacts = nil;
        }

    }else{
        int row = indexPath.row;
        NSArray *data = [_groupDatas objectForKey:[_groupNames objectAtIndex:indexPath.section]];
        EFriends *friend = [data objectAtIndex:row];
        MessageViewController *ms = [[MessageViewController alloc] init];
        XMPPJID *toJID = [XMPPJID jidWithString:friend.jid];
        ms.toJID = toJID;
        toJID = nil;
        [self.navigationController pushViewController:ms animated:YES];
        ms = nil;
        data = nil;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        return NO;
    }
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.view endEditing:YES];
}

#pragma mark 设置删除按钮标题
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}
#pragma mark 点击删除后
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 从数据源中删除
    // 从列表中删除
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *data = (NSMutableArray*)[_groupDatas objectForKey:[_groupNames objectAtIndex:indexPath.section]];
        NSInteger dataCount = data.count;
        // 删除网络数据
        EFriends *friend = [data objectAtIndex:indexPath.row];
        NSLog(@"%@",friend);
        // 此处没有回调
        [[XMPPServer sharedServer].xmppRoster removeUser:[XMPPJID jidWithString:friend.jid]];
        
        // 删除缓存数据
        friend.isDelete = YES;
        [DataOperation save];
        [data removeObjectAtIndex:indexPath.row];
        // 重新设置新值
        [_groupDatas setObject:data forKey:[_groupNames objectAtIndex:indexPath.section]];
        // 删除单元格
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewAutomaticDimension];
        
        NSNotification * notice = [NSNotification notificationWithName:@"removeFriend" object:friend.jid   userInfo:nil];
        [[NSNotificationCenter defaultCenter]postNotification:notice];
        
        // 如果分组没有数据 删除分组和分组数据
        if (dataCount==1) {
            [_datas removeObject:data];
            [_groupDatas removeObjectForKey:[_groupNames objectAtIndex:indexPath.section]];
            [_groupNames removeObjectAtIndex:indexPath.section];
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewAutomaticDimension];
        }
        friend = nil;
        data = nil;
        
    }
}

#pragma mark 消息代理
-(void)didReceiveMessage:(XMPPMessage *)xmppMessage WithXMPPStream:(XMPPStream *)xmppStream andEMessage:(EMessages *)em{
    
    [self initDatas];
}

-(void)friendWhenSendAddAction:(XMPPJID *)friendJID Subscription:(NSString *)subscription{
    
    [_tableView reloadData];
}
#pragma mark- 下拉刷新
-(void)refreshViewBeginRefreshing:(MJRefreshBaseView *)refreshView{

[self initDatas];

}

@end
