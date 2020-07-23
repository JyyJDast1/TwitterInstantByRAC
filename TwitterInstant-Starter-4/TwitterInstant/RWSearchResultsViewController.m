//
//  RWSearchResultsViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 03/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import <ReactiveObjC.h>
#import "RWSearchResultsViewController.h"
#import "RWTableViewCell.h"
#import "RWTweet.h"

@interface RWSearchResultsViewController ()<NSCacheDelegate>

@property (nonatomic, copy) NSArray *tweets;

@property (nonatomic, strong) NSCache *gCache4Img; //立刻懒加载分配空间
@end

@implementation RWSearchResultsViewController {

}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tweets = [NSArray array];
  
}

- (void)displayTweets:(NSArray *)tweets {
  self.tweets = tweets;
  [self.tableView reloadData];
}

#pragma mark -  delegate 4 nscache
- (void)cache:(NSCache *)cache willEvictObject:(id)obj{
    NSLog(@"cache willEvictObject:%@",obj);
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  RWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  
  RWTweet *tweet = self.tweets[indexPath.row];
  cell.twitterStatusText.text = tweet.status;
  cell.twitterUsernameText.text = [NSString stringWithFormat:@"@%@",tweet.username];
    
    cell.twitterAvatarView.image = [UIImage imageNamed:@"holder"];
    
    if (tweet.profileImageUrl.length > 0) {
        UIImage *lImg = [self.gCache4Img objectForKey:tweet.profileImageUrl];
        if (nil != lImg) {
            cell.twitterAvatarView.image = lImg;
        }else{
            [[[tweet getAvatarImageSignal]
                deliverOn:[RACScheduler mainThreadScheduler]]
               subscribeNext:^(UIImage *  _Nullable x) {
                  NSLog(@"img set,%@",[NSThread currentThread]);
                  
                  //注意：不要错误赋值到 imageview上了！！！
                  cell.twitterAvatarView.image = x;
                  
                 //cache
                [self.gCache4Img setObject:x forKey:tweet.profileImageUrl];
              }
               error:^(NSError * _Nullable error) {
                  NSLog(@"load img err:%@",error);
              }];
        }
    }
   
  return cell;
}

#pragma mark -  getter
- (NSCache *)gCache4Img{
    if (nil == _gCache4Img) {
        _gCache4Img = [[NSCache alloc] init];
        _gCache4Img.countLimit = 10;
        _gCache4Img.totalCostLimit = 5 * 1024 * 1024;//5M
        _gCache4Img.delegate = self;
    }
    return _gCache4Img;
}

@end
