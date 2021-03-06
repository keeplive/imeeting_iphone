//
//  ContactsSelectContainerView.h
//  IMeeting
//
//  Created by  on 12-6-15.
//  Copyright (c) 2012年 richitec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ABContactsListView.h"
#import "MeetingContactsListView.h"
#import "ECBaseUIView.h"

@interface ContactsSelectContainerView : ECBaseUIView <UIViewGestureRecognizerDelegate>{
    UIView *_newContactInputView;
    UITextField *_phoneNumberInputTextField;
    
    // subview addressBook contacts list table view
    ABContactsListView *_mABContactsListView;
    // subview meeting contacts list table view
    MeetingContactsListView *_mMeetingContactsListView;
    
    // subview meeting contacts list table view prein meeting contacts info array
    NSMutableArray *_mPreinMeetingContactsInfoArray;
    
    UITextField *_mSearchField;
}

@property (nonatomic, readonly) NSMutableArray *preinMeetingContactsInfoArray;

// init subview meeting contacts list table view in meeting contacts info array
- (void)initInMeetingAttendeesPhoneNumbers:(NSArray *)pPhoneNumbers; 

// init subview meeting contacts list table view prein meeting contacts info array
- (void)initPreinMeetingAttendeesPhoneNumbers:(NSArray *)pPhoneNumbers;

// add the selected contact with indexPath and selected phone number to meeting contacts list table view prein meeting section
- (void)addSelectedContactToMeetingWithIndexPath:(NSIndexPath *)pIndexPath andSelectedPhoneNumber:(NSString *)pSelectedPhoneNumber;

// remove the select contact from meeting contacts list view prein meeting secton if it is in
- (void)removeSelectedContactFromMeetingWithIndexPath:(NSIndexPath *)pIndexPath;

// add contact with user input phone number to meeting contacts list table view prein meeting section
- (void)addContactToMeetingWithPhoneNumber:(NSString *)pPhoneNumber;

// search contact with parameters
- (void)searchContactWithParameter;

// hide softKeyboard when contacts list table view will begin dragging
- (void)hideSoftKeyboardWhenBeginScroll;

@end
