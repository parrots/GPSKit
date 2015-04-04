//
//  LiveTrackingViewController.m
//  GPSKit iOS Example
//
//  Created by Curtis Herbert on 5/10/14.
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

@import GPSKit;
#import "LiveTrackingViewController.h"

@interface LiveTrackingViewController () <UIAlertViewDelegate>

@property (nonatomic) CLHLocationSubscriber *locationSubscriber;
@property BOOL isTracking;
@property (nonatomic) NSMutableArray *trackedPoints;

@end

@implementation LiveTrackingViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.isTracking = NO;
        self.trackedPoints = [[NSMutableArray alloc] init];
        self.locationSubscriber = [[CLHLocationSubscriber alloc] init];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateTitleWithStength:self.locationSubscriber.currentStrength];
    
    [self.locationSubscriber setErrorHandler:^(NSError *error) {
#if (TARGET_IPHONE_SIMULATOR)
        if (error.code == 0) {
            UIAlertView *helpfulAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Got error code 0. Did you set a simulated location for the simulator under the Debug -> Location menu?" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [helpfulAlert show];
        } else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [errorAlert show];
        }
#else
        
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [errorAlert show];
#endif
    }];
    
    __weak typeof(self) weakSelf = self;
    [self.locationSubscriber startSignalMonitoringWithHandler:^(CLHGPSKitSignalStrength strength) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updateTitleWithStength:strength];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.locationSubscriber stopSignalMonitoring];
    if (self.isTracking) {
        [self stopTracking:self];
    }
}

#pragma mark - Actions

- (void)startTracking:(id)sender
{
    if (!self.isTracking) {
        self.isTracking = YES;
        [self updateButtonStates];
        __weak typeof(self) weakSelf = self;
        [self.locationSubscriber startLiveTrackingWithHandler:^(CLLocation *location) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updatePathWithNewLocation:location];
        }];
        
        //In iOS8 we can link them to the settings page for an app
        if (&UIApplicationOpenSettingsURLString != NULL) {
            if (self.locationSubscriber.authorizationStatus == kCLAuthorizationStatusDenied) {
                UIAlertView *settingsAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Denied" message:@"To use this app you need to allow access to the GPS. Go to settings to enable it?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                [settingsAlert show];
            }
        }
    }
}

- (void)stopTracking:(id)sender
{
    if (self.isTracking) {
        self.isTracking = NO;
        [self updateButtonStates];
        [self.locationSubscriber stopLiveTracking];
    }
}

#pragma mark - MapView delegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKPolylineView *pv = [[MKPolylineView alloc] initWithPolyline:overlay];
    [pv setFillColor:[UIColor colorWithRed:167/255.0f green:210/255.0f blue:244/255.0f alpha:1.0]];
    [pv setStrokeColor:[UIColor colorWithRed:106/255.0f green:151/255.0f blue:232/255.0f alpha:1.0]];
    [pv setLineWidth:5.0];
    [pv setLineCap:kCGLineCapRound];
    return pv;
}

#pragma mark - Misc

- (void)updatePathWithNewLocation:(CLLocation *)location
{
    [self.trackedPoints addObject:location];
    
    MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.005, 0.005));
    [self.mapView setRegion:region animated:NO];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    NSUInteger nodeCount = [self.trackedPoints count];
    MKMapPoint * pointsArray = malloc(sizeof(CLLocationCoordinate2D) * nodeCount);
    for (int i = 0; i < nodeCount; i++) {
        CLLocation *location = self.trackedPoints[i];
        pointsArray[i] = MKMapPointForCoordinate(location.coordinate);
    }
    MKPolyline *polyLine = [MKPolyline polylineWithPoints:pointsArray count:nodeCount];
    [self.mapView addOverlay:polyLine];
    free(pointsArray);
}

- (void)updateTitleWithStength:(CLHGPSKitSignalStrength)strength
{
    self.title = [NSString stringWithFormat:@"Live - %@", [LiveTrackingViewController stringForStrength:strength]];
}

- (void)updateButtonStates
{
    UIButton *enabledButton = self.isTracking ? self.stopTrackingButton : self.startTrackingButton;
    UIButton *disabledButton = self.isTracking ? self.startTrackingButton : self.stopTrackingButton;
    
    disabledButton.enabled = NO;
    disabledButton.alpha = 0.4;
    enabledButton.enabled = YES;
    enabledButton.alpha = 1.0;
}

+ (NSString *)stringForStrength:(CLHGPSKitSignalStrength)strength
{
    switch (strength) {
        case CLHGPSKitSignalStrengthNone:
            return @"No GPS";
            break;
        case CLHGPSKitSignalStrengthPoor:
            return @"Poor GPS";
            break;
        case CLHGPSKitSignalStrengthFair:
            return @"Fair GPS";
            break;
        case CLHGPSKitSignalStrengthGreat:
            return @"Great GPS";
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex && &UIApplicationOpenSettingsURLString != NULL) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end