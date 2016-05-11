//
//  LMSheetView.m
//  SimpleExcel
//
//  Created by Chenly on 16/5/11.
//  Copyright © 2016年 Little Meaning. All rights reserved.
//

#import "LMSheetView.h"
#import "LMSLabel.h"

static CGFloat const kLMSheetLineWidth = 1.f;

@interface LMSheetView () <UIScrollViewDelegate>

@end

@implementation LMSheetView
{
    UIView *_topLeftView;
    UIScrollView *_topRightView;
    UIScrollView *_bottomLeftView;
    UIScrollView *_bottomRightView;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    LMSLabel *_selectedLabel;
    
    BOOL _needReCalculateLayout; // 仅在 reload 之后需要重新计算单元格的布局
    NSMutableArray<NSNumber *> *_xOffsetCache;
    NSMutableArray<NSNumber *> *_yOffsetCache;
    NSMutableArray<NSNumber *> *_heightCache;
    NSMutableArray<NSNumber *> *_widthCache;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self p_setupViews];
        [self p_setDefaultStyle];
        [self p_setupGestureRecognizers];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_setupViews];
        [self p_setDefaultStyle];
        [self p_setupGestureRecognizers];
    }
    return self;
}

- (void)p_setupViews {
    _topLeftView = [[UILabel alloc] init];
    _topLeftView.backgroundColor = [UIColor clearColor];
    _topLeftView.clipsToBounds = YES;
    
    _topRightView = [[UIScrollView alloc] init];
    _topRightView.backgroundColor = [UIColor clearColor];
    _topRightView.scrollEnabled = NO;
    
    _bottomLeftView = [[UIScrollView alloc] init];
    _bottomLeftView.backgroundColor = [UIColor clearColor];
    _bottomLeftView.scrollEnabled = NO;
    
    _bottomRightView = [[UIScrollView alloc] init];
    _bottomRightView.backgroundColor = [UIColor clearColor];
    _bottomRightView.bounces = NO;
    _bottomRightView.directionalLockEnabled = YES;
    _bottomRightView.delegate = self;
    
    [self addSubview:_topLeftView];
    [self addSubview:_topRightView];
    [self addSubview:_bottomLeftView];
    [self addSubview:_bottomRightView];
}

- (void)p_setDefaultStyle {
    _headerBackgroundColor = [UIColor colorWithWhite:0.93f alpha:1];
    _headerTextColor = [UIColor grayColor];
    _headerFont = [UIFont systemFontOfSize:15.f];
    _headerTextAlignment = NSTextAlignmentCenter;
    
    _bodyBackgroundColor = [UIColor whiteColor];
    _bodyTextColor = [UIColor blackColor];
    _bodyFont = [UIFont systemFontOfSize:13.f];
    _bodyTextAlignment = NSTextAlignmentLeft;
    
    self.lineColor = [UIColor colorWithWhite:0.85f alpha:1];
}

