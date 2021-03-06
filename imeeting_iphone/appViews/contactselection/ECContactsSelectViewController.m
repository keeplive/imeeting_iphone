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
#import "ECGroupViewController.h"
#import "ECMainPageViewController.h"
#import "AuthInterceptor.h"

@interface ECContactsSelectViewController ()
- (void)onFinishedInviteAttendees:(ASIHTTPRequest*)pRequest;
- (void)doJump;
- (void)setupGroupModuleWithGroupId:(NSString *)groupId;
- (void)onNetworkFailed:(ASIHTTPRequest*)pRequest;
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
        ECContactsSelectContainerView *view = (ECContactsSelectContainerView*)self.view;
        [view.createButton setTitle:NSLocalizedString(@"Open Talk", nil) forState:UIControlStateNormal];
    } else {
        ECContactsSelectContainerView *view = (ECContactsSelectContainerView*)self.view;
        [view.createButton setTitle:NSLocalizedString(@"invite", nil) forState:UIControlStateNormal];
    }
     
}

#pragma mark - actions
- (void)inviteAttendees:(NSArray *)attendeeArray {
    _currentInviteArray = [NSMutableArray arrayWithCapacity:10];
    for (ContactBean *contact in attendeeArray) {
        [_currentInviteArray addObject:contact.selectedPhoneNumber];
    }
    NSString *attendeesJsonString = [_currentInviteArray JSONString];
    NSLog(@"attendees json string: %@", attendeesJsonString);
    
    if (self.isAppearedInCreateNewGroup) {
        // begin to create new group
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:attendeesJsonString, GROUP_ATTENDEES, nil];
        [HttpUtil postSignatureRequestWithUrl:CREATE_CONF_URL andPostFormat:urlEncoded andParameter:params andUserInfo:nil andRequestType:synchronous andProcessor:self andFinishedRespSelector:@selector(onFinishedInviteAttendees:) andFailedRespSelector:@selector(onNetworkFailed:)];
    } else {
        // already in group
        
        NSString *groupId = [[ECGroupManager sharedECGroupManager] currentGroupModule].groupId;
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:groupId, GROUP_ID, attendeesJsonString, GROUP_ATTENDEES, nil];
        [HttpUtil postSignatureRequestWithUrl:INVITE_ATTENDEE_LIST_URL andPostFormat:urlEncoded andParameter:params andUserInfo:nil andRequestType:synchronous andProcessor:self andFinishedRespSelector:@selector(onFinishedInviteAttendees:) andFailedRespSelector:@selector(onNetworkFailed:)];
    }
}

- (void)onFinishedInviteAttendees:(ASIHTTPRequest *)pRequest {
    NSLog(@"onFinishedInviteAttendees - request url = %@, responseStatusCode = %d, responseStatusMsg = %@", pRequest.url, [pRequest responseStatusCode], [pRequest responseStatusMessage]);
    
    int statusCode = pRequest.responseStatusCode;
    
    switch (statusCode) {
        case 200:
            // invite ok
            [self doJump];
       
            break;
        case 201: {
            // create group and invite ok
            // send SMS to notify attendees
            NSDictionary *jsonData = [[[NSString alloc] initWithData:pRequest.responseData encoding:NSUTF8StringEncoding] objectFromJSONString];
            if (jsonData) {
                NSString *groupId = [jsonData objectForKey:GROUP_ID];
                [self setupGroupModuleWithGroupId:groupId];
                
                ECGroupModule *module = [ECGroupManager sharedECGroupManager].currentGroupModule;
                module.audioConfId = [jsonData objectForKey:AUDIO_CONF_ID];
                module.owner = [jsonData objectForKey:OWNER];
                
                [self doJump];
                
            } else {
                goto create_error;
            }
            
            break;
        }
        default:
            goto create_error;
            break;
    }
    
    return;
    
invite_error:
    [[[iToast makeText:NSLocalizedString(@"error in inviting attendees", "")] setDuration:iToastDurationLong] show];
    [self.navigationController popViewControllerAnimated:YES];
    return;
    
create_error:
    [[[iToast makeText:NSLocalizedString(@"error in creating group", "")] setDuration:iToastDurationLong] show];
    [self.navigationController popViewControllerAnimated:YES];
    return;
}

- (void)onNetworkFailed:(ASIHTTPRequest *)pRequest {
    HTTP_RETURN_CHECK(pRequest, self);
}

- (void)setupGroupModuleWithGroupId:(NSString *)groupId {
    ECGroupViewController *gvc = [[ECGroupViewController alloc] init];
    ECGroupModule *module = [[ECGroupModule alloc] init];
    module.groupController = gvc;
    [ECGroupManager sharedECGroupManager].currentGroupModule = module;    
    module.groupId = groupId;
}

- (void)doJump {
    if (self.isAppearedInCreateNewGroup) {
        NSLog(@"in creating group mode");
        // it is in creating group mode, so we create group view and jump to it
        ECGroupModule *module = [[ECGroupManager sharedECGroupManager] currentGroupModule];
        [module connectToNotifyServer];
        
      //  [NSThread detachNewThreadSelector:@selector(refreshAttendeeList) toTarget:module.groupController withObject:nil];
        [module.groupController performSelector:@selector(refreshAttendeeList)];
        
        ECMainPageViewController *mainController = [ECMainPageViewController shareViewController];
        [NSThread detachNewThreadSelector:@selector(refreshGroupList) toTarget:mainController withObject:nil];

        [self.navigationController popViewControllerAnimated:NO];
        [mainController.navigationController pushViewController:module.groupController animated:YES];
    } else {
        NSLog(@"already in group mode");
        // already in group mode, so we jump back to group view
        ECGroupModule *module = [[ECGroupManager sharedECGroupManager] currentGroupModule];
        ECGroupViewController *gc = (ECGroupViewController*)module.groupController;
        gc.refreshList = YES;
        //[NSThread detachNewThreadSelector:@selector(refreshAttendeeList) toTarget:gc withObject:nil];
        [gc refreshAttendeeList];
        [self goBackToGroupView];
    }
}

- (void)goBackToGroupView {
    /*
     CATransition *animation = [CATransition animation];
     animation.duration = 0.3f;
     animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
     animation.type = kCATransitionReveal;
     animation.subtype = kCATransitionFromBottom;        
     [self.navigationController.view.layer addAnimation:animation forKey:nil];
     [self.navigationController popViewControllerAnimated:NO];
     */
    [UIView beginAnimations:@"animationID" context:nil];
    [UIView setAnimationDuration:0.4f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationRepeatAutoreverses:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:YES];
    [self.navigationController popViewControllerAnimated:NO];
    [UIView commitAnimations];

}


@end
