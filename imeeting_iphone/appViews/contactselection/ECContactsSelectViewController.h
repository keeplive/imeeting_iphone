//
//  ECContactsSelectViewController.h
//  imeeting_iphone
//
//  Created by star king on 12-7-5.
//  Copyright (c) 2012年 elegant cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactsSelectViewController.h"

@interface ECContactsSelectViewController : ContactsSelectViewController {
     NSMutableArray *_currentInviteArray;
}

// if it's appeared in creating new group.
@property (nonatomic) BOOL isAppearedInCreateNewGroup;


- (void)inviteAttendees:(NSArray*)attendeeArray;
- (void)goBackToGroupView;
@end