- (LMSLabel *)p_createLabelForIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSInteger col = indexPath.col;
    
    LMSLabel *label = [[LMSLabel alloc] init];
    label.numberOfLines = 0;
    label.backgroundColor = row * col == 0 ? self.headerBackgroundColor : self.bodyBackgroundColor;
    label.font = row * col == 0 ? self.headerFont : self.bodyFont;
    label.textColor = row * col == 0 ? self.headerTextColor : self.bodyTextColor;
    label.textAlignment = row * col == 0 ? self.headerTextAlignment : self.bodyTextAlignment;
    label.indexPath = [NSIndexPath indexPathForCol:col inRow:row];
    return label;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.dataSource) {
        return;
    }
    
    // 外层容器布局
    CGRect rect = CGRectZero;
    rect.origin.x = 0;
    rect.origin.y = kLMSheetLineWidth;
    rect.size.width = [_widthCache[0] floatValue];
    rect.size.height = [_heightCache[0] floatValue];
    _topLeftView.frame = rect;
    
    rect.origin.x = CGRectGetMaxX(rect) + kLMSheetLineWidth;
    rect.size.width = CGRectGetWidth(self.frame) - CGRectGetMinX(rect);
    _topRightView.frame = rect;
    
    rect = _topLeftView.frame;
    rect.origin.y = CGRectGetMaxY(rect) + kLMSheetLineWidth;
    rect.size.height = CGRectGetHeight(self.frame) - kLMSheetLineWidth - CGRectGetMinY(rect);
    _bottomLeftView.frame = rect;
    
    rect.origin.x = CGRectGetMinX(_topRightView.frame);
    rect.origin.y = CGRectGetMinY(_bottomLeftView.frame);
    rect.size.width = CGRectGetWidth(_topRightView.frame);
    rect.size.height = CGRectGetHeight(_bottomLeftView.frame);
    _bottomRightView.frame = rect;
    [self scrollViewDidScroll:_bottomRightView];
    
    // 内部所有单元格布局
    if (!_needReCalculateLayout) {
        return;
    }
    [self p_calculateLayout];
    [self p_layoutContentLabels];
    
    _needReCalculateLayout = NO;
}

- (void)layoutSubviewsForReloadingRow:(NSInteger)row {
    
    CGFloat newValue = [self.dataSource sheetView:self heightForRow:row];
    CGFloat oldValue = [_heightCache[row] floatValue];
    CGFloat changedHeight = newValue - oldValue;
    if (changedHeight == 0) {
        return;
    }
    
    _heightCache[row] = @(newValue);
    for (NSInteger index = row + 1; index < _yOffsetCache.count; index++) {
        CGFloat yOffset = [_yOffsetCache[index] floatValue] + changedHeight;
        _yOffsetCache[index] = @(yOffset);
    }
    [self p_layoutContentLabels];
}

- (void)p_calculateLayout {
    if (!_xOffsetCache) {
        _xOffsetCache = [NSMutableArray array];
        _yOffsetCache = [NSMutableArray array];
        _heightCache = [NSMutableArray array];
        _widthCache = [NSMutableArray array];
    }
    else {
        [_xOffsetCache removeAllObjects];
        [_yOffsetCache removeAllObjects];
        [_heightCache removeAllObjects];
        [_widthCache removeAllObjects];
    }
    
    NSInteger numberOfRows = [self.dataSource numberOfRowsInSheetView:self];
    NSInteger numberOfCols = [self.dataSource numberOfColsInSheetView:self];
    
    CGFloat yOffset = 0;
    for (NSInteger row = 0; row < numberOfRows; row++) {
        
        CGFloat height;
        if ([self.dataSource respondsToSelector:@selector(sheetView:heightForRow:)]) {
            height = [self.dataSource sheetView:self heightForRow:row];
        }
        else {
            height = row == 0 ? self.headerHeight : self.rowHeight;
        }
        [_heightCache addObject:@(height)];
        
        [_yOffsetCache addObject:@(yOffset)];
        if (row > 0) {
            yOffset += height + kLMSheetLineWidth;
        }
    }
    
    CGFloat xOffset = 0;
    for (NSInteger col = 0; col < numberOfCols; col++) {
        
        CGFloat width;
        if ([self.dataSource respondsToSelector:@selector(sheetView:widthForCol:)]) {
            width = [self.dataSource sheetView:self widthForCol:col];
        }
        else {
            width = col == 0 ? self.leaderWidth : self.colWidth;
        }
        [_widthCache addObject:@(width)];
        
        [_xOffsetCache addObject:@(xOffset)];
        if (col > 0) {
            xOffset += width + kLMSheetLineWidth;
        }
    }
}

