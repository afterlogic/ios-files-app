//
//  PopupViewController.m
//
//  Created by Cheshire on 26.10.15.
//

#import "PopupViewController.h"


const CGFloat defaultDelay  = 3.0f;

@interface PopupViewController ()
{
    AgreeBlock _agree;
    DisagreeBlock _disagree;
    UIViewController *parentView;
}
@property (weak, nonatomic) IBOutlet UIView *uploadView;

@property (weak, nonatomic) IBOutlet UILabel *filenameLabel;




@end

@implementation PopupViewController

-(id)initPopUpWithoutButonsWithTitle:(NSString *)title message:(NSString *)message parrentView:(id)parent{
    self.view = [[[NSBundle mainBundle] loadNibNamed:@"PopupViewController" owner:self options:nil] firstObject];
    if (self != nil) {
        [self.uploadView setHidden:YES];
        [self.disagreeButton setEnabled:NO];
        [self.disagreeButton setAlpha:0.0f];
        [self.agreeButton setEnabled:NO];
        [self.agreeButton setAlpha:0.0f];
        [self setMainTitle:message];
        [self setHeaderTitle:title];
        if ([parent isKindOfClass:[UIViewController class]]) {
            parentView = (UIViewController *)parent;
        }
    }
    return self;

}

-(id)initPopUpWithOneButtonWithTitle:(NSString *)title message:(NSString *)message agreeText:(NSString *)agree  agreeBlock:(AgreeBlock)agreeBlock parrentView:(id)parent
{
    self.view = [[[NSBundle mainBundle] loadNibNamed:@"PopupViewController" owner:self options:nil] firstObject];
    if (self != nil) {
        [self.uploadView setHidden:YES];
        [self setAgreeButtonText:agree];
        [self.disagreeButton setEnabled:NO];
        [self.disagreeButton setAlpha:0.0f];
        [self setMainTitle:message];
        [self setHeaderTitle:title];
        [self.agreeButton addTarget:self action:@selector(onAgree) forControlEvents:UIControlEventTouchUpInside];
        _agree = agreeBlock;
        if ([parent isKindOfClass:[UIViewController class]]) {
            parentView = (UIViewController *)parent;
        }
    }
    return self;
}

-(id)initPopUpWithTitle:(NSString *)title message:(NSString *)message agreeText:(NSString *)agree disagreeText:(NSString *)disagree agreeBlock:(AgreeBlock)agreeBlock disagreeBlock:(DisagreeBlock)disagreeBlock parrentView:(id)parent
{
    self.view = [[[NSBundle mainBundle] loadNibNamed:@"PopupViewController" owner:self options:nil] firstObject];
    if (self != nil) {
        [self.uploadView setHidden:YES];
        [self setAgreeButtonText:agree];
        [self setDisagreeButtonText:disagree];
        [self setMainTitle:message];
        [self setHeaderTitle:title];
        [self.agreeButton addTarget:self action:@selector(onAgree) forControlEvents:UIControlEventTouchUpInside];
        [self.disagreeButton addTarget:self action:@selector(onDisagree) forControlEvents:UIControlEventTouchUpInside];
        _agree = agreeBlock;
        _disagree = disagreeBlock;
        if ([parent isKindOfClass:[UIViewController class]]) {
            parentView = (UIViewController *)parent;
        }
    }
    return self;
}

-(id)initProgressAllertWithTitle:(NSString *)title message:(NSString *)message fileName:(NSString *)fileName fileSize:(NSString *)size disagreeText:(NSString *)disagree disagreeBlock:(DisagreeBlock)disagreeBlock parrentView:(id)parent{
    self.view = [[[NSBundle mainBundle] loadNibNamed:@"PopupViewController" owner:self options:nil] firstObject];
    if (self != nil) {
        [self.uploadView setHidden:NO];
        [self.agreeButton setHidden:YES];
        [self.agreeButton setEnabled:NO];
        [self setDisagreeButtonText:disagree];
        [self.disagreeButton addTarget:self action:@selector(onDisagree) forControlEvents:UIControlEventTouchUpInside];
        _disagree = disagreeBlock;
        [self setMainTitle:message];
        [self setHeaderTitle:title];
        self.filenameLabel.text = fileName;
        self.currentUploadedBytes.text = @"currentBytes";
        self.neededToUploadBytes.text = size;
        if ([parent isKindOfClass:[UIViewController class]]) {
            parentView = (UIViewController *)parent;
        }
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.view setFrame: [UIScreen mainScreen].bounds];
    self.contentView.layer.cornerRadius = 5.0f;
    self.agreeButton.layer.borderWidth = 1.0f;
    self.agreeButton.layer.borderColor =[UIColor whiteColor].CGColor;
    self.disagreeButton.layer.borderWidth = 1.0f;
    self.disagreeButton.layer.borderColor =[UIColor whiteColor].CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)setAgreeButtonText:(NSString *)text{
//    [self.agreeButton.titleLabel setText:text];
    [self.agreeButton setTitle:text forState:UIControlStateNormal];
    [self.agreeButton setTitle:text forState:UIControlStateHighlighted];
}

-(void)setDisagreeButtonText:(NSString *)text{
//    [self.disagreeButton.titleLabel setText:text];
    [self.disagreeButton setTitle:text forState:UIControlStateNormal];
    [self.disagreeButton setTitle:text forState:UIControlStateHighlighted];
}

-(void)setMainTitle:(NSString *)title{
    [self.mainText setText:title];
    [self.mainText setTextColor:[UIColor whiteColor]];
}

-(void)setHeaderTitle:(NSString *)headerText{
    [self.headerText setText:headerText];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)onAgree{
    if (_agree) {
        _agree();
    }else{
        [self closeView];
    };
}

-(void)onDisagree{
    if(_disagree){
        _disagree();
    }else{
        [self closeView];
    }
}
- (IBAction)onExitTouch:(id)sender {
    [self closeView];
}

-(void)setProgressWihtCurrentBytes:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    self.currentUploadedBytes.text = [self transformedValue:[NSNumber numberWithLongLong:totalBytesSent]];
    self.neededToUploadBytes.text = [self transformedValue:[NSNumber numberWithLongLong:totalBytesExpectedToSend]];
    float progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
    [self.progressBar setProgress:progress animated:YES];
//    [self.view setNeedsLayout];
}


-(void)showPopup{
    if (parentView) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [parentView.navigationController presentViewController:self animated:YES completion:nil];
    }
}

-(void)closeView{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)closeViewWithComplition:(void (^ __nullable)(void)) handler{
    [self dismissViewControllerAnimated:YES completion:^{
        handler();
    }];
}

-(void)closeViewWithDelay:(CGFloat) delay{
    CGFloat closeDelay = delay ? delay : defaultDelay;
    [self performSelector:@selector(closeView) withObject:nil afterDelay:closeDelay];
}

-(void)closeViewWithDelay:(CGFloat) delay complition:(void (^ __nullable)(void)) handler{
    CGFloat closeDelay = delay ? delay : defaultDelay;
    [self performSelector:@selector(closeView) withObject:nil afterDelay:closeDelay];
}

- (id)transformedValue:(id)value
{
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = @[@"bytes",@"KB",@"MB",@"GB",@"TB", @"PB", @"EB", @"ZB", @"YB"];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, tokens[multiplyFactor]];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
@end
