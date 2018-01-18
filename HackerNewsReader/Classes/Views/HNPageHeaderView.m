//
//  HNPageHeaderView.m
//  HackerNewsReader
//
//  Created by Ryan Nystrom on 5/7/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import "HNPageHeaderView.h"

#import "UIColor+HackerNews.h"
#import "UIFont+HackerNews.h"

static UIEdgeInsets const kHNPageHeaderInsets = (UIEdgeInsets){8.0, 15.0, 8.0, 15.0};
static CGFloat const kHNPageHeaderLabelSpacing = 5.0;

@interface HNPageHeaderView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation HNPageHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont hn_pageTitleFont];
        _titleLabel.textColor = [UIColor hn_titleTextColor];
        _titleLabel.backgroundColor = self.backgroundColor;
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont hn_subtitleFont];
        _subtitleLabel.textColor = [UIColor hn_subtitleTextColor];
        _subtitleLabel.backgroundColor = self.backgroundColor;
        [self addSubview:_subtitleLabel];

        _textLabel = [[UILabel alloc] init];
        _textLabel.font = [UIFont hn_titleFont];
        _textLabel.textColor = [UIColor hn_titleTextColor];
        _textLabel.numberOfLines = 0;
        _textLabel.backgroundColor = self.backgroundColor;
        [self addSubview:_textLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:tap];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
        [self addGestureRecognizer:longPress];
    }
    return self;
}


#pragma mark - Public API

- (void)setTitleText:(NSString *)titleText {
    self.titleLabel.text = titleText;
}

- (void)setSubtitleText:(NSString *)subtitleText {
    self.subtitleLabel.text = subtitleText;
}

- (void)setTextAttributedString:(NSAttributedString *)textAttributedString {
    self.textLabel.attributedText = textAttributedString;
}


#pragma mark - Layout

- (CGSize)sizeThatFits:(CGSize)size {
    CGRect inset = UIEdgeInsetsInsetRect((CGRect){CGPointZero, size}, kHNPageHeaderInsets);
    CGSize titleSize = [self.titleLabel sizeThatFits:inset.size];
    CGSize subtitleSize = [self.subtitleLabel sizeThatFits:inset.size];
    CGFloat textHeight = 0.0;
    if (self.textLabel.text.length) {
        CGSize textSize = [self.textLabel sizeThatFits:inset.size];
        textHeight += kHNPageHeaderLabelSpacing + textSize.height;
    }
    return CGSizeMake(size.width, kHNPageHeaderInsets.top + titleSize.height + kHNPageHeaderLabelSpacing + subtitleSize.height + textHeight + kHNPageHeaderInsets.bottom);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets safeInsets = kHNPageHeaderInsets;
    if (@available(iOS 11.0, *)) {
        safeInsets.left = fmax(safeInsets.left, self.safeAreaInsets.left);
        safeInsets.right = fmax(safeInsets.right, self.safeAreaInsets.right);
    }
    CGRect inset = UIEdgeInsetsInsetRect(self.bounds, kHNPageHeaderInsets);
    CGSize titleSize = [self.titleLabel sizeThatFits:inset.size];
    self.titleLabel.frame = CGRectMake(safeInsets.left, safeInsets.top, titleSize.width, titleSize.height);

    CGSize subtitleSize = [self.subtitleLabel sizeThatFits:inset.size];
    self.subtitleLabel.frame = CGRectMake(safeInsets.left, CGRectGetMaxY(self.titleLabel.frame) + kHNPageHeaderLabelSpacing, subtitleSize.width, subtitleSize.height);

    if (self.textLabel.text) {
        CGSize textSize = [self.textLabel sizeThatFits:inset.size];
        self.textLabel.frame = CGRectMake(safeInsets.left, CGRectGetMaxY(self.subtitleLabel.frame) + kHNPageHeaderLabelSpacing, textSize.width, textSize.height);
    }
}


#pragma mark - Gestures

- (void)onTap:(UITapGestureRecognizer *)recognizer {
    CGPoint textLabelPoint = [recognizer locationInView:self.textLabel];
    CGPoint point = [recognizer locationInView:self];
    if (CGRectContainsPoint(self.textLabel.frame, point) &&
        [self.delegate respondsToSelector:@selector(pageHeader:didTapText:characterAtIndex:)]) {
        // http://stackoverflow.com/a/26806991/940936
        // init text storage
        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.textLabel.attributedText];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [textStorage addLayoutManager:layoutManager];

        // init text container
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.textLabel.frame.size.width, self.textLabel.frame.size.height+100) ];
        textContainer.lineFragmentPadding = 0;
        textContainer.maximumNumberOfLines = self.textLabel.numberOfLines;
        textContainer.lineBreakMode = self.textLabel.lineBreakMode;

        [layoutManager addTextContainer:textContainer];

        NSUInteger characterIndex = [layoutManager characterIndexForPoint:textLabelPoint
                                                          inTextContainer:textContainer
                                 fractionOfDistanceBetweenInsertionPoints:NULL];
        [self.delegate pageHeader:self didTapText:self.textLabel.attributedText characterAtIndex:characterIndex];
    } else if (CGRectContainsPoint(self.titleLabel.frame, point) &&
               [self.delegate respondsToSelector:@selector(pageHeaderDidTapTitle:)]) {
        [self.delegate pageHeaderDidTapTitle:self];
    }
}

- (void)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan &&
        [self.delegate respondsToSelector:@selector(pageHeader:didLongPressAtPoint:)]) {
        CGPoint point = [recognizer locationInView:self];
        [self.delegate pageHeader:self didLongPressAtPoint:point];
    }
}

@end