- (void)p_layoutContentLabels {
    CGSize contentSize = CGSizeZero;
    contentSize.width = [_xOffsetCache.lastObject floatValue] + [_widthCache.lastObject floatValue];
    contentSize.height = [_yOffsetCache.lastObject floatValue] + [_heightCache.lastObject floatValue];
    _bottomRightView.contentSize = contentSize;
    
    for (UIView *view in @[_topLeftView, _topRightView, _bottomLeftView, _bottomRightView]) {
        for (UIView *subview in view.subviews) {
            if (![subview isMemberOfClass:[LMSLabel class]]) {
                continue;
            }
            [self p_layoutLabel:(LMSLabel *)subview];
        }
    }
}

- (void)p_layoutLabel:(LMSLabel *)label {
    CGRect rect = CGRectZero;
    rect.origin.x = [_xOffsetCache[label.indexPath.col] floatValue];
    rect.origin.y = [_yOffsetCache[label.indexPath.row] floatValue];
    rect.size.width = [_widthCache[label.indexPath.col] floatValue];
    rect.size.height = [_heightCache[label.indexPath.row] floatValue];
    label.frame = rect;
}

#pragma mark - 点击事件

- (void)p_setupGestureRecognizers {
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleTap:)];
    [self addGestureRecognizer:_tapGestureRecognizer];
}

- (void)p_handleTap:(UILongPressGestureRecognizer *)tap {
    if (![self.delegate respondsToSelector:@selector(sheetView:didSelectedCellAtIndexPath:)]) {
        return;
    }
    
    CGPoint point = [tap locationInView:self];
    CGRect rect = [_bottomRightView convertRect:_bottomRightView.bounds toView:self];
    if (!CGRectContainsPoint(rect, point)) {
        return;
    }
    
    LMSLabel *label;
    for (UIView *subview in _bottomRightView.subviews) {
        if ([subview isKindOfClass:[LMSLabel class]]) {
            CGRect rect = [subview convertRect:subview.bounds toView:self];
            if (CGRectContainsPoint(rect, point)) {
                label = (LMSLabel *)subview;
                break;
            }
        }
    }
    if (label) {
        if (_selectedLabel) {
            _selectedLabel.selected = NO;
        }
        _selectedLabel = label;
        _selectedLabel.selected = YES;
        [self.delegate sheetView:self didSelectedCellAtIndexPath:label.indexPath];
    }
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _bottomRightView) {
        _topRightView.contentOffset = CGPointMake(_bottomRightView.contentOffset.x, 0);
        _bottomLeftView.contentOffset = CGPointMake(0, _bottomRightView.contentOffset.y);
    }
}

#pragma mark - public

- (void)setDataSource:(id<LMSheetViewDataSource>)dataSource {
    if (_dataSource == dataSource) {
        return;
    }
    _dataSource = dataSource;
    [self reloadData];
}

