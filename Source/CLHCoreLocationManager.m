//
//  CLHCoreLocationManager.m
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

@import UIKit;
#import "CLHCoreLocationManager.h"

NSString * const CLHGPSKitNewLocationNotification = @"com.curtisherbert.gpskit.newlocation";
NSString * const CLHGPSKitNewStrengthNotification = @"com.curtisherbert.gpskit.newstrength";
NSString * const CLHGPSKitLocationResolvedNotification = @"com.curtisherbert.gpskit.locationresolved";
NSString * const CLHGPSKitErrorNotification = @"com.curtisherbert.gpskit.error";
NSString * const CLHGPSKitModeSubscribeNotification = @"com.curtisherbert.gpskit.modesubscribe";
NSString * const CLHGPSKitModeUnsubscribeNotification = @"com.curtisherbert.gpskit.modeunsubscribe";

NSString * const CLHGPSKitNewLocationNotificationNoteKey = @"location";
NSString * const CLHGPSKitLocationResolvedNotificationNoteKey = @"resolvedlocation";
NSString * const CLHGPSKitNewStrengthNotificationNoteKey = @"strength";
NSString * const CLHGPSKitChangeModeNotificationNoteKey = @"mode";
NSString * const CLHGPSKitErrorNotificationNoteKey = @"error";

@interface CLHCoreLocationManager()

@property CLLocationManager *locationManager;
@property NSMutableArray *requestedModes;
@property BOOL isTracking;
@property id backgroundSubscriptionToken;
@property id foregroundSubscriptionToken;

@property CLLocation *currentLocation;
@property CLHGPSKitSignalStrength currentStrength;

@end

@implementation CLHCoreLocationManager

@synthesize currentLocation = _currentLocation;
@synthesize currentStrength = _currentStrength;

const NSTimeInterval CLHCoreLocationManagerDontValidateLocationAge = -1;

static CLHCoreLocationManager *CLHLocationManagerSharedInstance = nil;

+ (CLHCoreLocationManager *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!CLHLocationManagerSharedInstance) {
            CLHLocationManagerSharedInstance = [[CLHCoreLocationManager alloc] init];
        }
    });
    
    return CLHLocationManagerSharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.distanceFilter = 10.0;
        self.maxLocationAge = 5.0 * 60.0;
        self.signalPollingHealthyRecheckInterval = 15;
        self.signalPollingWeakRecheckInterval = 3;
        self.desiredAccuracyLiveTracking = kCLLocationAccuracyBest;
        self.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        
        self.requestedModes = [[NSMutableArray alloc] initWithObjects:@(0), @(0), @(0), nil];
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(requestedModes)) options:NSKeyValueObservingOptionNew context:nil];
        
        __weak typeof(self) weakSelf = self;
        self.backgroundSubscriptionToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                if (![strongSelf isInMode:CLHGPSKitSubscriptionModeLiveTracking]) {
                    [strongSelf.locationManager stopUpdatingLocation];
                }
                [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf selector:@selector(forceLocationCheck) object:nil];
            }
        }];
        
        self.foregroundSubscriptionToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                if (![strongSelf isInMode:CLHGPSKitSubscriptionModeLiveTracking] && ([strongSelf isInMode:CLHGPSKitSubscriptionModeCurrentLocation] || [strongSelf isInMode:CLHGPSKitSubscriptionModeSignalMonitoring])) {
                    [strongSelf forceLocationCheck];
                }
            }
        }];
        
        self.currentStrength = CLHGPSKitSignalStrengthNone;
        self.currentLocation = nil;
    }
    return self;
}

- (void)dealloc
{
    [self.locationManager setDelegate:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.foregroundSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.backgroundSubscriptionToken];
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(requestedModes)) context:nil];
}

- (void)useLocationManager:(CLLocationManager *)locationManager
{
    [self.locationManager stopUpdatingLocation];
    [self.locationManager setDelegate:nil];
    
    self.locationManager = locationManager;
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = self.distanceFilter;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.activityType = CLActivityTypeFitness;
}

#pragma mark - Mode tracking

