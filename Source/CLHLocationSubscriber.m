//
//  CLHLocationSubscriber.m
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

#import "CLHLocationSubscriber.h"

@interface CLHLocationSubscriber()

@property (nonatomic) CLHCoreLocationManager *coreLocationManager;
@property (nonatomic) NSMutableArray *subscribedModes;

@property (copy) void (^signalHandler)(CLHGPSKitSignalStrength);
@property (copy) void (^currentLocationResolvingHandler)(CLLocation *);
@property (copy) void (^currentLocationCompletionHandler)(CLLocation *);
@property (copy) void (^liveLocationHandler)(CLLocation *);
@property (copy) void (^errorHandler)(NSError *);

@property (nonatomic) id updatedLocationSubscriptionToken;
@property (nonatomic) id updatedSignalStrengthSubscriptionToken;
@property (nonatomic) id resolvedLocationSubscriptionToken;
@property (nonatomic) id errorSubscriptionToken;

@end

@implementation CLHLocationSubscriber

- (id)init
{
    return [self initWithManager:[CLHCoreLocationManager sharedManager]];
}

- (id)initWithManager:(CLHCoreLocationManager *)manager
{
    self = [super init];
    if (self) {
        self.subscribedModes = [[NSMutableArray alloc] init];
        self.coreLocationManager = manager;
        
        [self setupLocationEventMonitoring];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.updatedLocationSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.updatedSignalStrengthSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.resolvedLocationSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.errorSubscriptionToken];
    
    NSArray *currentModes = [self.subscribedModes copy];
    for (NSNumber *mode in currentModes) {
        [self disableMode:[mode intValue]];
    }
}

- (void)setupLocationEventMonitoring
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    __weak typeof(self) weakSelf = self;
    self.updatedLocationSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitNewLocationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CLLocation *newLocation = (CLLocation *)note.userInfo[CLHGPSKitNewLocationNotificationNoteKey];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (newLocation && strongSelf) {
            [strongSelf willChangeValueForKey:NSStringFromSelector(@selector(currentLocation))];
            [strongSelf didChangeValueForKey:NSStringFromSelector(@selector(currentLocation))];
            if (strongSelf.currentLocationResolvingHandler) {
                strongSelf.currentLocationResolvingHandler(newLocation);
            }
            if (strongSelf.liveLocationHandler && [strongSelf.subscribedModes containsObject:@(CLHGPSKitSubscriptionModeLiveTracking)]) {
                strongSelf.liveLocationHandler(newLocation);
            }
        }
    }];
    self.resolvedLocationSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitLocationResolvedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CLLocation *resolvedLocation = (CLLocation *)note.userInfo[CLHGPSKitLocationResolvedNotificationNoteKey];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && resolvedLocation && [strongSelf.subscribedModes containsObject:@(CLHGPSKitSubscriptionModeCurrentLocation)]) {
            if (strongSelf.currentLocationCompletionHandler) {
                strongSelf.currentLocationCompletionHandler(resolvedLocation);
            }
            [strongSelf cancelResolvingCurrentLocation];
        }
    }];
    self.updatedSignalStrengthSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitNewStrengthNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *newStrengthValue = note.userInfo[CLHGPSKitNewStrengthNotificationNoteKey];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (newStrengthValue && strongSelf) {
            CLHGPSKitSignalStrength newStrength = [newStrengthValue intValue];
            [strongSelf willChangeValueForKey:NSStringFromSelector(@selector(currentStrength))];
            [strongSelf didChangeValueForKey:NSStringFromSelector(@selector(currentStrength))];
            if (strongSelf.signalHandler) {
                strongSelf.signalHandler(newStrength);
            }
        }
    }];
    self.errorSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitErrorNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            NSError *error = note.userInfo[CLHGPSKitErrorNotificationNoteKey];
            if ([strongSelf.subscribedModes count] > 0 && strongSelf.errorHandler) {
                strongSelf.errorHandler(error);
            }
        }
    }];
}

#pragma mark - Current GPS state

- (CLLocation * _Nullable)currentLocation
{
    return self.coreLocationManager.currentLocation;
}

- (CLHGPSKitSignalStrength)currentStrength
{
    return self.coreLocationManager.currentStrength;
}

- (CLAuthorizationStatus)authorizationStatus
{
    return self.coreLocationManager.authorizationStatus;
}

#pragma mark - GPS mode subscription options

- (void)startSignalMonitoringWithHandler:(void (^)(CLHGPSKitSignalStrength))handler
{
    self.signalHandler = handler;
    [self enableMode:CLHGPSKitSubscriptionModeSignalMonitoring];
}

- (void)stopSignalMonitoring
{
    self.signalHandler = nil;
    [self disableMode:CLHGPSKitSubscriptionModeSignalMonitoring];
}

- (void)resolveCurrentLocationWithInProgressHandler:(void (^)(CLLocation *))inProgressHandler andCompletionHandler:(void (^)(CLLocation *))completionHandler
{
    self.currentLocationResolvingHandler = inProgressHandler;
    self.currentLocationCompletionHandler = completionHandler;
    [self enableMode:CLHGPSKitSubscriptionModeCurrentLocation];
}

- (void)cancelResolvingCurrentLocation
{
    self.currentLocationResolvingHandler = nil;
    self.currentLocationCompletionHandler = nil;
    [self disableMode:CLHGPSKitSubscriptionModeCurrentLocation];
}

- (void)startLiveTrackingWithHandler:(void (^)(CLLocation *))handler
{
    self.liveLocationHandler = handler;
    [self enableMode:CLHGPSKitSubscriptionModeLiveTracking];
}

- (void)resumeLiveTracking
{
    if (!self.liveLocationHandler) {
        NSLog(@"Warning: trying to resume live tracking when no handler was defined.");
    }
    [self enableMode:CLHGPSKitSubscriptionModeLiveTracking];
}

- (void)pauseLiveTracking
{
    [self disableMode:CLHGPSKitSubscriptionModeLiveTracking];
}

- (void)stopLiveTracking
{
    self.liveLocationHandler = nil;
    [self disableMode:CLHGPSKitSubscriptionModeLiveTracking];
}

#pragma mark - Mode management

- (void)enableMode:(CLHGPSKitSubscriptionMode)mode
{
    if (![self.subscribedModes containsObject:@(mode)]) {
        [self.subscribedModes addObject:@(mode)];
        [self.coreLocationManager subscribeForMode:mode];
    }
}

- (void)disableMode:(CLHGPSKitSubscriptionMode)mode
{
    if ([self.subscribedModes containsObject:@(mode)]) {
        [self.subscribedModes removeObject:@(mode)];
        [self.coreLocationManager unsubscribeForMode:mode];
    }
}

- (void)forceLocationCheck
{
    [self.coreLocationManager forceLocationCheck];
}

@end
