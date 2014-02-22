//
//  CLHLocationSubscriber.h
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
#import "CLHCoreLocationManager.h"

/**
 *  Use this class in place of Apple's CoreLocationManager. Provides convenient block-based methods and 
 *  abstracts boilerplate logic into three "subscription modes".
 *
 *  When going through this class the system will also pay attention to background/foreground transitions
 *  of the app and make sure CoreLocation is appropriatly shut down when needed.
 */
@interface CLHLocationSubscriber : NSObject

/**
 *  Most recent location reported by the system. Here for KVO goodness.
 */
@property (readonly) CLLocation *currentLocation;
/**
 *  Most recent signal strength reported by the system. Here for KVO goodness.
 */
@property (readonly) CLHGPSKitSignalStrength currentStrength;

/**
 *  Tells the system to start polling for GPS signal strength updates by requesting the current location
 *  on a timer. Will continue to poll until stopped. Polling also becomes disabled automatically
 *  if live tracking is also enabled, the system falls back to just reporting strength based on those
 *  live locations.
 *
 *  @param handler callback for when a new signal strength comes in.
 */
- (void)startSignalMonitoringWithHandler:(void (^)(CLHGPSKitSignalStrength strength))handler;
/**
 *  Cancels signal monitoring.
 */
- (void)stopSignalMonitoring;

/**
 *  Gets the user's current location and then ends GPS lookup. Uses the 'desiredAccuracy' value on the CoreLocationManager
 *  (which is same as on a normal CoreLocationManager object) to determine when the reported location is accurate enough 
 *  to be considered "done".
 *
 *  (GPS can take a few seconds to resolve, so you may get a location back immediatly with an accuracy of +/- 500 meters, and
 *  then get one of +/- 10 meters a few seconds later. Higher the accuracy requirement, the slower the initial lookup.)
 *
 *  @param inProgressHandler Callback to handle location reported back while actual location is resolved.
 *  @param completionHandler Callback made when location is determined to be accurate enough to be considered done.
 */
- (void)resolveCurrentLocationWithInProgressHandler:(void (^)(CLLocation *location))inProgressHandler andCompletionHandler:(void (^)(CLLocation *location))completionHandler;
/**
 *  Cancels any pending lookup requests.
 */
- (void)cancelResolvingCurrentLocation;

/**
 *  Gets a constant stream of new locations as the user moves.
 *
 *  Implemention notes: auto pausing of GPS by iOS is turned off for this (I'm assuming this is for activty tracking where pausing
 *  recording automatically would be bad).
 *
 *  @param handler Callback for new locations.
 */
- (void)startLiveTrackingWithHandler:(void (^)(CLLocation *location))handler;
/**
 *  Resumes live tracking.
 */
- (void)resumeLiveTracking;
/**
 *  Pauses live tracking.
 */
- (void)pauseLiveTracking;
/**
 *  Stops live tracking and removes the handler.
 */
- (void)stopLiveTracking;

/**
 *  Forces the system to execute a one-time lookup of the current location. Can be used in any mode to force a new CoreLocation update.
 */
- (void)forceLocationCheck;
/**
 *  Error handler option. Passthrough of CoreLocation errors.
 *
 *  @param handler Callback block to handle errors with.
 */
- (void)setErrorHandler:(void (^)(NSError *error))handler;

@end