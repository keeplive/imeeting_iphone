//
//  UserBean+IMeeting.m
//  imeeting_iphone
//
//  Created by star king on 12-6-18.
//  Copyright (c) 2012年 elegant cloud. All rights reserved.
//

#import "UserBean+IMeeting.h"

@implementation UserBean (IMeeting)

- (void)setRememberPwd:(BOOL)rememberPwd {
    [self.extensionDic setObject:[NSNumber numberWithBool:rememberPwd] forKey:@"rememberPwd"];
}

- (BOOL)rememberPwd {
    BOOL remeber = NO;
    NSNumber * ret = [self.extensionDic objectForKey:@"rememberPwd"];
    if (ret) {
        remeber = ret.boolValue;
    }

    return remeber;
}

@end
