//
//  EventViewController.m
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "EventViewController.h"
#import <DRYUI/DRYUI.h>
#import <ChameleonFramework/Chameleon.h>
#import <BlocksKit/BlocksKit+UIKit.h>


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface EventViewController()

@property (nonatomic, strong) Data *data;
@property (nonatomic, strong) Event *originalEvent;
@property (nonatomic, strong) Event *editingEvent;
@property (nonatomic, strong) EventViewControllerDoneBlock done;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation EventViewController

- (instancetype)initWithData:(Data *)data andEvent:(Event *)event done:(EventViewControllerDoneBlock)done {
    if (([super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.data = data;
        self.originalEvent = event;
        self.editingEvent = [event copy];
        self.done = done;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)loadView {
    self.view = [UIView new];
    self.view.backgroundColor = FlatNavyBlueDark;
    build_subviews(self.view) {
        UITextField *add_subview(name) {
            _.text = self.editingEvent.name;
            _.backgroundColor = FlatNavyBlue;
            _.textColor = FlatWhiteDark;
            _.make.left.and.right.equalTo(superview);
            _.make.top.equalTo(superview).with.offset(10);
            _.make.height.equalTo(@50);
        };
        UITextField *add_subview(date) {
            _.text = [self.dateFormatter stringFromDate:self.editingEvent.date];
            _.textColor = FlatWhiteDark;
            _.backgroundColor = FlatNavyBlue;
            
            UIDatePicker *pickerView = [UIDatePicker new];
            _.inputView = pickerView;
            
            // create a done view + done button, attach to it a doneClicked action, and place it in a toolbar as an accessory input view...
            // Prepare done button
            UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
            keyboardDoneButtonView.barStyle = UIBarStyleBlack;
            keyboardDoneButtonView.translucent = YES;
            keyboardDoneButtonView.tintColor = nil;
            [keyboardDoneButtonView sizeToFit];
            
            UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dateDoneButtonPressed:)];
            [keyboardDoneButtonView setItems:@[doneButton]];
            _.inputAccessoryView = keyboardDoneButtonView;
            
            [pickerView bk_addEventHandler:^(id sender) {
                self.editingEvent.date = pickerView.date;
                _.text = [self.dateFormatter stringFromDate:self.editingEvent.date];
            } forControlEvents:UIControlEventValueChanged];
            
            _.make.left.and.right.equalTo(superview);
            _.make.top.equalTo(name.mas_bottom).with.offset(10);
            _.make.height.equalTo(@50);
        }
    };
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

- (void)dateDoneButtonPressed:(id)sender {
    [self.view endEditing:YES];
}

- (void)doneButtonPressed:(id)sender {
    self.done(self.editingEvent);
}

- (void)cancelButtonPressed:(id)sender {
    self.done(self.originalEvent);
}

@end
