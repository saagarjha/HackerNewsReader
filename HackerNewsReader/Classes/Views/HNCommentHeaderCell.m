//
//  HNCommentHeaderCell.m
//  HackerNewsReader
//
//  Created by Ryan Nystrom on 4/12/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import "HNCommentHeaderCell.h"

#import "UIColor+HackerNews.h"
#import "UIFont+HackerNews.h"

static CGFloat const kHNCommentHeaderPadding = 15.0;

@interface HNCommentHeaderCell ()

@property (nonatomic, strong, readonly) UILabel *collapsedLabel;
@property (nonatomic, strong) CALayer *borderLayer;

@end

@implementation HNCommentHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont hn_subtitleFont];
        _titleLabel.textColor = [UIColor hn_subtitleTextColor];
        [self.contentView addSubview:_titleLabel];

        _collapsedLabel = [[UILabel alloc] init];
        _collapsedLabel.textColor = [UIColor hn_subtitleTextColor];
        _collapsedLabel.font = [UIFont hn_subtitleFont];
        _collapsedLabel.text = @"\u2212";
        [self.contentView addSubview:_collapsedLabel];

        _borderLayer = [CALayer layer];
        _borderLayer.backgroundColor = [UIColor colorWithRed:0.783922 green:0.780392 blue:0.8 alpha:1.0].CGColor;
        [self.layer addSublayer:_borderLayer];

        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor hn_overlayHighlightColor];
        self.selectedBackgroundView = backgroundView;
    }
    return self;
}


#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.contentView.bounds;
    CGFloat left = self.indentationWidth * self.indentationLevel + kHNCommentHeaderPadding;
    CGRect usernameFrame = CGRectInset(bounds, left, 0.0);
    self.titleLabel.frame = CGRectIntegral(usernameFrame);

    [self.collapsedLabel sizeToFit];
    CGSize collapsedSize = self.collapsedLabel.bounds.size;
    CGRect frame = CGRectMake(CGRectGetWidth(bounds) - kHNCommentHeaderPadding - collapsedSize.width, CGRectGetMidY(bounds) - collapsedSize.height / 2, collapsedSize.width, collapsedSize.height);
    self.collapsedLabel.frame = CGRectIntegral(frame);

    CGFloat separatorHeight = 1.0 / [UIScreen mainScreen].scale;
    self.borderLayer.frame = CGRectMake(left, CGRectGetHeight(self.bounds) - separatorHeight, CGRectGetWidth(self.bounds), separatorHeight);
}


#pragma mark - Public API

- (void)setCollapsed:(BOOL)collapsed {
    _collapsed = collapsed;
    self.collapsedLabel.text = collapsed ? @"+" : @"\u2212";
}


#pragma mark - Accessibility

- (NSString *)accessibilityHint {
    return NSLocalizedString(@"Select to collapse thread", @"Hint that selecting the cell collapses the comment thread");
}

@end
