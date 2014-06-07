//
//  CLHLocationManagerSampleLogger.m
//  GPSKit iOS Example
//
//  Created by Curtis Herbert on 5/9/14.
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
#import "CLHLocationManagerSampleLogger.h"
#import <GPSKit/CLHGPSKit.h>

@interface CLHLocationManagerSampleLogger()

@property (nonatomic) id updatedLocationSubscriptionToken;
@property (nonatomic) id updatedSignalStrengthSubscriptionToken;
@property (nonatomic) id resolvedLocationSubscriptionToken;
@property (nonatomic) id subscribedToModeToken;
@property (nonatomic) id unsubscribedToModeToken;
@property (nonatomic) id errorSubscriptionToken;

@end

@implementation CLHLocationManagerSampleLogger

- (id)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        self.updatedLocationSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitNewLocationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            CLLocation *newLocation = (CLLocation *)note.userInfo[CLHGPSKitNewLocationNotificationNoteKey];
            NSLog(@"New location: %@", newLocation);
        }];
        self.resolvedLocationSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitLocationResolvedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            CLLocation *resolvedLocation = (CLLocation *)note.userInfo[CLHGPSKitLocationResolvedNotificationNoteKey];
            NSLog(@"Resolved location for one-time lookup: %@", resolvedLocation);
        }];
        self.updatedSignalStrengthSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitNewStrengthNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSNumber *newStrengthValue = note.userInfo[CLHGPSKitNewStrengthNotificationNoteKey];
            NSLog(@"New signal strength: %@", [CLHCoreLocationManager displayNameForStrength:[newStrengthValue intValue]]);
        }];
        self.errorSubscriptionToken = [notificationCenter addObserverForName:CLHGPSKitErrorNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSError *error = note.userInfo[CLHGPSKitErrorNotificationNoteKey];
            NSLog(@"Core location error: %@", error);
        }];
        self.subscribedToModeToken = [notificationCenter addObserverForName:CLHGPSKitModeSubscribeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSNumber *mode = note.userInfo[CLHGPSKitChangeModeNotificationNoteKey];
            NSLog(@"Subscribed to mode: %@", [CLHCoreLocationManager displayNameForMode:[mode intValue]]);
        }];
        self.unsubscribedToModeToken = [notificationCenter addObserverForName:CLHGPSKitModeUnsubscribeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSNumber *mode = note.userInfo[CLHGPSKitChangeModeNotificationNoteKey];
            NSLog(@"Unsubscribed for mode: %@", [CLHCoreLocationManager displayNameForMode:[mode intValue]]);
        }];

    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.updatedLocationSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.updatedSignalStrengthSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.resolvedLocationSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.errorSubscriptionToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.subscribedToModeToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.unsubscribedToModeToken];
}

@end
