#GPSKit
CoreLocation without the fuss (and with blocks!).

CoreLocation is really powerful, but with great power comes great responsibility. There’s a lot of non-obvious stuff you’re responsible to plan for when using CoreLocation for everyday tasks. GPSKit is a library that does all the heavy lifting for you and simplifies these common tasks into a new shiny block-based interface

GPSKit structures CoreLocation operations around common use cases: GPS signal strength monitoring, location lookups, and continuous GPS tracking.

These use cases can be mixed and matched throughout your application and GPSKit will manage the hard parts behind the scenes.

##How to get Started
* Set up [CocoaPods](http://cocoapods.org) and add `` pod 'GPSKit'`` to your Podfile
* ``#import <GPSKit\CLHGPSKit.h>`` where you want to use GPSKit

##Usage

``CLHLocationSubscriber`` is your gateway to GPSKit. Grab a new instance and use it anywhere you want to get GPS data. Keep it around for when you want to stop any GPS work (such as unsubscribing for signal updates in ``ViewWillDisappear``).

###Signal Strength Monitoring
Provides updates about the current signal strength when new locations are returned by CoreLocation. If no other GPS activity requests are active GPSKit will use polling of the GPS system to monitor signal strength (as opposed to keeping GPS active all the time).

Start monitoring:
```objective-c
CLHLocationSubscriber *locationSubscriber = [[CLHLocationSubscriber alloc] init];
[locationSubscriber startSignalMonitoringWithHandler:^(CLHGPSKitSignalStrength strength) {
	//do something with the signal strength
}];
```
Ending monitoring:
```objective-c
[locationSubscriber stopSignalMonitoring];
```

###Location Lookup
Gets the user's current location. Cold-start GPS lookups tend to be inaccurate at first as it gets satellite fixes (or have cached old locations), so the API manages separating out inaccurate GPS coordinates from the final one that's accurate enough to use.

Starting a lookup:
```objective-c
CLHLocationSubscriber *locationSubscriber = [[CLHLocationSubscriber alloc] init];
[locationSubscriber resolveCurrentLocationWithInProgressHandler:^(CLLocation *location) {
	//do something with the location, knowing it possibly isn't the final one
	//useful if you can pre-start a network request knowing the general region a user is in
} andCompletionHandler:^(CLLocation *location) {
	//do something with the user's location
}];
```
Canceling an in-progress lookup:
```objective-c
[locationSubscriber cancelResolvingCurrentLocation];
```

###Continuous GPS Tracking
Continuously reports the user's current location.

Starting GPS tracking:
```objective-c
CLHLocationSubscriber *locationSubscriber = [[CLHLocationSubscriber alloc] init];
[locationSubscriber startLiveTrackingWithHandler:^(CLLocation *location) {
	//do something with the location
}];
```
Pausing, resuming, and stopping live tracking:
```objective-c
[locationSubscriber pauseLiveTracking];
[locationSubscriber resumeLiveTracking];
[locationSubscriber stopLiveTracking];
```

###Error-handling
```objective-c
CLHLocationSubscriber *locationSubscriber = [[CLHLocationSubscriber alloc] init];
[locationSubscriber setErrorHandler:^(NSError *error) {
	//do something with the error
}];
```
(You'll only get a callback with errors if that instance of the subscriber is currently registered for any GPS modes.)

##Advanced Usage
GPSKit is customizable for parameters like the polling interval or desired accuracy. The ``CLHCoreLocationManager`` class exposes these options as properties and are globablly used. GPSKit also broadcasts key events through NSNotificationCenter. See ``CLHCoreLocationManager`` for all of the available notifications.

If you need to override the CLLocationManager that GPSKit should use you can also do that through the ``CLHCoreLocationManager``. This is mostly useful if you're providing your own implementation, such as one that would use GPX files to power the locations vs live GPS.

###License
GPSKit is available under the MIT license. See the LICENSE file for more info.