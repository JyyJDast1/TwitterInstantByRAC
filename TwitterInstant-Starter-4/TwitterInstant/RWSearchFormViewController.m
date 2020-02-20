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

@interface RWSearchFormViewController ()

@property (weak, nonatomic) IBOutlet UITextField *searchText;

@property (strong, nonatomic) RWSearchResultsViewController *resultsViewController;

@end

@implementation RWSearchFormViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.title = @"Twitter Instant";
  
  [self styleTextField:self.searchText];
  
  self.resultsViewController = self.splitViewController.viewControllers[1];
    
    [self checkInputTF];
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

- (void)styleTextField:(UITextField *)textField {
  CALayer *textFieldLayer = textField.layer;
  textFieldLayer.borderColor = [UIColor grayColor].CGColor;
  textFieldLayer.borderWidth = 2.0f;
  textFieldLayer.cornerRadius = 0.0f;
}

@end
