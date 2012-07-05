//
//  ECContactsSelectViewController.m
//  imeeting_iphone
//
//  Created by star king on 12-7-5.
//  Copyright (c) 2012年 elegant cloud. All rights reserved.
//

#import "ECContactsSelectViewController.h"
#import "ECContactsSelectContainerView.h"
#import "ContactBean+IMeeting.h"
#import "ECGroupModule.h"
#import "ECGroupManager.h"
#import "ECConstants.h"
#import "ECUrlConfig.h"
#import "ECGroupVideoViewController.h"
#import "ECGroupAttendeeListViewController.h"

@interface ECContactsSelectViewController ()
- (void)onFinishedInviteAttendees:(ASIHTTPRequest*)pRequest;
- (void)doJump;
- (void)setupGroupModuleWithGroupId:(NSString *)groupId;
- (void)sendSMS;
@end

@implementation ECContactsSelectViewController
@synthesize isAppearedInCreateNewGroup = _isAppearedInCreateNewGroup;

- (id)init{
    return [super initWithCompatibleView:[[ECContactsSelectContainerView alloc] init]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isAppearedInCreateNewGroup = YES;
        
    }
    return self;
}

- (void)setIsAppearedInCreateNewGroup:(BOOL)isAppearedInCreateNewGroup {
    _isAppearedInCreateNewGroup = isAppearedInCreateNewGroup;
    ECContactsSelectContainerView *view = (ECContactsSelectContainerView*)self.view;
    view.isAppearedInCreatingNewGroup = isAppearedInCreateNewGroup;
    
    if (isAppearedInCreateNewGroup) {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Next", "")];
    } else {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"invite", "")];
    }
}

#pragma mark - actions
- (void)inviteAttendees:(NSArray *)attendeeArray {
    mCurrentInviteArray = [NSMutableArray arrayWithCapacity:10];
    for (ContactBean *contact in attendeeArray) {
        [mCurrentInviteArray addObject:contact.selectedPhoneNumber];
    }
    NSString *attendeesJsonString = [mCurrentInviteArray JSONString];
    NSLog(@"attendees json string: %@", attendeesJsonString);
    
    if (self.isAppearedInCreateNewGroup) {
        // begin to create new group
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:attendeesJsonString, GROUP_ATTENDEES, nil];
        [HttpUtil postSignatureRequestWithUrl:CREATE_GROUP_URL andPostFormat:urlEncoded andParameter:params andUserInfo:nil andRequestType:synchronous andProcessor:self andFinishedRespSelector:@selector(onFinishedInviteAttendees:) andFailedRespSelector:nil];
    } else {
        // already in group
        
        NSString *groupId = [[ECGroupManager sharedECGroupManager] currentGroupModule].groupId;
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:groupId, GROUP_ID, attendeesJsonString, GROUP_ATTENDEES, nil];
        [HttpUtil postRequestWithUrl:INVITE_ATTENDEE_LIST_URL andPostFormat:urlEncoded andParameter:params andUserInfo:nil andRequestType:synchronous andProcessor:self andFinishedRespSelector:@selector(onFinishedInviteAttendees:) andFailedRespSelector:nil];
    }
}

- (void)onFinishedInviteAttendees:(ASIHTTPRequest *)pRequest {
    NSLog(@"onFinishedInviteAttendees - request url = %@, responseStatusCode = %d, responseStatusMsg = %@", pRequest.url, [pRequest responseStatusCode], [pRequest responseStatusMessage]);
    
    int statusCode = pRequest.responseStatusCode;
    
    switch (statusCode) {
        case 200:
            // invite ok
            if ([MFMessageComposeViewController canSendText]) {
                [self sendSMS];
            } else {
                [self doJump];
            }
            
            break;
        case 201: {
            // create group and invite ok
            // send SMS to notify attendees
            NSDictionary *jsonData = [[[NSString alloc] initWithData:pRequest.responseData encoding:NSUTF8StringEncoding] objectFromJSONString];
            if (jsonData) {
                NSString *groupId = [jsonData objectForKey:GROUP_ID];
                [self setupGroupModuleWithGroupId:groupId];
                
                if ([MFMessageComposeViewController canSendText] && mCurrentInviteArray.count > 0) {
                    [self sendSMS];
                } else {
                    [self doJump];
                }
                
            } else {
                goto invite_error;
            }
            
            break;
        }
        default:
            goto invite_error;
            break;
    }
    
    return;
    
invite_error:
    [iToast makeText:NSLocalizedString(@"error in inviting attendees", "")];
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)sendSMS {
    mMsgViewController= [[MFMessageComposeViewController alloc] init];
    
    mMsgViewController.recipients = mCurrentInviteArray;
    
    NSString *groupId = [[ECGroupManager sharedECGroupManager] currentGroupModule].groupId;
    NSString *msgBody = [NSString stringWithFormat:@"%@邀请您加入讨论组(%@)。[iMeeting]", [UserManager shareUserManager].userBean.name, groupId];
    mMsgViewController.body = msgBody;
    mMsgViewController.messageComposeDelegate = self;
    [self presentModalViewController:mMsgViewController animated:YES];
}

- (void)setupGroupModuleWithGroupId:(NSString *)groupId {
    ECGroupVideoViewController *gvc = [[ECGroupVideoViewController alloc] init];
    ECGroupAttendeeListViewController *alvc =[[ECGroupAttendeeListViewController alloc] init];
    ECGroupModule *module = [[ECGroupModule alloc] init];
    module.videoController = gvc;
    module.attendeeController = alvc;
    [ECGroupManager sharedECGroupManager].currentGroupModule = module;    
    module.groupId = groupId;
}

- (void)doJump {
    if (self.isAppearedInCreateNewGroup) {
        NSLog(@"in creating group mode");
        // it is in creating group mode, so we create group view and jump to it
        ECGroupModule *module = [[ECGroupManager sharedECGroupManager] currentGroupModule];
        [module connectToNotifyServer];
        
        [NSThread detachNewThreadSelector:@selector(refreshAttendeeList) toTarget:module.attendeeController withObject:nil];
        
        UIViewController *videoController = module.videoController;
        NSArray *controllers = self.navigationController.viewControllers;
        UIViewController *main = [controllers objectAtIndex:1];
        [NSThread detachNewThreadSelector:@selector(refreshGroupList) toTarget:main withObject:nil];
        
        
        [self.navigationController popViewControllerAnimated:NO];
        [main.navigationController pushViewController:videoController animated:NO];
    } else {
        NSLog(@"already in group mode");
        // already in group mode, so we jump back to group view
        ECGroupModule *module = [[ECGroupManager sharedECGroupManager] currentGroupModule];
        ECGroupAttendeeListViewController *alvc = (ECGroupAttendeeListViewController*)module.attendeeController;
        alvc.refreshList = YES;
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    NSLog(@"messageComposeViewController finished - result: %d", result);
    
    [self dismissModalViewControllerAnimated:YES];
    mMsgViewController = nil;
    
    [self doJump];
    
}

@end