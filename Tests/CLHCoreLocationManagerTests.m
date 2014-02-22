//
//  CLHCoreLocationManagerTests.m
//  GPSKit
//
//  Created by Curtis Herbert on 2/22/14.
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
@import UIKit;
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CLHCoreLocationManager_TestMethods.h"

@interface CLHCoreLocationManagerTests : XCTestCase

@end

@implementation CLHCoreLocationManagerTests

- (void)testSubscribeForMode
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    XCTAssertTrue([manager isInMode:CLHGPSKitSubscriptionModeSignalMonitoring], @"Expected to be subscribed to mode");
}

- (void)testSubscribeForModeNotification
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    id mockNotificationWatcher = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mockNotificationWatcher name:CLHGPSKitModeSubscribeNotification object:nil];
    [[mockNotificationWatcher expect] notificationWithName:CLHGPSKitModeSubscribeNotification object:[OCMArg any] userInfo:[OCMArg any]];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    [mockNotificationWatcher verify];
    [[NSNotificationCenter defaultCenter] removeObserver:mockNotificationWatcher];
}

- (void)testUnsubscribeForModeNotification
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    id mockNotificationWatcher = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mockNotificationWatcher name:CLHGPSKitModeUnsubscribeNotification object:nil];
    [[mockNotificationWatcher expect] notificationWithName:CLHGPSKitModeUnsubscribeNotification object:[OCMArg any] userInfo:[OCMArg any]];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [manager unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    [mockNotificationWatcher verify];
    [[NSNotificationCenter defaultCenter] removeObserver:mockNotificationWatcher];
}

- (void)testSubscribeForModeMultipleSources
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [manager unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    XCTAssertTrue([manager isInMode:CLHGPSKitSubscriptionModeSignalMonitoring], @"Expected to be subscribed to mode");
}

- (void)testGPSShutdownDuringSignalForBackgroundTransition
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager stub] startUpdatingLocation];
    [[clManager expect] stopUpdatingLocation];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [clManager verify];
}

- (void)testGPSShutdownDuringSignalAfterGoodLocation
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager stub] startUpdatingLocation];
    [[clManager expect] stopUpdatingLocation];
    [manager useLocationManager:clManager];
    
    CLLocation *finalLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate date]];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [manager locationManager:clManager didUpdateLocations:@[finalLocation]];
    
    [clManager verify];
}

- (void)testGPSResumeDuringSignalForForgroundTransition
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] startUpdatingLocation];
    [[clManager expect] startUpdatingLocation];
    [[clManager stub] stopUpdatingLocation];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    
    [clManager verify];
}

- (void)testGPSShutdownDuringCurrentLocationRequestForBackgroundTransition
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager stub] startUpdatingLocation];
    [[clManager expect] stopUpdatingLocation];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [clManager verify];
}

- (void)testGPSResumeDuringCurrentLocationRequestForForgroundTransition
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] startUpdatingLocation];
    [[clManager expect] startUpdatingLocation];
    [[clManager stub] stopUpdatingLocation];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    
    [clManager verify];
}

- (void)testGPSActiveDuringLiveModeForBackgroundTransition
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] startUpdatingLocation];
    [[clManager reject] stopUpdatingLocation];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [clManager verify];
}

- (void)testUnsubscribeForMode
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [manager unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    XCTAssertTrue(![manager isInMode:CLHGPSKitSubscriptionModeSignalMonitoring], @"Expected to be unsubscribed to mode");
}

- (void)testExcessiveUnsubscribeForMode
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    XCTAssertThrows([manager unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring], @"Expected exception for double unsubscribe");
}

- (void)testResolvedLocationNotification
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    
    CLLocation *finalLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate date]];
    
    id mockNotificationWatcher = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mockNotificationWatcher name:CLHGPSKitLocationResolvedNotification object:nil];
    [[mockNotificationWatcher expect] notificationWithName:CLHGPSKitLocationResolvedNotification object:[OCMArg any] userInfo:@{CLHGPSKitLocationResolvedNotificationNoteKey: finalLocation}];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [manager locationManager:clManager didUpdateLocations:@[finalLocation]];
    
    [mockNotificationWatcher verify];
    [[NSNotificationCenter defaultCenter] removeObserver:mockNotificationWatcher];
}

- (void)testNewLocationNotification
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate date]];
    
    id mockNotificationWatcher = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mockNotificationWatcher name:CLHGPSKitNewLocationNotification object:nil];
    [[mockNotificationWatcher expect] notificationWithName:CLHGPSKitNewLocationNotification object:[OCMArg any] userInfo:@{CLHGPSKitNewLocationNotificationNoteKey: location}];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    
    [mockNotificationWatcher verify];
    [[NSNotificationCenter defaultCenter] removeObserver:mockNotificationWatcher];
}