- (void)subscribeForMode:(CLHGPSKitSubscriptionMode)mode
{
    //we want to lazy-load the location manager if we can so users don't get a pop-up asking for permission
    //until the app is actually trying to do something
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!self.locationManager) {
            [self useLocationManager:[[CLLocationManager alloc] init]];
        }
    });
    
    [self updateSubscriberCountForMode:mode incrementBy:1];
}

- (void)unsubscribeForMode:(CLHGPSKitSubscriptionMode)mode
{
    NSInteger currentModeValue = [self.requestedModes[mode] integerValue];
    NSAssert(currentModeValue > 0, @"Trying to stop mode %@ one too many times", [CLHCoreLocationManager displayNameForMode:mode]);
    
    [self updateSubscriberCountForMode:mode incrementBy:-1];
}

- (void)updateSubscriberCountForMode:(CLHGPSKitSubscriptionMode)mode incrementBy:(NSInteger)count
{
    NSInteger currentModeValue = [self.requestedModes[mode] integerValue];
    NSIndexSet *modeIndex = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(mode, 1)];
    NSString *requestedModeSelectorString = NSStringFromSelector(@selector(requestedModes));
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:modeIndex forKey:requestedModeSelectorString];
    self.requestedModes[mode] = @(currentModeValue + count);
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:modeIndex forKey:requestedModeSelectorString];
    
    if (count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitModeSubscribeNotification object:nil userInfo:@{CLHGPSKitChangeModeNotificationNoteKey : @(mode)}];
    } else if (count < 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitModeUnsubscribeNotification object:nil userInfo:@{CLHGPSKitChangeModeNotificationNoteKey : @(mode)}];
    }
}

- (void)forceLocationCheck
{
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Current GPS status properties

- (CLHGPSKitSignalStrength)currentStrength
{
    return _currentStrength;
}

- (void)setCurrentStrength:(CLHGPSKitSignalStrength)currentStrength
{
    if (currentStrength != _currentStrength) {
        _currentStrength = currentStrength;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewStrengthNotification object:nil userInfo:@{CLHGPSKitNewStrengthNotificationNoteKey : @(currentStrength)}];
    }
}

- (CLLocation *)currentLocation
{
    if (![self isLocationFresh:_currentLocation]) {
        return nil;
    }
    return _currentLocation;
}

- (void)setCurrentLocation:(CLLocation *)currentLocation
{
    if (currentLocation != _currentLocation) {
        _currentLocation = currentLocation;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{CLHGPSKitNewLocationNotificationNoteKey : currentLocation}];
    }
}

# pragma mark - Location manager delegates

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceLocationCheck) object:nil];
    
    BOOL needForcedCheck = NO;
    for (CLLocation *newLocation in locations) {
        //check to see if we are dealing with cached old location, spam startUpdating to get an update quicker if we are
        if (![self isLocationFresh:newLocation]) {
            needForcedCheck = YES;
            continue;
        }
        
        self.currentStrength = [CLHCoreLocationManager strengthFromLocation:newLocation];
        
        //we only want to track locations and strengths when they are coming from a new location
        if ((!self.currentLocation || [newLocation.timestamp timeIntervalSinceDate:self.currentLocation.timestamp] > 0) &&
            self.currentStrength > CLHGPSKitSignalStrengthNone) {
            self.currentLocation = newLocation;
        }
        
        needForcedCheck = NO;
    }
    
    if (needForcedCheck) {
        [self forceLocationCheck];
        return;
    }
    
    //if we aren't activly tracking location, we might be able to shut down the GPS chip
    //check to see if we've satisfied current requests and schedule future polling as needed
    if (![self isInMode:CLHGPSKitSubscriptionModeLiveTracking]) {
        BOOL currentLocationIsAccurateEnough = self.currentLocation && self.currentLocation.horizontalAccuracy <= self.desiredAccuracy && self.currentLocation.horizontalAccuracy >= 0.0f;
        if ([self isInMode:CLHGPSKitSubscriptionModeCurrentLocation] && currentLocationIsAccurateEnough) {
            [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitLocationResolvedNotification object:nil userInfo:@{CLHGPSKitLocationResolvedNotificationNoteKey : self.currentLocation}];
            
        } else if (![self isInMode:CLHGPSKitSubscriptionModeCurrentLocation]) {
            [self.locationManager stopUpdatingLocation];
        }
        
        if ([self isInMode:CLHGPSKitSubscriptionModeSignalMonitoring]) {
            NSTimeInterval recheckInterval = (self.currentStrength > CLHGPSKitSignalStrengthPoor) ? self.signalPollingHealthyRecheckInterval : self.signalPollingWeakRecheckInterval;
            [self performSelector:@selector(forceLocationCheck) withObject:nil afterDelay:recheckInterval];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.currentStrength = CLHGPSKitSignalStrengthNone;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitErrorNotification object:nil userInfo:@{CLHGPSKitErrorNotificationNoteKey : error}];
}

