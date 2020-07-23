//
//  RWSearchFormViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 02/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWSearchFormViewController.h"
#import "RWSearchResultsViewController.h"
#import <ReactiveObjC.h>
#import "RWTweet.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>
typedef NS_ENUM(NSInteger, RWTwitterInstantError) {
    RWTwitterInstantErrorAccessDenied,
    RWTwitterInstantErrorNoTwitterAccounts,
    RWTwitterInstantErrorInvalidResponse
};

static NSString * const RWTwitterInstantDomain = @"TwitterInstant";

@interface RWSearchFormViewController ()

@property (weak, nonatomic) IBOutlet UITextField *searchText;

@property (strong, nonatomic) RWSearchResultsViewController *resultsViewController;

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccountType *twitterAccountType;


@end

@implementation RWSearchFormViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Twitter Instant";
    
    [self styleTextField:self.searchText];
    
    self.resultsViewController = self.splitViewController.viewControllers[1];
    
    self.accountStore = [[ACAccountStore alloc] init];
    self.twitterAccountType = [self.accountStore
      accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    
    [self checkInputTF ];
    
    @weakify(self);
    
    [[[[[[
//          [self isUserAgreeLoginSig]
          [self requestAccessToTwitterSignal]
         
         //上面信号发送完成时，才往下流动
         then:^RACSignal * _Nonnull{
        //对搜索框进行限制，2字以上；节流0.5s;通过文字进行搜索；展示搜索结果
        @strongify(self);
        return self.searchText.rac_textSignal;
    }]
        filter:^BOOL(NSString *  _Nullable value) {
        return value.length > 2;
    }]
       throttle:0.5]
      //网络请求
      flattenMap:^__kindof RACSignal * _Nullable(NSString *  _Nullable value) {
        @strongify(self);
        return
        [self signalGetInfoWithSearchText:value];
//        [self signalForSearchWithText:value];
    }]
     deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSArray *  _Nullable arr) {
        @strongify(self);
        NSLog(@"arr:%@", arr);
        [self.resultsViewController displayTweets:arr];
    } error:^(NSError * _Nullable error) {
        NSLog(@"err:%@", error);
    } completed:^{
        
    }]
    ;
    
    
    
    [self testCheckThread];
}

- (RACSignal *)requestAccessToTwitterSignal {
  
  // 1 - define an error
  NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain
                                             code:RWTwitterInstantErrorAccessDenied
                                         userInfo:nil];
  
  // 2 - create the signal
  @weakify(self)
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    // 3 - request access to twitter
    @strongify(self)
    [self.accountStore
       requestAccessToAccountsWithType:self.twitterAccountType
         options:nil
      completion:^(BOOL granted, NSError *error) {
          // 4 - handle the response
          if (!granted) {
            [subscriber sendError:accessError];
          } else {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
          }
        }];
    return nil;
  }];
}

- (RACSignal *)signalGetInfoWithSearchText:(NSString *)text{
    
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //模拟网络请求
        [NSThread sleepForTimeInterval:2];
        
        NSError *lErr = [NSError errorWithDomain:@"getInfoErr" code:400 userInfo:nil];
        BOOL isSuc = YES;
        if (isSuc) {
            NSMutableArray *lArrM = [NSMutableArray array];
            for (int i = 0; i < 30; ++i) {
               int lNum0 = arc4random_uniform(100);
               RWTweet *lM = [RWTweet tweetWithStatus:@{@"text" : @"content...",
                                                        @"user" : @{@"screen_name" : [@"name" stringByAppendingFormat:@"%d",lNum0],
                                                                    @"profile_image_url" : @"https://c-ssl.duitang.com/uploads/item/201701/05/20170105150148_rZtyj.jpeg"
                                                        }
               }];
              [lArrM addObject:lM];
            }
           
            [subscriber sendNext:lArrM];
            [subscriber sendCompleted];
        }else{
            [subscriber sendError:lErr];
        }
        return nil;
    }];
    
}

