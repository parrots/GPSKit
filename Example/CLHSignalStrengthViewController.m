//
//  CLHSignalStrengthViewController.m
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

#import "CLHSignalStrengthViewController.h"
#import <GPSKit/CLHGPSKit.h>
#include "TargetConditionals.h"

@interface CLHSignalStrengthViewController ()

@property (nonatomic) CLHLocationSubscriber *locationSubscriber;
@property (strong, nonatomic) NSMutableArray *strengths;

@end

@implementation CLHSignalStrengthViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.strengths = [[NSMutableArray alloc] init];
        self.locationSubscriber = [[CLHLocationSubscriber alloc] init];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.locationSubscriber.currentStrength != CLHGPSKitSignalStrengthNone) {
        [self trackNewStrength:self.locationSubscriber.currentStrength];
    }
}

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
    [self.locationSubscriber startSignalMonitoringWithHandler:^(CLHGPSKitSignalStrength strength) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf trackNewStrength:strength];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.locationSubscriber stopSignalMonitoring];
}

#pragma mark - Strength tracking

- (void)trackNewStrength:(CLHGPSKitSignalStrength)strength
{
    [self.strengths insertObject:@(strength) atIndex:0];
    [self.tableView reloadData];
}

+ (NSString *)stringForStrength:(CLHGPSKitSignalStrength)strength
{
    switch (strength) {
        case CLHGPSKitSignalStrengthNone:
            return @"No GPS signal";
            break;
        case CLHGPSKitSignalStrengthPoor:
            return @"Poor GPS signal";
            break;
        case CLHGPSKitSignalStrengthFair:
            return @"Fair GPS signal";
            break;
        case CLHGPSKitSignalStrengthGreat:
            return @"Great GPS signal";
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.strengths count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StrengthCell"];
    CLHGPSKitSignalStrength recordedStrength = [self.strengths[indexPath.row] intValue];
    cell.textLabel.text = [CLHSignalStrengthViewController stringForStrength:recordedStrength];
    return cell;
}

@end