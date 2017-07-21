//
//  aurorafilesTests.m
//  aurorafilesTests
//
//  Created by Michael Akopyants on 07/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//



#import <Specta/Specta.h>
#import <OCMockito/OCMockito.h>
#import <OCHamcrest/OCHamcrest.h>

#import "ApiProtocol.h"
#import "ErrorProvider.h"


SpecBegin(ApiProtocol);
describe(@"User session status", ^{
    __block id<ApiProtocol> mockManager;
    __block NSError *testError;
    __block NSError *nilError;
    __block void (^mockedBlock)(BOOL, NSError *) = ^void(BOOL isAuthorized, NSError *error){};
    __block void (^userDataBlock)(BOOL, NSError *) = ^void(BOOL isAuthorized, NSError *error){};
    describe(@"Check user status", ^{
        beforeAll(^{
            mockManager = mockProtocol(@protocol(ApiProtocol));
            testError = [[ErrorProvider instance]generateError:@"070915"];
            nilError = nil;
            userDataBlock = nil;
        });
        context(@"Without error", ^{
            before(^{
                [givenVoid([mockManager userData:mockedBlock])willDo:^id _Nonnull(NSInvocation *args) {
                    NSArray *arguments = [args mkt_arguments];
                    NSLog(@"arg 0 is -> %@",arguments[0]);
                    userDataBlock = arguments[0];
                    userDataBlock(YES,nil);
                    return nil;
                }];
            });
            it(@"Signed in", ^{
                [mockManager userData:^(BOOL authorised, NSError *error) {
                    assertThatBool(authorised, isTrue());
                    assertThat(error, nilValue());
                }];
            });
            
            before(^{
                [givenVoid([mockManager userData:mockedBlock])willDo:^id _Nonnull(NSInvocation *args) {
                    NSArray *arguments = [args mkt_arguments];
                    userDataBlock = arguments[0];
                    userDataBlock(NO,nil);
                    return nil;
                }];
            });
            it(@"Signed out", ^{
                [mockManager userData:^(BOOL authorised, NSError *error) {
                    assertThatBool(authorised, isFalse());
                    assertThat(error, nilValue());
                }];
            });

        });
        
        context(@"With error", ^{
            before(^{
                [givenVoid([mockManager userData:mockedBlock])willDo:^id _Nonnull(NSInvocation *args) {
                    NSArray *arguments = [args mkt_arguments];
                    userDataBlock = arguments[0];
                    userDataBlock(YES,testError);
                    return nil;
                }];
            });
            it(@"Signed in", ^{
                [mockManager userData:^(BOOL authorised, NSError *error) {
                    assertThatBool(authorised, isTrue());
                    assertThat(error, equalTo(testError));
                }];
            });
            before(^{
                [givenVoid([mockManager userData:mockedBlock])willDo:^id _Nonnull(NSInvocation *args) {
                    NSArray *arguments = [args mkt_arguments];
                    userDataBlock = arguments[0];
                    userDataBlock(NO,testError);
                    return nil;
                }];
            });
            it(@"Signed out", ^{
                [mockManager userData:^(BOOL authorised, NSError *error) {
                    assertThatBool(authorised, isFalse());
                    assertThat(error, equalTo(testError));
                }];
            });

        });
    });
});
SpecEnd
