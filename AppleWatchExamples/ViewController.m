//
//  ViewController.m
//  AppleWatchExamples
//
//  Copyright (c) 2015 Estimote, Inc. All rights reserved.
//

#import "ViewController.h"
#import <EstimoteSDK/EstimoteSDK.h>

@interface ViewController () <ESTNearableManagerDelegate>

// UI
@property (nonatomic, weak) IBOutlet UILabel *identifierLabel;
@property (nonatomic, weak) IBOutlet UILabel *zoneLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *regionEventSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *zoneSegmentedControl;

// Model
@property (nonatomic, strong) ESTNotificationTransporter *transporter;
@property (nonatomic, strong) ESTSimulatedNearableManager *simulator;
@property (nonatomic, strong) ESTNearable *nearable;

@end

@implementation ViewController

#pragma mark - ViewController Life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[ESTNotificationTransporter sharedTransporter] setAppGroupIdentifier:@"group.com.estimote.appleWatchExamples"];
    self.transporter = [ESTNotificationTransporter sharedTransporter];

    [self.transporter addObserver:self
                         selector:@selector(didReceiveTransporterZoneNotification)
                  forNotification:ESTNotificationDidSaveNearableZoneDescription];
    
    [self.transporter addObserver:self
                         selector:@selector(didReceiveTransporterNearableNotification)
                  forNotification:ESTNotificationDidSaveNearable];
    
    [self setupSimulator];
}

#pragma mark - UI Actions

- (IBAction)zoneSegmentedControlTouched:(UISegmentedControl *)sender
{
    [self.regionEventSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    
    [self.simulator simulateZoneForNearable:sender.selectedSegmentIndex + 1];
    [self.transporter saveNearableZoneDescription:[sender titleForSegmentAtIndex:sender.selectedSegmentIndex]];
}

- (IBAction)regionEventSegmentedControlTouched:(UISegmentedControl *)sender
{
    [self.zoneSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            [self.simulator simulateDidEnterRegionForNearable:self.nearable];
        break;
            
        case 1:
            [self.simulator simulateDidExitRegionForNearable:self.nearable];
        break;
            
        default:
            break;
    }
}

#pragma mark - ESTNotificationTransporter

- (void)didReceiveTransporterZoneNotification
{
    NSLog(@"iOS app didReceiveTransporterZoneNotification");
}

- (void)didReceiveTransporterNearableNotification
{
    NSLog(@"iOS app didReceiveTransporterNearableNotification");
}

#pragma mark - UI

- (void)updateUIWithNearable:(ESTNearable *)nearable
{
    self.identifierLabel.text = nearable.identifier;
    
    NSString *zone;
    switch (nearable.zone)
    {
        case ESTNearableZoneImmediate:
            zone = @"Immediate";
            break;
        case ESTNearableZoneNear:
            zone = @"Near";
            break;
        case ESTNearableZoneFar:
            zone = @"Far";
            break;
            case ESTNearableZoneUnknown:
            zone = @"Unknown";
            break;
            
        default:
            break;
    }
    self.zoneLabel.text = zone;
}

#pragma mark - Simulator

#define SIMULATED_NEARABLE_ID @"1e7da6fca6de4e60"
- (void)setupSimulator
{
    self.simulator = [[ESTSimulatedNearableManager alloc] initWithDelegate:self
                                                                identifier:SIMULATED_NEARABLE_ID
                                                                      zone:ESTNearableZoneFar];
    [self.simulator startRangingForIdentifier:SIMULATED_NEARABLE_ID];
}

#pragma mark - ESTNearableManagerDelegate

- (void)nearableManager:(ESTNearableManager *)manager didRangeNearable:(ESTNearable *)nearable
{
    self.nearable = nearable;
    [self updateUIWithNearable:nearable];
    [self.transporter saveNearable:nearable];
}

- (void)nearableManager:(ESTNearableManager *)manager didEnterIdentifierRegion:(NSString *)identifier
{
    [self.transporter notifyDidEnterIdentifierRegion:identifier];
}

- (void)nearableManager:(ESTNearableManager *)manager didExitIdentifierRegion:(NSString *)identifier
{
    [self.transporter notifyDidExitIdentifierRegion:identifier];
}

@end
