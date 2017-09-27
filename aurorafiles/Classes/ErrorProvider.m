//
//  ErrorProvider.m
//  aurorafiles
//
//  Created by Cheshire on 02.06.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "ErrorProvider.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

const NSString* InvalidToken = @"101";
const NSString* AuthError = @"102";
const NSString* InvalidInputParameter = @"103";
const NSString* DataBaseError = @"104";
const NSString* LicenseProblem = @"105";
const NSString* DemoAccount = @"106";
const NSString* CaptchaError = @"107";
const NSString* AccessDenied = @"108";
const NSString* UnknownEmail = @"109";
const NSString* UserNotAllowed = @"110";
const NSString* UserAlreadyExists = @"111";
const NSString* SystemNotConfigured = @"112";

const NSString* CanNotGetMessageList = @"201";
const NSString* CanNotGetMessage = @"202";
const NSString* CanNotDeleteMessage = @"203";
const NSString* CanNotMoveMessage = @"204";
const NSString* CanNotMoveMessageQuota = @"205";
const NSString* CanNotCopyMessage = @"206";
const NSString* CanNotCopyMessageQuota = @"207";
const NSString* LibraryNoFound = @"208";

const NSString* CanNotSaveMessage = @"301";
const NSString* CanNotSendMessage = @"302";
const NSString* InvalidRecipients = @"303";
const NSString* CannotSaveMessageInSentItems = @"304";
const NSString* UnableSendToRecipients = @"305";
const NSString* ExternalRecipientsBlocked = @"306";

const NSString* CanNotCreateFolder = @"401";
const NSString* CanNotDeleteFolder = @"402";
const NSString* CanNotSubscribeFolder = @"403";
const NSString* CanNotUnsubscribeFolder = @"404";

const NSString* CanNotSaveSettings = @"501";
const NSString* CanNotChangePassword = @"502";
const NSString* AccountOldPasswordNotCorrect = @"503";

const NSString* CanNotCreateContact = @"601";
const NSString* CanNotCreateGroup = @"602";
const NSString* CanNotUpdateContact = @"603";
const NSString* CanNotUpdateGroup = @"604";
const NSString* ContactDataHasBeenModifiedByAnotherApplication = @"605";
const NSString* CanNotGetContact = @"607";

const NSString* CanNotCreateAccount = @"701";
const NSString* FetcherConnectError = @"702";
const NSString* FetcherAuthError = @"703";
const NSString* AccountExists = @"704";

// Rest
const NSString* RestOtherError = @"710";
const NSString* RestApiDisabled = @"711";
const NSString* RestUnknownMethod = @"712";
const NSString* RestInvalidParameters = @"713";
const NSString* RestInvalidCredentials = @"714";
const NSString* RestInvalidToken = @"715";
const NSString* RestTokenExpired = @"716";
const NSString* RestAccountFindFailed = @"717";
const NSString* RestTenantFindFailed = @"719";

const NSString* CalendarsNotAllowed = @"801";
const NSString* FilesNotAllowed = @"802";
const NSString* ContactsNotAllowed = @"803";
const NSString* HelpdeskUserAlreadyExists = @"804";
const NSString* HelpdeskSystemUserExists = @"805";
const NSString* CanNotCreateHelpdeskUser = @"806";
const NSString* HelpdeskUnknownUser = @"807";
const NSString* HelpdeskUnactivatedUser = @"808";
const NSString* VoiceNotAllowed = @"810";
const NSString* IncorrectFileExtension = @"811";
const NSString* CanNotUploadFileQuota = @"812";
const NSString* FileAlreadyExists = @"813";
const NSString* FileNotFound = @"814";

const NSString* MailServerError = @"901";
const NSString* WebAuthError = @"902";
const NSString* UnknownError = @"999";

const NSString* UnitTestError = @"070915";



const NSString *apiDomain = @"com.afterlogic.api";
@interface ErrorProvider(){

}

@end

@implementation ErrorProvider