- (void)reloadData {
    @autoreleasepool {
        [_topLeftView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_topRightView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_bottomLeftView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_bottomRightView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    if (!self.dataSource) {
        return;
    }
    
    _needReCalculateLayout = YES;
    
    NSInteger numberOfRows = [self.dataSource numberOfRowsInSheetView:self];
    NSInteger numberOfCols = [self.dataSource numberOfColsInSheetView:self];
    for (NSInteger row = 0; row < numberOfRows; row++) {
        for (NSInteger col = 0; col < numberOfCols; col++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForCol:col inRow:row];
            UIView *view;
            if (indexPath.row == 0 && indexPath.col == 0) {
                view = _topLeftView;
            }
            else if (indexPath.row == 0) {
                view = _topRightView;
            }
            else if (indexPath.col == 0) {
                view = _bottomLeftView;
            }
            else {
                view = _bottomRightView;
            }
            LMSLabel *label = [self p_createLabelForIndexPath:indexPath];
            label.text = [self.dataSource sheetView:self contentForCellAtIndexPath:label.indexPath];
            [view addSubview:label];
        }
    }
    [self setNeedsLayout];
}

- (void)reloadCellAtIndexPath:(NSIndexPath *)indexPath {
    for (UIView *subview in _bottomRightView.subviews) {
        if ([subview isMemberOfClass:[LMSLabel class]]) {
            LMSLabel *label = (LMSLabel *)subview;
            if ([label.indexPath isEqual:indexPath]) {
                label.text = [self.dataSource sheetView:self contentForCellAtIndexPath:label.indexPath];
                [self layoutSubviewsForReloadingRow:indexPath.row];
                break;
            }
        }
    }
}

- (NSIndexPath *)selectedIndexPath {
    return _selectedLabel.indexPath;
}

- (void)setLineColor:(UIColor *)lineColor {
    self.backgroundColor = lineColor;
}

- (UIColor *)lineColor {
    return self.backgroundColor;
}

@end

@implementation NSIndexPath (LMSheet)

+ (instancetype)indexPathForCol:(NSInteger)col inRow:(NSInteger)row {
    return [NSIndexPath indexPathForItem:col inSection:row];
}

- (NSInteger)row {
    return self.section;
}

- (NSInteger)col {
    return self.item;
}

@end

@implementation LMSheetView (Scroll)

// 存在问题，水平和竖直同时滚动的时候，只有一个生效。
- (void)scrollToNearestSelectedRowWithScrollDirection:(LMSheetScrollDirection)scrollDirection
                                     atScrollPosition:(LMSheetScrollPosition)scrollPosition
                                             animated:(BOOL)animated {
    if (!_selectedLabel) {
        return;
    }
    
    CGPoint contentOffset = _bottomRightView.contentOffset;
    CGRect visiableRect = _bottomRightView.bounds;
    visiableRect.origin = contentOffset;
    if (CGRectContainsRect(visiableRect, _selectedLabel.frame)) {
        return;
    }
    
    if (scrollDirection == LMSheetScrollDirectionHorizontal) {
        CGFloat width = CGRectGetHeight(_bottomRightView.frame);
        switch (scrollPosition) {
            case LMSheetScrollPositionLeading:
                contentOffset.x = CGRectGetMinX(_selectedLabel.frame);
                if (contentOffset.x + width > _bottomRightView.contentSize.width) {
                    contentOffset.x = _bottomRightView.contentSize.width - width;
                }
                break;
            case LMSheetScrollPositionCenter:
                contentOffset.x = _selectedLabel.center.x - width / 2.f;
                if (contentOffset.x + width > _bottomRightView.contentSize.width) {
                    contentOffset.x = _bottomRightView.contentSize.width - width;
                }
                else if (contentOffset.x < 0) {
                    contentOffset.x = 0;
                }
                break;
            case LMSheetScrollPositionTrailing:
                contentOffset.x = CGRectGetMaxX(_selectedLabel.frame) - width;
                if (contentOffset.x < 0) {
                    contentOffset.x = 0;
                }
                break;
            default:
                break;
        }
    }
    else {
        CGFloat height = CGRectGetHeight(_bottomRightView.frame);
        switch (scrollPosition) {
            case LMSheetScrollPositionLeading:
                contentOffset.y = CGRectGetMinY(_selectedLabel.frame);
                if (contentOffset.y + height > _bottomRightView.contentSize.height) {
                    contentOffset.y = _bottomRightView.contentSize.height - height;
                }
                break;
            case LMSheetScrollPositionCenter:
                contentOffset.y = _selectedLabel.center.y - height / 2.f;
                if (contentOffset.y + height > _bottomRightView.contentSize.height) {
                    contentOffset.y = _bottomRightView.contentSize.height - height;
                }
                else if (contentOffset.y < 0) {
                    contentOffset.y = 0;
                }
                break;
            case LMSheetScrollPositionTrailing:
                contentOffset.y = CGRectGetMaxY(_selectedLabel.frame) - height;
                if (contentOffset.y < 0) {
                    contentOffset.y = 0;
                }
                break;
            default:
                break;
        }
    }    
    [_bottomRightView setContentOffset:contentOffset animated:animated];
    [_topRightView setContentOffset:CGPointMake(contentOffset.x, 0) animated:animated];
    [_bottomLeftView setContentOffset:CGPointMake(0, contentOffset.y) animated:animated];
}

@end