//
//  UISearchBar+HackerNews.m
//  HackerNewsReader
//
//  Created by Saagar Jha on 1/13/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

#import "UISearchBar+HackerNews.h"

#import "HNNavigationController.h"

@implementation UISearchBar (HackerNews)

+ (void)hn_enableAppearance {
    if (@available(iOS 11, *)) {
        UISearchBar *appearance = [UISearchBar appearanceWhenContainedInInstancesOfClasses:@[HNNavigationController.class]];
        appearance.tintColor = [UIColor whiteColor];
    }
}

@end
