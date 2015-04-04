//
//  CLHGPSKitTests.m
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
@import Foundation;
@import GPSKit;
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CLHLocationSubscriber_TestMethods.h"

@interface CLHLocationSubscriberTests : XCTestCase

@end

@implementation CLHLocationSubscriberTests

- (void)testSignalMonitoringSubscription
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager expect] subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [[mockManager expect] unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    [subscriber startSignalMonitoringWithHandler:nil];
    [subscriber stopSignalMonitoring];
    
    [mockManager verify];
}

- (void)testLocationLookupRequestSubscription
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager expect] subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[mockManager expect] unsubscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    
    [subscriber resolveCurrentLocationWithInProgressHandler:nil andCompletionHandler:nil];
    [subscriber cancelResolvingCurrentLocation];
    
    [mockManager verify];
}

- (void)testLiveTrackingSubscription
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager expect] subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[mockManager expect] unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    [subscriber startLiveTrackingWithHandler:nil];
    [subscriber stopLiveTracking];
    
    [mockManager verify];
}

- (void)testSignalMonitoringCallback
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    __block CLHGPSKitSignalStrength returnedStrength = CLHGPSKitSignalStrengthNone;
    [subscriber startSignalMonitoringWithHandler:^(CLHGPSKitSignalStrength strength) {
        returnedStrength = strength;
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewStrengthNotification object:nil userInfo:@{ CLHGPSKitNewStrengthNotificationNoteKey: @(CLHGPSKitSignalStrengthGreat)}];
    [subscriber stopSignalMonitoring];
    
    XCTAssertEqual(returnedStrength, CLHGPSKitSignalStrengthGreat, @"Unexpected strength value");
}

- (void)testSignalMonitoringCallbackSilentPostUnsubscribe
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeSignalMonitoring];
    
    __block CLHGPSKitSignalStrength returnedStrength = CLHGPSKitSignalStrengthNone;
    [subscriber startSignalMonitoringWithHandler:^(CLHGPSKitSignalStrength strength) {
        returnedStrength = strength;
    }];
    [subscriber stopSignalMonitoring];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewStrengthNotification object:nil userInfo:@{ CLHGPSKitNewStrengthNotificationNoteKey: @(CLHGPSKitSignalStrengthGreat)}];
    [subscriber stopSignalMonitoring];
    
    XCTAssertEqual(returnedStrength, CLHGPSKitSignalStrengthNone, @"Expected strength value to not be updated");
}

- (void)testLocationLookupRequestInProgressCallback
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    
    CLLocation *inprogressLocation1 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:50 verticalAccuracy:50 timestamp:[NSDate date]];
    CLLocation *inprogressLocation2 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:20 verticalAccuracy:20 timestamp:[NSDate date]];
    CLLocation *completionLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    NSArray *expectedLocations = @[inprogressLocation1, inprogressLocation2, completionLocation];
    __block NSMutableArray* returnedLocations = [[NSMutableArray alloc] init];
    [subscriber resolveCurrentLocationWithInProgressHandler:^(CLLocation *location) {
        [returnedLocations addObject:location];
    } andCompletionHandler:nil];
    for (CLLocation *location in expectedLocations) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location}];
    }
    
    XCTAssert([returnedLocations isEqualToArray:expectedLocations], @"Unexpected in-progress locations");
}

- (void)testLocationLookupRequestCompletionCallback
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    
    CLLocation *expectedCompletionLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    __block CLLocation* returnedLocation;
    [subscriber resolveCurrentLocationWithInProgressHandler:nil andCompletionHandler:^(CLLocation *location) {
        returnedLocation = location;
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitLocationResolvedNotification object:nil userInfo:@{ CLHGPSKitLocationResolvedNotificationNoteKey: expectedCompletionLocation}];
    
    XCTAssertEqual(returnedLocation, expectedCompletionLocation, @"Unexpected completed location");
}

- (void)testLocationLookupRequestUnsubscripePostCompletion
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[mockManager expect] unsubscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    
    CLLocation *expectedCompletionLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    [subscriber resolveCurrentLocationWithInProgressHandler:nil andCompletionHandler:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitLocationResolvedNotification object:nil userInfo:@{ CLHGPSKitLocationResolvedNotificationNoteKey: expectedCompletionLocation}];
    
    [mockManager verify];
}

- (void)testLocationLookupRequestCompletionCallbackSilentPostUnsubscribe
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    
    CLLocation *expectedCompletionLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    __block CLLocation* returnedLocation;
    [subscriber resolveCurrentLocationWithInProgressHandler:nil andCompletionHandler:^(CLLocation *location) {
        returnedLocation = location;
    }];
    [subscriber cancelResolvingCurrentLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitLocationResolvedNotification object:nil userInfo:@{ CLHGPSKitLocationResolvedNotificationNoteKey: expectedCompletionLocation}];
    
    XCTAssertNil(returnedLocation, @"Expected no location to be returned");
}

