//
//  LMSLabel.m
//  SimpleExcel
//
//  Created by Chenly on 16/5/11.
//  Copyright © 2016年 Little Meaning. All rights reserved.
//

#import "LMSLabel.h"

@implementation LMSLabel

- (void)setSelected:(BOOL)selected {
    if (_selected == selected) {
        return;
    }
    _selected = selected;
    if (selected) {
        self.layer.masksToBounds = YES;
        self.layer.borderColor = [UIColor colorWithRed:43/255.f green:132/255.f blue:210/255.f alpha:1].CGColor;
        self.layer.borderWidth = 1.f;
    }
    else {
        self.layer.masksToBounds = NO;
        self.layer.borderWidth = 0;
    }
    [self setNeedsDisplay];
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:CGRectInset(rect, 4, 4)];
}

@end
