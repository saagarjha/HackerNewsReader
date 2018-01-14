//
//  UINavigationBar+HackerNews.m
//  HackerNewsUIKit
//
//  Created by Ryan Nystrom on 4/8/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import "UINavigationBar+HackerNews.h"

#import "HNNavigationController.h"
#import "UIColor+HackerNews.h"
#import "UIFont+HackerNews.h"

@implementation UINavigationBar (HackerNews)

+ (void)hn_enableAppearance {
    UINavigationBar *appearance = [self appearanceWhenContainedInInstancesOfClasses:@[HNNavigationController.class]];
    [appearance setTitleTextAttributes:@{
                                         NSForegroundColorAttributeName: [UIColor hn_navigationTextColor],
                                         NSFontAttributeName: [UIFont hn_navigationFont]
                                         }];
    if (@available(iOS 11.0, *)) {
        [appearance setLargeTitleTextAttributes:@{
                                                  NSForegroundColorAttributeName: [UIColor hn_navigationTextColor],
                                                  NSFontAttributeName: [UIFont hn_largeNavigationFont]
                                                  }];
    }
    [appearance setTintColor:[UIColor hn_navigationTintColor]];
    [appearance setBarTintColor:[UIColor hn_brandColor]];
}

@end
