//
//  HNPostControllerHandling.m
//  HackerNewsReader
//
//  Created by Ryan Nystrom on 6/1/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import <SafariServices/SafariServices.h>

#import "HNPostControllerHandling.h"
#import "UIColor+HackerNews.h"

#import "HNPost.h"

#import "HNCommentViewController.h"
#import "NSURL+HackerNews.h"

UIViewController *viewControllerForPost(HNPost *post) {
    UIViewController *controller;
    if ([post.URL isHackerNewsURL]) {
        NSUInteger postID = [[post.URL hn_valueForQueryParameter:@"id"] integerValue];
        controller = [[HNCommentViewController alloc] initWithPostID:postID];
    } else {
        controller = [[SFSafariViewController alloc] initWithURL:post.URL];
        ((SFSafariViewController*)controller).preferredBarTintColor = [UIColor hn_brandColor];
    }
    controller.hidesBottomBarWhenPushed = YES;
    return controller;
}

UIViewController *viewControllerForURL(NSURL *url) {
    UIViewController *controller;
    if ([url isHackerNewsURL]) {
        NSUInteger postID = [[url hn_valueForQueryParameter:@"id"] integerValue];
        controller = [[HNCommentViewController alloc] initWithPostID:postID];
    } else {
        controller = [[SFSafariViewController alloc] initWithURL:url];
        ((SFSafariViewController*)controller).preferredBarTintColor = [UIColor hn_brandColor];
    }
    controller.hidesBottomBarWhenPushed = YES;
    return controller;
}