- (void)testLocationLookupRequestCompletionCallbackNoAccurateLocationFound
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeCurrentLocation];
    
    CLLocation *inprogressLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:50 verticalAccuracy:50 timestamp:[NSDate date]];
    __block CLLocation* returnedLocation;
    [subscriber resolveCurrentLocationWithInProgressHandler:nil andCompletionHandler:^(CLLocation *location) {
        returnedLocation = location;
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: inprogressLocation}];
    
    XCTAssertNotEqual(returnedLocation, inprogressLocation, @"Expected no completion value to be returned");
}

- (void)testLiveTrackingSubscriptionCallback
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    CLLocation *location1 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:50 verticalAccuracy:50 timestamp:[NSDate date]];
    CLLocation *location2 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:20 verticalAccuracy:20 timestamp:[NSDate date]];
    CLLocation *location3 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    NSArray *expectedLocations = @[location1, location2, location3];
    __block NSMutableArray* returnedLocations = [[NSMutableArray alloc] init];
    [subscriber startLiveTrackingWithHandler:^(CLLocation *location) {
        [returnedLocations addObject:location];
    }];
    
    for (CLLocation *location in expectedLocations) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location}];
    }
    
    XCTAssert([returnedLocations isEqualToArray:expectedLocations], @"Unexpected locations");
}

- (void)testLiveTrackingSubscriptionCallbackPauseResume
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    CLLocation *location1 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:50 verticalAccuracy:50 timestamp:[NSDate date]];
    CLLocation *location2 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:20 verticalAccuracy:20 timestamp:[NSDate date]];
    CLLocation *location3 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    
    __block NSMutableArray* returnedLocations = [[NSMutableArray alloc] init];
    [subscriber startLiveTrackingWithHandler:^(CLLocation *location) {
        [returnedLocations addObject:location];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location1}];
    [subscriber pauseLiveTracking];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location2}];
    [subscriber resumeLiveTracking];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location3}];
    
    NSArray *expectedLocation = @[location1, location3];
    XCTAssert([returnedLocations isEqualToArray:expectedLocation], @"Received more locations than expected");
}

- (void)testLiveTrackingSubscriptionCallbackSilentPostUnsubscribe
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    CLLocation *location1 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:50 verticalAccuracy:50 timestamp:[NSDate date]];
    CLLocation *location2 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:20 verticalAccuracy:20 timestamp:[NSDate date]];
    CLLocation *location3 = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
    
    __block NSMutableArray* returnedLocations = [[NSMutableArray alloc] init];
    [subscriber startLiveTrackingWithHandler:^(CLLocation *location) {
        [returnedLocations addObject:location];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location1}];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location2}];
    [subscriber stopLiveTracking];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitNewLocationNotification object:nil userInfo:@{ CLHGPSKitNewLocationNotificationNoteKey: location3}];
    
    NSArray *expectedLocation = @[location1, location2];
    XCTAssert([returnedLocations isEqualToArray:expectedLocation], @"Received more locations than expected");
}

- (void)testErrorCallback
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    NSError *expectedError = [NSError errorWithDomain:@"Test" code:1 userInfo:nil];
    __block NSError* returnedError = nil;
    [subscriber setErrorHandler:^(NSError *error) {
        returnedError = error;
    }];
    [subscriber startLiveTrackingWithHandler:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitErrorNotification object:nil userInfo:@{ CLHGPSKitErrorNotificationNoteKey: expectedError}];
    
    XCTAssertEqual(returnedError, expectedError, @"Unexpected error returned");
}

- (void)testErrorCallbackSilentWithNoSubscriptions
{
    id mockManager = [OCMockObject mockForClass:[CLHCoreLocationManager class]];
    CLHLocationSubscriber *subscriber = [[CLHLocationSubscriber alloc] initWithManager:mockManager];
    [[mockManager stub] subscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    [[mockManager stub] unsubscribeForMode:CLHGPSKitSubscriptionModeLiveTracking];
    
    NSError *expectedError = [NSError errorWithDomain:@"Test" code:1 userInfo:nil];
    __block NSError* returnedError = nil;
    [subscriber setErrorHandler:^(NSError *error) {
        returnedError = error;
    }];
    [subscriber startLiveTrackingWithHandler:nil];
    [subscriber stopLiveTracking];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CLHGPSKitErrorNotification object:nil userInfo:@{ CLHGPSKitErrorNotification: expectedError}];
    
    XCTAssertNil(returnedError, @"Expected no error to be returned");
}

@end