#pragma mark - Helpers

+ (CLHGPSKitSignalStrength)strengthFromLocation:(CLLocation *)location;
{
    CLHGPSKitSignalStrength strength = CLHGPSKitSignalStrengthNone;
    if (location.horizontalAccuracy < 0) {
        strength = CLHGPSKitSignalStrengthNone;
    } else if (location.horizontalAccuracy > 163) {
        strength = CLHGPSKitSignalStrengthPoor;
    } else if (location.horizontalAccuracy > 48) {
        strength = CLHGPSKitSignalStrengthFair;
    } else {
        strength = CLHGPSKitSignalStrengthGreat;
    }
    
    return strength;
}

+ (NSString*)displayNameForMode:(CLHGPSKitSubscriptionMode)mode
{
    NSString *result = nil;
    
    switch(mode) {
        case CLHGPSKitSubscriptionModeSignalMonitoring:
            result = @"Signal Monitoring";
            break;
        case CLHGPSKitSubscriptionModeCurrentLocation:
            result = @"Current Location";
            break;
        case CLHGPSKitSubscriptionModeLiveTracking:
            result = @"Live Tracking";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected LocationManagerMode"];
    }
    
    return result;
}

+ (NSString*)displayNameForStrength:(CLHGPSKitSignalStrength)strength
{
    NSString *result = nil;
    
    switch(strength) {
        case CLHGPSKitSignalStrengthNone:
            result = @"None";
            break;
        case CLHGPSKitSignalStrengthPoor:
            result = @"Poor";
            break;
        case CLHGPSKitSignalStrengthFair:
            result = @"Fair";
            break;
        case CLHGPSKitSignalStrengthGreat:
            result = @"Great";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected GPSSignalStrength"];
    }
    
    return result;
}

#pragma mark - Misc

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(requestedModes))]) {
        //only require the best accuracy if we're in tracking mode, otherwise approximates will do
        if ([self isInMode:CLHGPSKitSubscriptionModeLiveTracking]) {
            self.locationManager.desiredAccuracy = self.desiredAccuracyLiveTracking;
        } else {
            self.locationManager.desiredAccuracy = self.desiredAccuracy;
        }
        
        BOOL shouldBeTracking = [[self.requestedModes valueForKeyPath:@"@max.self"] integerValue] > 0;
        if (shouldBeTracking && !self.isTracking) {
            self.isTracking = YES;
            [self.locationManager startUpdatingLocation];
        } else if (!shouldBeTracking && self.isTracking) {
            self.isTracking = NO;
            [self.locationManager stopUpdatingLocation];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceLocationCheck) object:nil];
        }
    
        //if we're moving up to a activty tracking, cancel any previous timed refreshes and make sure things are moving along
        NSUInteger changedTo = [change[NSKeyValueChangeNewKey][0] integerValue];
        NSUInteger changeMode = ((NSIndexSet *)change[NSKeyValueChangeIndexesKey]).firstIndex;
        if (changedTo == 1 && changeMode == CLHGPSKitSubscriptionModeLiveTracking) {
            [self.locationManager startUpdatingLocation];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceLocationCheck) object:nil];
        }
    }
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter
{
    _distanceFilter = distanceFilter;
    [self.locationManager setDistanceFilter:_distanceFilter];
}

- (BOOL)isInMode:(CLHGPSKitSubscriptionMode)mode
{
    return [self.requestedModes[mode] integerValue] > 0;
}

- (BOOL)isLocationFresh:(CLLocation *)location
{
    return self.maxLocationAge == CLHCoreLocationManagerDontValidateLocationAge || abs([location.timestamp timeIntervalSinceNow]) <= self.maxLocationAge;
}

@end