- (void)testErrorNotification
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    
    NSError *error = [NSError errorWithDomain:@"Test" code:1 userInfo:nil];
    
    id mockNotificationWatcher = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mockNotificationWatcher name:CLHGPSKitErrorNotification object:nil];
    [[mockNotificationWatcher expect] notificationWithName:CLHGPSKitErrorNotification object:[OCMArg any] userInfo:@{CLHGPSKitErrorNotificationNoteKey: error}];
    
    [manager locationManager:clManager didFailWithError:error];
    
    [mockNotificationWatcher verify];
    [[NSNotificationCenter defaultCenter] removeObserver:mockNotificationWatcher];
}

- (void)testNewStrengthNotification
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate date]];
    CLHGPSKitSignalStrength strength = CLHGPSKitSignalStrengthGreat;
    
    id mockNotificationWatcher = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mockNotificationWatcher name:CLHGPSKitNewStrengthNotification object:nil];
    [[mockNotificationWatcher expect] notificationWithName:CLHGPSKitNewStrengthNotification object:[OCMArg any] userInfo:@{CLHGPSKitNewStrengthNotificationNoteKey: @(strength)}];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    
    [mockNotificationWatcher verify];
    [[NSNotificationCenter defaultCenter] removeObserver:mockNotificationWatcher];
}

- (void)testDistanceFilterInit
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] setDistanceFilter:manager.distanceFilter];
    [manager useLocationManager:clManager];
    
    [clManager verify];
}

- (void)testDistanceFilterPassthrough
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] setDistanceFilter:manager.distanceFilter];
    [[clManager expect] setDistanceFilter:15];
    [manager useLocationManager:clManager];
    manager.distanceFilter = 15;
    
    [clManager verify];
}

- (void)testDesiredAccuracyActive
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracy];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    [clManager verify];
}

- (void)testDesiredAccuracyNonActive
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracyLiveTracking];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    [clManager verify];
}

- (void)testDesiredAccuracyUpgrade
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracy];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracyLiveTracking];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    [clManager verify];
}

- (void)testDesiredAccuracyDowngrade
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracy];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracyLiveTracking];
    [[clManager expect] setDesiredAccuracy:manager.desiredAccuracy];
    [manager useLocationManager:clManager];
    
    [manager subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [manager subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [manager unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    [clManager verify];
}

- (void)testFreshnessValidation
{
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    XCTAssertTrue([manager isLocationFresh:location], @"Expected location to be considered fresh");
}

- (void)testFreshnessValidationFails
{
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSinceNow:0 - manager.maxLocationAge - 1]];
    
    XCTAssertTrue(![manager isLocationFresh:location], @"Expected location to not be considered fresh");
}

- (void)testFreshnessValidationIgnored
{
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    manager.maxLocationAge = CLHCoreLocationManagerDontValidateLocationAge;
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSinceNow:0 - manager.maxLocationAge - 1]];
    
    XCTAssertTrue([manager isLocationFresh:location], @"Expected location to be considered fresh");
}

- (void)testGPSSpamOnExpiredLocations
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager expect] startUpdatingLocation];
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSinceNow:0 - manager.maxLocationAge - 1]];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    
    [clManager verify];
}

- (void)testGPSNotSpamedOnExpiredLocationsAndCurrentLocations
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [[clManager reject] startUpdatingLocation];
    [manager useLocationManager:clManager];
    
    CLLocation *oldLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSinceNow:0 - manager.maxLocationAge - 1]];
    CLLocation *newLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSinceNow:0 - manager.maxLocationAge + 1]];
    
    [manager locationManager:clManager didUpdateLocations:@[oldLocation, newLocation]];
    
    [clManager verify];
}

- (void)testLocationUpdated
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate date]];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    
    XCTAssertEqual(manager.currentLocation, location, @"Expected location to be updated");
}

- (void)testIgnoreOldLocations
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    manager.maxLocationAge = CLHCoreLocationManagerDontValidateLocationAge;
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSince1970:10]];
    CLLocation *oldLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSince1970:8]];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    [manager locationManager:clManager didUpdateLocations:@[oldLocation]];
    
    XCTAssertEqual(manager.currentLocation, location, @"Expected older location to be ignored");
}

- (void)testIgnoreInvalidLocations
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    manager.maxLocationAge = CLHCoreLocationManagerDontValidateLocationAge;
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSince1970:10]];
    CLLocation *invalidLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:-1 verticalAccuracy:10 timestamp:[NSDate dateWithTimeIntervalSince1970:8]];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    [manager locationManager:clManager didUpdateLocations:@[invalidLocation]];
    
    XCTAssertEqual(manager.currentLocation, location, @"Expected invalid location to be ignored");
}

- (void)testStrengthUpdates
{
    id clManager = [OCMockObject niceMockForClass:[CLLocationManager class]];
    CLHCoreLocationManager *manager = [[CLHCoreLocationManager alloc] init];
    [manager useLocationManager:clManager];
    
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:0 verticalAccuracy:10 timestamp:[NSDate date]];
    
    [manager locationManager:clManager didUpdateLocations:@[location]];
    
    XCTAssertEqual(manager.currentStrength, CLHGPSKitSignalStrengthGreat, @"Expected strength to be updated");
}

@end
