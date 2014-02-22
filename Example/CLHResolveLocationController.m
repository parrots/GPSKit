//
//  CLHDetailViewController.m
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
#import "CLHResolveLocationController.h"
#import "CLHMapPin.h"
#import <GPSKit/CLHGPSKit.h>

@interface CLHResolveLocationController ()

@property (nonatomic) CLHLocationSubscriber *locationSubscriber;

@end

@implementation CLHResolveLocationController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.locationSubscriber = [[CLHLocationSubscriber alloc] init];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    [self.locationSubscriber resolveCurrentLocationWithInProgressHandler:^(CLLocation *location) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        CLHMapPin *point = [[CLHMapPin alloc] init];
        point.coordinate = location.coordinate;
        [strongSelf.mapView addAnnotation:point];
        
    } andCompletionHandler:^(CLLocation *location) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        CLHMapPin *point = [[CLHMapPin alloc] init];
        point.coordinate = location.coordinate;
        [strongSelf.mapView addAnnotation:point];
        
        MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.05, 0.05));
        [strongSelf.mapView setRegion:region animated:YES];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.locationSubscriber cancelResolvingCurrentLocation];
}

@end
