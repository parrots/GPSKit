//
//  CLHCoreLocationManager.h
//  GPSKit
//
//  Created by Curtis Herbert on 6/4/13.
//  http://consumedbycode.com/goodies/gpskit
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@import CoreLocation;

/**
 *  Signal strengths that can be reported
 */
typedef NS_ENUM(NSInteger, CLHGPSKitSignalStrength) {
    /**
     *  Reported if no location found yet, or if CoreLocation access is denied by the user.
     */
    CLHGPSKitSignalStrengthNone = 0,
    /**
     *  Poor strength (off by more than 163 meters horizontally)
     */
    CLHGPSKitSignalStrengthPoor = 1,
    /**
     *  Fair strength (off by more than 48 meters horizontally)
     */
    CLHGPSKitSignalStrengthFair = 2,
    /**
     *  Great strength
     */
    CLHGPSKitSignalStrengthGreat = 3
};

/**
 *  Modes the system can operate for (can mix and match more than one at a time)
 */
typedef NS_ENUM(NSInteger, CLHGPSKitSubscriptionMode) {
    /**
     *  Timer-based polling for signal strength.
     */
    CLHGPSKitSubscriptionModeSignalMonitoring = 0,
    /**
     *  One-time location resolution.
     */
    CLHGPSKitSubscriptionModeCurrentLocation = 1,
    /**
     *  Continuous monitoring.
     */
    CLHGPSKitSubscriptionModeLiveTracking = 2
};

NS_ASSUME_NONNULL_BEGIN

/**
 *  Can be used as a value for 'maxLocationAge' to disable time-based filtering.
 */
extern NSTimeInterval const CLHCoreLocationManagerDontValidateLocationAge;

/**
 *  Various notificaitons triggered by the GPSKit system.
 */
extern NSString * const CLHGPSKitNewLocationNotification;
extern NSString * const CLHGPSKitNewStrengthNotification;
extern NSString * const CLHGPSKitLocationResolvedNotification;
extern NSString * const CLHGPSKitErrorNotification;
extern NSString * const CLHGPSKitModeSubscribeNotification;
extern NSString * const CLHGPSKitModeUnsubscribeNotification;

/**
 *  Keys to reference from GPSKit-triggered notifications in the UserInfo dictionary.
 */
extern NSString * const CLHGPSKitNewLocationNotificationNoteKey;
extern NSString * const CLHGPSKitNewStrengthNotificationNoteKey;
extern NSString * const CLHGPSKitChangeModeNotificationNoteKey;
extern NSString * const CLHGPSKitErrorNotificationNoteKey;
extern NSString * const CLHGPSKitLocationResolvedNotificationNoteKey;

/**
 *  The heavy lifting exists here - this class is the one that interfaces with CoreLocation to get GPS data.
 *  Consumers of the SDK shouldn't need to muck with this too much, except for possibly overriding some of the
 *  properties listed below.
 */
@interface CLHCoreLocationManager : NSObject <CLLocationManagerDelegate>

/**
 *  Most recent location reported by the system. Here for KVO goodness.
 */
@property (readonly, nullable) CLLocation *currentLocation;
/**
 *  Most recent signal strength reported by the system. Here for KVO goodness.
 */
@property (readonly) CLHGPSKitSignalStrength currentStrength;
/**
 *  Current authorization status for Core Location.
 */
@property (readonly) CLAuthorizationStatus authorizationStatus;

/**
 *  Time interval at which to re-check signal strength when last-known was healthy. Default to 15.
 */
@property (nonatomic) NSTimeInterval signalPollingHealthyRecheckInterval;
/**
 *  Time interval at which to re-check signal strength when last-known was poor. Default to 3.
 */
@property (nonatomic) NSTimeInterval signalPollingWeakRecheckInterval;
/**
 *  The 'desired accuracy' value to use on the CoreLocationManager in all states but live tracking. Default to kCLLocationAccuracyHundredMeters.
 */
@property (nonatomic) CLLocationAccuracy desiredAccuracy;
/**
 *  The 'desired accuracy' value to use on the CoreLocationManager during live tracking. Default to kCLLocationAccuracyBest.
 */
@property (nonatomic) CLLocationAccuracy desiredAccuracyLiveTracking;
/**
 *  The 'distance filter' to use on the CoreLocationManager in all states. Default to 10.
 */
@property (nonatomic) CLLocationDistance distanceFilter;
/**
 *  Filter out locations reported by the system that are older than this value. Can use 'CLHCoreLocationManagerDontValidateLocationAge' to disable this filtering.
 */
@property (nonatomic) NSTimeInterval maxLocationAge;

/**
 *  Manager for the custom CoreLocation system.
 *
 *  @return singleton
 */
+ (instancetype)sharedManager;
/**
 *  Allows a user to override the CoreLocationManager this system will use. Good for mock managers.
 *
 *  @param locationManager CoreLocationManager to use for GPS lookups.
 */
- (void)useLocationManager:(CLLocationManager *)locationManager;

/**
 *  Tell the system to start working in a specific mode.
 *
 *  @param mode Mode to start.
 */
- (void)subscribeForMode:(CLHGPSKitSubscriptionMode)mode;
/**
 *  Tell the system to stop working in a specific mode.
 *
 *  Note: total requests for a mode are tracked, so only when all unsubscripes are complete will the mode terminate.
 *
 *  @param mode Mode to stop.
 */
- (void)unsubscribeForMode:(CLHGPSKitSubscriptionMode)mode;
/**
 *  Forces the system to execute a one-time lookup of the current location. Can be used in any mode to force a new CoreLocation update.
 */
- (void)forceLocationCheck;

/**
 *  Helper to get a display string for a mode. Mainly useful for logs.
 *
 *  @param mode Mode to look up name for.
 *
 *  @return String representation of a mode.
 */
+ (NSString *)displayNameForMode:(CLHGPSKitSubscriptionMode)mode;
/**
 *  Helper to get a display string for a strength. Mainly useful for logs.
 *
 *  @param strength Strength to look up name for.
 *
 *  @return String representation of a strength.
 */
+ (NSString *)displayNameForStrength:(CLHGPSKitSignalStrength)strength;

@end

NS_ASSUME_NONNULL_END