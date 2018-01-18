//
//  UIToolbar+HackerNews.m
//  HackerNewsUIKit
//
//  Created by Ryan Nystrom on 4/8/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import "UIToolbar+HackerNews.h"

#import "HNNavigationController.h"
#import "UIColor+HackerNews.h"

@implementation UIToolbar (HackerNews)

+ (void)hn_enableAppearance {
    UIToolbar *appearance = [self appearanceWhenContainedInInstancesOfClasses:@[HNNavigationController.class]];
    [appearance setTintColor:[UIColor hn_brandColor]];
}

@end
