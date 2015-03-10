# Estimote WatchKit SDK

Estimote WatchKit SDK is a set of tools and examples to make building Apple Watch apps powered by beacons and nearables quick and easy.

**Table of Contents**

- [What's included?](#whats-included)
- [How to get started?](#how-to-get-started)
- [Documentation](#documentation)
	- [ESTNotificationTransporter](#estnotificationtransporter)
	- [Nearables Simulator](#nearables-simulator)
- [Coming next...](#coming-next)
- [Let us know your thoughts](#let-us-know-your-thoughts)

## What's included?

First, there's a **special build¹ of the [Estimote SDK 3.0 beta](https://github.com/Estimote/iOS-SDK/tree/3.0.0-beta)** which adds:
 - **Nearables Simulator**. You can't test your Watch app on a real device just yet, so we added an ESTSimulatedNearableManager to enable you to test your nearables ⇔ Watch app integration in the Xcode simulator, which traditionally doesn't support Bluetooth Smart and hence doesn't work with the regular ESTNearableManager and ESTBeaconManager.
 - **ESTNotificationTransporter**. Building a Watch app really is about building a WatchKit extension to an iOS app, the latter of which continues to do all the heavy lifting — like scanning for beacons and nearables. So we've made it easy to have your iOS app communicate ranging and monitoring result to the WatchKit extension.

And then, we prepared **a Sneaker Seeker demo app**, which shows how to use all of the new additions to build a nearables-powered Apple Watch app.

*¹ The ESTSimulatedNearableManager and ESTNotificationTransporter are coming to the [3.0.0-beta branch of the Estimote SDK](https://github.com/Estimote/iOS-SDK/tree/3.0.0-beta) later this week. For now, please use the EstimoteSDK.framework included in the Estimote-WatchKit-SDK repo.*

## How to get started?

For the WatchKit extension and the iOS app to communicate, you need to set up an App Group — a shared container where two separate processes can exchange data.

Download the Estimote-WatchKit-SDK, open up the "SNEAKER SEEKER" Xcode project and then:

1. Click on the "SNEAKER SEEKER" top-level item in the Project Navigator, on the left side.
2. On the General tab, change the Bundle Identifier to your own, e.g. "com.doe.john.sneakerSeeker".
3. On the Capabilities tab, in the App Groups section, un-check the default "group.com.estimote.appleWatchExamples" and add your own instead, e.g. "group.com.doe.john.sneakerSeeker".
4. In the "TARGETS" section on the left, select "SNEAKER SEEKER WatchKit Extension" and on the General tab, adjust the Bundle Identifier to match the one from step 2 ("com.doe.john.sneakerSeeker.**watchkitextension**").
5. Find the "AppleWatchExamples.entitlements" in the Project Navigator and change the value of the "Item 0" key to your App Group ("group.com.doe.john.sneakerSeeker").
6. Repeat step 5 for "AppleWatchExamples WatchKit Extension.entitlements".
7. In the "ViewController.m" file, change the parameter of the `setAppGroupIdentifier` method call to your App Group ("group.com.doe.john.sneakerSeeker").
8. Repeat step 7 for "InterfaceController.m" file.

Now you're ready to run the demo!

## Documentation

### ESTNotificationTransporter

A quick recap on the architecture of the WatchKit app. We have the WatchKit app itself, it runs on the Watch and it’s only about the presentation layer. We have the WatchKit extension which resides on the phone and runs all the Watch-related code. This code is supposed to be lightweight, so it’s not a good candidate for beacon/stickers ranging and monitoring. And finally, we have the “parent” iOS app, also running on the phone, in a separate process — and that's our perfect spot for any long-running, background tasks like monitoring.

There’s the catch: the WatchKit extension and the “parent” app live in separate processes and sandboxes, so if we’re to pass beacons or stickers ranging/monitoring results from the app into the extension, we need to employ some inter-process communication. Which is where the ESTNotificationTransporter comes in.

The way you’d usually go about communicating beacon and stickers ranging results from the iOS app to the WatchKit extension:

 1. [iOS app] Receive the ranging results in your didRange delegate.
 2. [iOS app] Serialize them and put them into a “shared storage” — the App Group.
 3. [iOS app] Notify the WatchKit extension that new ranging results are available.
 4. [WatchKit extension] Receive the notification from the iOS app.
 5. [WatchKit extension] Read and unserialize data from the App Group storage.
 6. [WatchKit extension] Act on the newest data.

ESTNotificationTransporter takes care of all of that for you.

First, in your Project Settings, on the Capabilities tab, enable the App Group capability and add an App Group, e.g. group.com.example.helloWatch. In both your iOS app and WatchKit extension’s code, obtain an instance of the ESTNotificationTransporter and set it up with this App Group identifier:

    self.transporter = [ESTNotificationTransporter sharedTransporter];
    [self.transporter setAppGroupIdentifier:@"group.com.example.helloWatch"];

Then, set your iOS app with beacon or nearable manager as usual — let’s assume it’s the nearable manager. In the didRangeNearable delegate add:

    - (void)nearableManager:(ESTNearableManager *)manager 
           didRangeNearable:(ESTNearable *)nearable {
        [self.transporter saveNearable:nearable];
    }

In your WatchKit extension’s setup, subscribe to appropriate notification:

    [self.transporter addObserver:self
                         selector:@selector(didRangeNearableViaNotification:)
                  forNotification:ESTNotificationDidSaveNearable];

...and add the code to handle it:

    - (void)didRangeNearableViaNotification:(NSNotification *)notification {
        ESTNearable *nearable = [self.transporter readNearable];
        // TODO: add your Watch app response to the ranging results here
    }

That’s it for ranging nearables, but the ESTNotificationTransporter can also handle communication around enter and exit events, proximity zone changes etc. Well, let’s go through one more example then — enter the range of a nearable. In the didEnterIdentifierRegion delegate add:

    -  (void)nearableManager:(ESTNearableManager *)manager 
    didEnterIdentifierRegion:(NSString *)identifier {
        [self.transporter notifyDidEnterIdentifierRegion:identifier];
    }

In the WatchKit extension’s setup:

    [self.transporter addObserver:self
                         selector:@selector(didEnterNearableRange)
                  forNotification:ESTNotificationDidNearableEnterRegion];

And the handler method:

    - (void)didEnterNearableRange {
        NSString *id = [self.transporter readIdentifierForMonitoringEvents];
    }

### Nearables Simulator

You know how to code up the communication between the app that’s on your iPhone and scanning for beacons or stickers, and its WatchKit extension. The question is: how do you go about testing it? You can only run your Watch app in a simulator at this time, and the simulator doesn’t exactly work with beacons or stickers…

You could mock it all up, but it’s time consuming, so… we’ve done it for you! Meet another addition to the Estimote SDK 3.0 — ESTSimulatedNearableManager:

    self.simulator = [[ESTSimulatedNearableManager alloc]
                      initWithDelegate:self
                      identifier:@"0a1b2c3d4e5f6a7b"
                      zone:ESTNearableZoneFar];

This instantiates the simulator with a single, simulated nearable with the specified ID and in “far” distance to the phone. While at this time proximity zone is the only property that’s being stubbed out by the simulator, we’ll be adding more of them soon, so that you can also simulate your nearables moving, flipping around, getting cold etc. These leverage our built-in accelerometer and temperature sensors, which give incredible context to objects! 

The simulator works just like a regular ESTNearableManager, so we can now start ranging for our simulated nearable:

    [self.simulator startRangingForIdentifier:@"0a1b2c3d4e5f6a7b"];

...and receive appropriate events (didRange, didEnter, didExit) to our ESTNearableManagerDelegate like usual — only it will actually work in the iOS simulator, providing a “virtual” ESTNearable object:

    - (void)nearableManager:(ESTNearableManager *)manager
           didRangeNearable:(ESTNearable *)nearable {
        // assert(nearable.identifier == @"0a1b2c3d4e5f6a7b");
        // assert(nearable.zone == ESTNearableZoneFar);
        // ...
    }

Naturally, the simulator wouldn’t be much useful if we couldn’t dynamically control the properties of the simulated nearable and trigger enters or exits on demand:

    [self.simulator simulateZoneForNearable:ESTNearableZoneNear];

Monitoring works, too!

    [self.simulator startMonitoringForIdentifier:self.nearable.identifier];

.

    [self.simulator simulateDidEnterRegionForNearable:self.nearable];

    ...

    -  (void)nearableManager:(ESTNearableManager *)manager
    didEnterIdentifierRegion:(NSString *)identifier {
        // assert(identifier == self.nearable.identifier);
        // ...
    }

.

    [self.simulator simulateDidExitRegionForNearable:self.nearable];

    ...

    - (void)nearableManager:(ESTNearableManager *)manager   
    didExitIdentifierRegion:(NSString *)identifier {
        // assert(identifier == self.nearable.identifier);
        // ...
    }

Finally, once you’re past the development and testing stages, and ready to go live, all it takes is to replace the ESTSimulatedNearableManager with a regular ESTNearableManager. You’ll also need to remove any simulator-only methods from your code.

## Coming next...

 - More demo apps! Learn how to do trigger Watch notifications with beacons and nearables, and how to modify your glances based on ranging and monitoring results.
 - Beacons Simulator.
 - Expanding functionalities of ESTNotificationTransporter and both simulators.

## Let us know your thoughts

Head to [forums.estimote.com](https://forums.estimote.com) and discuss!
