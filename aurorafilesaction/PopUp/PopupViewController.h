//
//  PopupViewController.h
//
//  Created by Cheshire on 26.10.15.
//

#import <UIKit/UIKit.h>

typedef void (^AgreeBlock)(void);
typedef void (^DisagreeBlock)(void);

typedef NS_ENUM(NSInteger, kPopUpStyle){
    kPopUpStyleAgree = 0,
    kPopUpStyleOK,
    kPopUpStyleNoBtns
};

@interface PopupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *disagreeButton;
@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@property (weak, nonatomic) IBOutlet UITextView *mainText;
@property (weak, nonatomic) IBOutlet UILabel *headerText;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UILabel *currentUploadedBytes;
@property (weak, nonatomic) IBOutlet UILabel *neededToUploadBytes;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@property (assign, readonly, nonatomic) BOOL isShown;
//init
-(id)initPopUpWithoutButonsWithTitle:(NSString *)title message:(NSString *)message parrentView:(id)parent;
-(id)initPopUpWithOneButtonWithTitle:(NSString *)title message:(NSString *)message agreeText:(NSString *)agree  agreeBlock:(AgreeBlock)agreeBlock parrentView:(id)parent;
-(id)initPopUpWithTitle:(NSString *)title message:(NSString *)message agreeText:(NSString *)agree disagreeText:(NSString *)disagree agreeBlock:(AgreeBlock)agreeBlock disagreeBlock:(DisagreeBlock)disagreeBlock parrentView:(id)parent;
-(id)initProgressAllertWithTitle:(NSString *)title message:(NSString *)message fileName:(NSString *)fileName fileSize:(NSString *)size disagreeText:(NSString *)disagree disagreeBlock:(DisagreeBlock)disagreeBlock parrentView:(id)parent;

//show & close
-(void)showPopup;
-(void)closeView;
-(void)closeViewWithComplition:(void (^ __nullable)(void)) handler;

//upload progress
-(void)setProgressWihtCurrentBytes:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;
-(void)setCurrentFileName:(NSString  * _Nullable )fileName;

@end
