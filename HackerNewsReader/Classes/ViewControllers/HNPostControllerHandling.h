//
//  HNPostControllerHandling.h
//  HackerNewsReader
//
//  Created by Ryan Nystrom on 6/1/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class HNPost;

extern __kindof UIViewController *viewControllerForPost(HNPost *post);

extern __kindof UIViewController *viewControllerForURL(NSURL *url);

NS_ASSUME_NONNULL_END
