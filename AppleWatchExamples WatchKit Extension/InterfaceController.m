//
//  InterfaceController.m
//  AppleWatchExamples WatchKit Extension
//
//  Copyright (c) 2015 Estimote, Inc. All rights reserved.
//

#import "InterfaceController.h"
#import <EstimoteSDK/EstimoteSDK.h>

@interface InterfaceController()

// Model
@property (nonatomic) ESTNotificationTransporter *transporter;

// UI
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *mainGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleZone;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *warningLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *payButton;

@end


@implementation InterfaceController

#pragma mark - InterfaceController Life cycle

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];

    [self setupTransporter];
}

#pragma mark - ESTNotificationTransporter Methods

- (void)setupTransporter
{
    [[ESTNotificationTransporter sharedTransporter] setAppGroupIdentifier:@"group.com.estimote.appleWatchExamples"];
    self.transporter = [ESTNotificationTransporter sharedTransporter];
    
    [self.transporter addObserver:self
                         selector:@selector(updateNearableZoneImage:)
                  forNotification:ESTNotificationDidSaveNearableZoneDescription];
    
    [self.transporter addObserver:self
                         selector:@selector(didReceiveTransporterNearableNotification)
                  forNotification:ESTNotificationDidSaveNearable];
    
    [self.transporter addObserver:self
                         selector:@selector(didReceiveTransporterDidNearableEnterRegionNotification)
                  forNotification:ESTNotificationDidNearableEnterRegion];
    
    [self.transporter addObserver:self
                         selector:@selector(didReceiveTransporterDidNearableExitRegionNotification)
                  forNotification:ESTNotificationDidNearabeExitRegion];
}

- (void)updateNearableZoneImage:(NSNotification *)notification
{
    NSLog(@"Watch app didReceiveTransporterZoneNotification");
    [self setImageForZone:[self.transporter readNearableZoneDescription]];
}

- (void)didReceiveTransporterNearableNotification
{
    NSLog(@"Watch app didReceiveTransporterNearableNotification");
    
    // How to read custom class in extension without implementation file? (Implementation file in static library).
    ESTNearable *nearableFromDisk = [self.transporter readNearable];
    
    NSLog(@"Nearable discovered: %@", nearableFromDisk.identifier);
    //[self setImageForZone:nearableFromDisk.zone];
}

- (void)didReceiveTransporterDidNearableEnterRegionNotification
{
    [self nearableDidEnterRegionIdentifier:[self.transporter readIdentifierForMonitoringEvents]];
}

- (void)didReceiveTransporterDidNearableExitRegionNotification
{
    [self nearableDidExitRegionIdentifier:[self.transporter readIdentifierForMonitoringEvents]];
}

- (void)nearableDidEnterRegionIdentifier:(NSString *)identifier
{
    // Do nothing
}

- (void)nearableDidExitRegionIdentifier:(NSString *)identifier
{
    [self.mainGroup setBackgroundImageNamed:@"background_cold"];

    [self.payButton setHidden:YES];
    [self.titleZone setHidden:NO];
    [self.titleZone setText:@"BRRRR...\nYOU'RE FREEZING!"];
}

#pragma mark - User Interface

- (void)setImageForZone:(NSString *)zone
{
    if (!zone)
    {
        return;
    }
    
    [self.warningLabel setHidden:YES];
    [self.payButton setHidden:YES];
    [self.titleZone setHidden:NO];
    
    if ([zone isEqualToString:@"Immediate"])
    {
        [self.mainGroup setBackgroundImageNamed:@"shoe-pay"];

        [self.payButton setHidden:NO];
        [self.payButton setWidth:140];
        [self.payButton setHeight:40];

        [self.titleZone setHidden:YES];
    }
    else if ([zone isEqualToString:@"Near"])
    {
        [self.mainGroup setBackgroundImageNamed:@"background_warm"];
        [self.titleZone setText:@"YOU'RE REALLY CLOSE..."];
    }
    else if ([zone isEqualToString:@"Far"])
    {
        [self.mainGroup setBackgroundImageNamed:@"background_medium"];
        [self.titleZone setText:@"GETTING CLOSER...\nIT'S MUCH WARMER!"];
    }
}

@end