+ (ErrorProvider *)instance {
    static ErrorProvider *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (BOOL)generatePopWithError:(NSError *)error controller:(UIViewController *)vc {
    return [self generatePopWithError:error controller:vc customCancelAction:nil retryAction:nil];
}

- (BOOL)generatePopWithError:(NSError *)error controller:(UIViewController *)vc customCancelAction:(void (^ __nullable)(UIAlertAction *cancelAction))handler{
   return  [self generatePopWithError:error controller:vc customCancelAction:handler retryAction:nil];
}

- (BOOL)generatePopWithError:(NSError *)error controller:(UIViewController *)vc
          customCancelAction:(void (^ __nullable)(UIAlertAction *cancelAction))handler
                 retryAction:(void (^ __nullable)(UIAlertAction *retryAction))retryHandler{
    
    NSString *errorCode = [NSString stringWithFormat:@"%li",(long)error.code];
    if ([errorCode isEqualToString:@"-999"]) {
        return NO;
    }

    NSString *text = [[self getErrorList] valueForKey:errorCode];
    if(text.length == 0){
        text = error.localizedDescription;
    }
    
    UIAlertController *aC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ERROR", @"error popup label")
                                                                message:text
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text")
                                                            style:UIAlertActionStyleCancel
                                                          handler:handler];
    
    UIAlertAction * retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"retry text")
                                                            style:UIAlertActionStyleDefault
                                                          handler:retryHandler];
    [aC addAction:cancelAction];
    
    if(retryHandler){
        [aC addAction:retryAction];
    }
    
    [vc presentViewController:aC animated:YES completion:nil];
    
    return YES;
}

- (NSError *)generateError:(NSString *)errorCode{
    NSString *localizedDescription = [[self getErrorList] valueForKey:errorCode];
    if (localizedDescription.length == 0 || localizedDescription == nil) {
        return nil;
    }
    NSError *newError = [NSError errorWithDomain:apiDomain
                                            code:errorCode.intValue
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey : localizedDescription
                                                   }];
    return newError;
}

