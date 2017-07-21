//
//  SessionProviderTest.m
//  aurorafiles
//
//  Created by Slava Kutenkov on 18/07/2017.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import <Specta/Specta.h>
#import <OCMockito/OCMockito.h>
#import <OCHamcrest/OCHamcrest.h>

#import "SessionProvider.h"
#import "Settings.h"

SpecBegin(SessionProviderTest);

describe(@"check SSL connection", ^{
    __block __strong Class settingsMock = mockClass([Settings class]);
    __block SessionProvider *sessionProvider = [SessionProvider sharedManagerWithSettings:settingsMock];
    before(^{
        [given([settingsMock domain]) willReturn:@"aurora-files.afterlogic.com"];
    });
    context(@"host have a http connection", ^{
        [sessionProvider checkSSLConnection:^(NSString *domain) {
            assertThat([Settings domainScheme],equalTo(@"http://") );
            assertThat([Settings domainScheme],containsSubstring(@"://"));
        }];
    });
    
//    context(@"host have a https connection", ^{
//        [sessionProvider checkSSLConnection:^(NSString *domain) {
//            
//        }];
//    });
});

//describe(@"check domain version", ^{
//    describe(@"first test", ^{
//        <#code#>
//    })';'
//});

SpecEnd;
