//
//  LMSheetView.h
//  SimpleExcel
//
//  Created by Chenly on 16/5/11.
//  Copyright © 2016年 Little Meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMSheetView;

@protocol LMSheetViewDataSource <NSObject>

@required
- (NSInteger)numberOfRowsInSheetView:(LMSheetView *)sheetView;
- (NSInteger)numberOfColsInSheetView:(LMSheetView *)sheetView;

- (NSString *)sheetView:(LMSheetView *)sheetView contentForCellAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (CGFloat)sheetView:(LMSheetView *)sheetView heightForRow:(NSInteger)row;
- (CGFloat)sheetView:(LMSheetView *)sheetView widthForCol:(NSInteger)col;

@end

@protocol LMSheetViewDelegate <NSObject>

@optional
- (void)sheetView:(LMSheetView *)sheetView didSelectedCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface LMSheetView : UIView <UITableViewDelegate>

@property (nonatomic, weak) id<LMSheetViewDataSource> dataSource;
@property (nonatomic, weak) id<LMSheetViewDelegate> delegate;

@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat leaderWidth;
@property (nonatomic, assign) CGFloat colWidth;

@property (nonatomic, strong) UIColor *headerBackgroundColor;
@property (nonatomic, strong) UIColor *bodyBackgroundColor;
@property (nonatomic, strong) UIColor *headerTextColor;
@property (nonatomic, strong) UIColor *bodyTextColor;
@property (nonatomic, assign) NSTextAlignment headerTextAlignment;
@property (nonatomic, assign) NSTextAlignment bodyTextAlignment;
@property (nonatomic, strong) UIColor *lineColor;

@property (nonatomic, strong) UIFont *headerFont;
@property (nonatomic, strong) UIFont *bodyFont;

@property (nonatomic, readonly) NSIndexPath *selectedIndexPath;

- (void)reloadData;
- (void)reloadCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface NSIndexPath (LMSheet)

+ (instancetype)indexPathForCol:(NSInteger)col inRow:(NSInteger)row;

@property (nonatomic, readonly) NSInteger row;
@property (nonatomic, readonly) NSInteger col;

@end

typedef NS_ENUM(NSInteger, LMSheetScrollPosition) {
    LMSheetScrollPositionLeading,
    LMSheetScrollPositionCenter,
    LMSheetScrollPositionTrailing
};

typedef NS_ENUM(NSInteger, LMSheetScrollDirection) {
    LMSheetScrollDirectionHorizontal,
    LMSheetScrollDirectionVertical
};

@interface LMSheetView (Scroll)

- (void)scrollToNearestSelectedRowWithScrollDirection:(LMSheetScrollDirection)scrollDirection
                                     atScrollPosition:(LMSheetScrollPosition)scrollPosition
                                             animated:(BOOL)animated;

@end
