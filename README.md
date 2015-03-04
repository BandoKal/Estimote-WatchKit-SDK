##ESTNotificationTransporter

Exchange #nearables data between your host app and extension / Watch


ESTNotificationTransporter is a class that allows you to easily exchange data between a host app and extension.
After each successful save, an ESTNotification is sent so extension, or host app, can read data.

###Setup

Before implementing this class remember to setup App Groups in your project.
Please read https://developer.apple.com/library/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html
(Sharing Data with Your Containing App section) if you have any problems with that.

###Usage

ESTNotificationTransporter is a singleton class, but before calling 

`[ESTNotificationTransporter sharedTransporter]` 

set App Group identifier:

`[[ESTNotificationTransporter sharedTransporter] setAppGroupIdentifier:@"group.com.company.bundleIdentifier"]` 

so that both host app and extension can exchange data.

Next, add your class as NotificationTransporter observer:

    [[ESTNotificationTransporter sharedTransporter] addObserver:self
                                                       selector:@selector(didReceiveTransporterDidNearableEnterRegionNotification)
                                                forNotification:ESTNotificationDidNearableEnterRegion]

After receiving `ESTNotificationDidNearableEnterRegion` you can use NotificationTransporter to read data:

	- (void)didReceiveTransporterDidNearableEnterRegionNotification
	{
	    [self nearableDidEnterRegionIdentifier:[[ESTNotificationTransporter sharedTransporter readIdentifierForMonitoringEvents]]];
	}

Sending a notification is as simple as:

	[[ESTNotificationTransporter sharedTransporter] notifyDidEnterIdentifierRegion:identifier]

You can find example usage of ESTNotificationTransporter in our SNEAKER SEEKER app.