- (RACSignal *)isUserAgreeLoginSig{
    NSError *lErr = [NSError errorWithDomain:@"not agree login" code:400 userInfo:nil];
    
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        
        //弹窗让用户选择
        UIAlertController *lAlertC = [UIAlertController alertControllerWithTitle:@"是否同意登陆" message:@"请选择" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *lActYes = [UIAlertAction actionWithTitle:@"YES" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        }];
        [lAlertC addAction:lActYes];
        
        UIAlertAction *lActNO = [UIAlertAction actionWithTitle:@"NO" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
            [subscriber sendError:lErr];
        }];
        [lAlertC addAction:lActNO];
        
        //必须切到主线程，否则ipad上present可能弹出来
        dispatch_async(dispatch_get_main_queue(), ^ {
           [self presentViewController:lAlertC animated:YES completion:^{
            }];
        });
        
        
        return nil;
    }];
}

- (void)testCheckThread{
    //线程切换：记关键字 on
    RACScheduler *lBackThread = [RACScheduler schedulerWithPriority:(RACSchedulerPriorityBackground)];
    [[[[RACSignal
        createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"thread0:%@", [NSThread currentThread]);
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }]
       subscribeOn:lBackThread]
      deliverOnMainThread]
     subscribeNext:^(id  _Nullable x) {
        NSLog(@"subscribe thread:%@", [NSThread currentThread]);
    }];
}

- (void)checkInputTF{
    RACSignal *lTFColorSig =
    [self.searchText.rac_textSignal
     map:^id _Nullable(NSString * _Nullable value) {
        return [self isValidSearchText:value] ? [UIColor whiteColor] : [UIColor yellowColor];
    }];
    RAC(self.searchText, backgroundColor) = lTFColorSig;
    
    //快速查看宏定义展开后样式的方法：select Product -> Perform Action -> Preprocess “RWSearchForViewController”. This will preprocess the view controller, expand all the macros and allow you to see the final output.
    //    @weakify(self);
    //    [lTFColorSig subscribeNext:^(id  _Nullable x) {
    //        @strongify(self);
    //    }];
}

- (BOOL)isValidSearchText:(NSString *)text {
    return text.length > 2;
}

- (SLRequest *)requestforTwitterSearchWithText:(NSString *)text {
  NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
  NSDictionary *params = @{@"q" : text};
  
  SLRequest *request =  [SLRequest requestForServiceType:SLServiceTypeTwitter
                                           requestMethod:SLRequestMethodGET
                                                     URL:url
                                              parameters:params];
  return request;
}

- (RACSignal *)signalForSearchWithText:(NSString *)text {

  // 1 - define the errors
  NSError *noAccountsError = [NSError errorWithDomain:RWTwitterInstantDomain
                                                 code:RWTwitterInstantErrorNoTwitterAccounts
                                             userInfo:nil];
  
  NSError *invalidResponseError = [NSError errorWithDomain:RWTwitterInstantDomain
                                                      code:RWTwitterInstantErrorInvalidResponse
                                                  userInfo:nil];
  
  // 2 - create the signal block
  @weakify(self)
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    
    // 3 - create the request
    SLRequest *request = [self requestforTwitterSearchWithText:text];
    
    // 4 - supply a twitter account
    NSArray *twitterAccounts = [self.accountStore
      accountsWithAccountType:self.twitterAccountType];
    if (twitterAccounts.count == 0) {
      [subscriber sendError:noAccountsError];
    } else {
      [request setAccount:[twitterAccounts lastObject]];
      
      // 5 - perform the request
      [request performRequestWithHandler: ^(NSData *responseData,
                                          NSHTTPURLResponse *urlResponse, NSError *error) {
        if (urlResponse.statusCode == 200) {
          
          // 6 - on success, parse the response
          NSDictionary *timelineData =
             [NSJSONSerialization JSONObjectWithData:responseData
                                             options:NSJSONReadingAllowFragments
                                               error:nil];
          [subscriber sendNext:timelineData];
          [subscriber sendCompleted];
        }
        else {
          // 7 - send an error on failure
          [subscriber sendError:invalidResponseError];
        }
      }];
    }
    
    return nil;
  }];
}


- (void)styleTextField:(UITextField *)textField {
    CALayer *textFieldLayer = textField.layer;
    textFieldLayer.borderColor = [UIColor grayColor].CGColor;
    textFieldLayer.borderWidth = 2.0f;
    textFieldLayer.cornerRadius = 0.0f;
}

@end
