//
//  RWTweet.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 05/01/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

#import "RWTweet.h"

@implementation RWTweet

+ (instancetype)tweetWithStatus:(NSDictionary *)status {
  RWTweet *tweet = [RWTweet new];
  tweet.status = status[@"text"];
  
  NSDictionary *user = status[@"user"];
  tweet.profileImageUrl = user[@"profile_image_url"];
  tweet.username = user[@"screen_name"];
  return tweet;
}

- (RACSignal *)getAvatarImageSignal{
    if (0 == self.profileImageUrl.length) {
        return nil;
    }
    
    RACScheduler *backThread = [RACScheduler schedulerWithPriority:(RACSchedulerPriorityBackground)];
    
    return [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        
        NSData *lData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.profileImageUrl]];
        UIImage *lImg = [UIImage imageWithData:lData];
        
        NSError *lErr = [NSError errorWithDomain:@"load avater err" code:400 userInfo:nil];
        if (nil == lImg) {
            [subscriber sendError:lErr];
        }else{
            [subscriber sendNext:lImg];
            [subscriber sendCompleted];
        }
        
        return nil;
    }]
             replayLazily]
            subscribeOn:backThread];
}

@end
