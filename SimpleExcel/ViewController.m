//
//  ViewController.m
//  SimpleExcel
//
//  Created by Chenly on 16/5/11.
//  Copyright © 2016年 Little Meaning. All rights reserved.
//

#import "ViewController.h"
#import "LMSheetView.h"

@interface ViewController () <LMSheetViewDataSource, LMSheetViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet LMSheetView *sheetView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (nonatomic, strong) NSMutableDictionary *userData;
@property (nonatomic, strong) NSMutableDictionary *heightCache;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sheetView.leaderWidth = 40.f;
    self.sheetView.colWidth = 100.f;
    self.sheetView.dataSource = self;
    self.sheetView.delegate = self;
    
    self.textField.enabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.userData = [NSMutableDictionary dictionary];
    self.heightCache = [NSMutableDictionary dictionary];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - <LMSheetViewDataSource>

- (NSInteger)numberOfRowsInSheetView:(LMSheetView *)sheetView {
    return 200;
}

- (NSInteger)numberOfColsInSheetView:(LMSheetView *)sheetView {
    return 27;
}

- (CGFloat)sheetView:(LMSheetView *)sheetView heightForRow:(NSInteger)row {
    
    CGFloat height = [self.heightCache[@(row).stringValue] floatValue];
    return height > 28.f ? height : 28.f;
}

- (NSString *)sheetView:(LMSheetView *)sheetView contentForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if (indexPath.col == 0) {
            return @"";
        }
        else {
            char c = 'A' + (indexPath.col - 1);
            return [NSString stringWithFormat:@"%c", c];
        }
    }
    else {
        if (indexPath.col == 0) {
            return @(indexPath.row).stringValue;
        }
        else {
            NSString *content = self.userData[indexPath];
            if (content) {
                return content;
            }
            return @"";
        }
    }
}

#pragma mark - <LMSheetViewDelegate>

- (void)sheetView:(LMSheetView *)sheetView didSelectedCellAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *content = self.userData[indexPath];
    self.textField.text = content;
    
    char c = 'A' + (indexPath.col - 1);
    NSString *placeholder = [NSString stringWithFormat:@"%c%@", c, @(indexPath.row).stringValue];
    self.textField.placeholder = placeholder;
    
    self.textField.enabled = YES;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    NSIndexPath *indexPath = self.sheetView.selectedIndexPath;
    [self setContent:textField.text forIndexPath:indexPath];
    [self.sheetView reloadCellAtIndexPath:indexPath];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - data

- (CGFloat)heightOfContent:(NSString *)content forIndexPath:(NSIndexPath *)indexPath {
    CGSize boundingSize = CGSizeZero;
    boundingSize.width = (indexPath.col == 0 ? self.sheetView.leaderWidth : self.sheetView.colWidth - 4 * 2); // 4 为文字边距
    boundingSize.height = 0;
    CGRect rect = [content boundingRectWithSize:boundingSize
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName : self.sheetView.bodyFont}
                                        context:NULL];
    CGFloat height = rect.size.height + 4 * 2; // 4 为文字边距
    return height;
}

- (void)setContent:(NSString *)content forIndexPath:(NSIndexPath *)indexPath {
    
    if (content) {
        self.userData[indexPath] = content;
    }
    else {
        [self.userData removeObjectForKey:indexPath];
        return;
    }
    
    CGFloat height = [self heightOfContent:content forIndexPath:indexPath];
    NSNumber *heightNumber = self.heightCache[@(indexPath.row).stringValue];
    if (heightNumber) {
        if (height < heightNumber.floatValue) {
            __block CGFloat maxHeight = 0;
            [self.userData enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *idx, NSString *obj, BOOL * _Nonnull stop) {
                
                if (idx.row == indexPath.row) {
                    CGFloat height = [self heightOfContent:obj forIndexPath:idx];
                    if (height == heightNumber.floatValue) {
                        maxHeight = 0;
                        *stop = YES;
                    }
                    else if (height > maxHeight) {
                        maxHeight = height;
                    }
                }
            }];
            if (maxHeight > 0) {
                self.heightCache[@(indexPath.row).stringValue] = @(maxHeight);
            }
            return;
        }
    }
    self.heightCache[@(indexPath.row).stringValue] = @(height);
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.bottomConstraint.constant = keyboardSize.height;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view layoutSubviews];
        [self.sheetView layoutSubviews];
    } completion:^(BOOL finished) {
        [self.sheetView scrollToNearestSelectedRowWithScrollDirection:LMSheetScrollDirectionVertical
                                                     atScrollPosition:LMSheetScrollPositionTrailing
                                                             animated:YES];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.bottomConstraint.constant = 0;
    [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
        [self.view layoutSubviews];
    } completion:nil];
}

@end