- (NSDictionary *)getErrorList{
    return @{
             
#pragma mark - Application Errors
            @"4001":NSLocalizedString(@"The host is not responding. Try connecting again later", @"4001 error text"),
            @"4061":NSLocalizedString(@"You have entered an invalid e-mail address. Please try again", @"4061 error text"),
            @"4062":NSLocalizedString(@"Host field should not be empty. Please, enter the host url and try again", @"4062 error text"),
            
            @"5000":NSLocalizedString(@"The e-mail or password you entered is incorrect", @"5000 error text"),
            @"1":NSLocalizedString(@"",@""),
            @"9":NSLocalizedString(@"",@""),
            
            @"1001":NSLocalizedString(@"User is logged out", @""),
            
#pragma mark - Server Errors
            InvalidToken: NSLocalizedString(@"invalid token", @"101 aurora error"),
            AuthError: NSLocalizedString(@"authentication failure",@"102 aurora error"),
            InvalidInputParameter: NSLocalizedString(@"invalid data",@"103 aurora error"),
            DataBaseError: NSLocalizedString(@"database error",@"104 aurora error"),
            LicenseProblem:NSLocalizedString(@"license problem",@""),
            DemoAccount:NSLocalizedString(@"demo account",@""),
            CaptchaError:NSLocalizedString(@"captcha error",@""),
            AccessDenied:NSLocalizedString(@"access denied",@""),
            UnknownEmail:NSLocalizedString(@"unknown email",@""),
            UserNotAllowed:NSLocalizedString(@"user not allowed",@""),
            UserAlreadyExists:NSLocalizedString(@"user already exists",@""),
            SystemNotConfigured:NSLocalizedString(@"system not configured",@""),
            
            CanNotGetMessageList:NSLocalizedString(@"can't get message list",@""),
            CanNotGetMessage:NSLocalizedString(@"can't get message",@""),
            CanNotDeleteMessage:NSLocalizedString(@"can't delete message",@""),
            CanNotMoveMessage:NSLocalizedString(@"can't move message",@""),
            CanNotMoveMessageQuota:NSLocalizedString(@"can't move message quota",@""),
            CanNotCopyMessage:NSLocalizedString(@"can't copy message",@""),
            CanNotCopyMessageQuota:NSLocalizedString(@"can't copy message quota",@""),
            LibraryNoFound:NSLocalizedString(@"library not found",@""),
            
            CanNotSaveMessage:NSLocalizedString(@"can't save message",@""),
            CanNotSendMessage:NSLocalizedString(@"can't send message",@""),
            InvalidRecipients:NSLocalizedString(@"invalid recipients",@""),
            CannotSaveMessageInSentItems:NSLocalizedString(@"can't save message in sent items",@""),
            UnableSendToRecipients:NSLocalizedString(@"unable send to recipients",@""),
            ExternalRecipientsBlocked:NSLocalizedString(@"external recipients blocked",@""),
            
            CanNotCreateFolder:NSLocalizedString(@"can't create folder",@""),
            CanNotDeleteFolder:NSLocalizedString(@"can't delete folder",@""),
            CanNotSubscribeFolder:NSLocalizedString(@"can't subscribe folder",@""),
            CanNotUnsubscribeFolder:NSLocalizedString(@"can't unsubscribe folder",@""),
            
            CanNotSaveSettings:NSLocalizedString(@"can't save settings",@""),
            CanNotChangePassword:NSLocalizedString(@"can't change password",@""),
            AccountOldPasswordNotCorrect:NSLocalizedString(@"account old password not correct",@""),
            
            CanNotCreateContact:NSLocalizedString(@"can't create contact",@""),
            CanNotCreateGroup:NSLocalizedString(@"can't create group",@""),
            CanNotUpdateContact:NSLocalizedString(@"can't update contact",@""),
            CanNotUpdateGroup:NSLocalizedString(@"can't update Group",@""),
            ContactDataHasBeenModifiedByAnotherApplication:NSLocalizedString(@"Contact Data Has Been Modified By Another Application",@""),
            CanNotGetContact:NSLocalizedString(@"CanNotGetContact",@""),
            
            CanNotCreateAccount:NSLocalizedString(@"can't Create Account",@""),
            FetcherConnectError:NSLocalizedString(@"Fetcher Connect Error",@""),
            FetcherAuthError:NSLocalizedString(@"Fetcher Auth Error",@""),
            AccountExists:NSLocalizedString(@"Account Exists",@""),
            
            // Rest
            RestOtherError:NSLocalizedString(@"Rest Other Error",@""),
            RestApiDisabled:NSLocalizedString(@"Rest Api Disabled",@""),
            RestUnknownMethod:NSLocalizedString(@"Rest Unknown Method",@""),
            RestInvalidParameters:NSLocalizedString(@"Rest Invalid Parameters",@""),
            RestInvalidCredentials:NSLocalizedString(@"Rest Invalid Credentials",@""),
            RestInvalidToken:NSLocalizedString(@"Rest Invalid Token",@""),
            RestTokenExpired:NSLocalizedString(@"Rest Token Expired",@""),
            RestAccountFindFailed:NSLocalizedString(@"Rest Account Find Failed",@""),
            RestTenantFindFailed:NSLocalizedString(@"Rest Tenant Find Failed",@""),
            
            CalendarsNotAllowed:NSLocalizedString(@"Calendars Not Allowed",@""),
            FilesNotAllowed:NSLocalizedString(@"Files Not Allowed",@""),
            ContactsNotAllowed:NSLocalizedString(@"Contacts Not Allowed",@""),
            HelpdeskUserAlreadyExists:NSLocalizedString(@"Helpdesk User Already Exists",@""),
            HelpdeskSystemUserExists:NSLocalizedString(@"Helpdesk System User Exists",@""),
            CanNotCreateHelpdeskUser:NSLocalizedString(@"can't Create Helpdesk User",@""),
            HelpdeskUnknownUser:NSLocalizedString(@"Helpdesk Unknown User",@""),
            HelpdeskUnactivatedUser:NSLocalizedString(@"Helpdesk Unactivated User",@""),
            VoiceNotAllowed:NSLocalizedString(@"Voice Not Allowed",@""),
            IncorrectFileExtension:NSLocalizedString(@"Incorrect File Extension",@""),
            CanNotUploadFileQuota:NSLocalizedString(@"can't Upload File Quota",@""),
            FileAlreadyExists:NSLocalizedString(@"File Already Exists",@""),
            FileNotFound:NSLocalizedString(@"File Not Found",@""),
            MailServerError :NSLocalizedString(@"Mail Server Error",@""),
            WebAuthError :NSLocalizedString(@"This account is not allowed to log in.", @""),
            UnknownError: NSLocalizedString(@"something goes wrong...",@"unknown error"),
            
#pragma mark - Unit-test Errors
            UnitTestError: NSLocalizedString(@"This error need only for unit-tests!", @"unit test error"),
    };
}

@end
