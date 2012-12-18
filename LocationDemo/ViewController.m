//
//  ViewController.m
//  LocationDemo
//
//  Created by PAWAN POUDEL on 12/17/12.
//  Copyright (c) 2012 Mobile Defense Inc. All rights reserved.
//

#import "ViewController.h"
#import "MDLocationManager.h"
#import <MapKit/MapKit.h>

@interface ViewController () <MDLocationManagerDelegate> {
    CLLocation *currentLocation;
    NSString *streetAddress;
    
    NSTimer *stopLocationUpdateTimer;
}

@property (strong, nonatomic) MDLocationManager *locationManager;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *latLongLabel;
@property (weak, nonatomic) IBOutlet UILabel *streetAddressLabel;

@property (weak, nonatomic) IBOutlet UIView *latLongActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *streetAddressActivityIndicator;

@property (weak, nonatomic) IBOutlet UIImageView *latLongWarningImageView;
@property (weak, nonatomic) IBOutlet UIImageView *streetAddressWarningImageView;

@end

@implementation ViewController

#pragma mark - Accessors

- (MDLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[MDLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = 10; // meters
        _locationManager.purpose = @"to display your street address.";
    }
    return _locationManager;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = @"Location Demo";    
    [self performLocationTask:nil];
    [self hideLoadingIndicator];    
}

- (void)viewDidUnload {
    [self setLatLongWarningImageView:nil];
    [self setStreetAddressWarningImageView:nil];
    [super viewDidUnload];
}

#pragma mark - Actions

- (void)performLocationTask:(id)sender {
    // Check if user has disabled or denied Location Services access
    
    NSString *latLongLabelText = @"";
    NSString *streetAddressLabelText = @"Unable to retrieve your street address.";
    
    if ([CLLocationManager locationServicesEnabled] == NO) {
        latLongLabelText = @"Location Services is disabled. Enable it from Settings app to retrieve your location.";
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        latLongLabelText = @"Access to Location Services for this app is denied. Authorize this app from Settings app to retrieve your location.";
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        latLongLabelText = @"Access to Location Services for this app is restricted. Remove parental control from General > Restrictions view in Settings app.";
    }
    else {
        [self startProgressViews];
        [self.locationManager fetchCurrentPlacemark];
        
        double locationTimeout = 30.0; // seconds
        stopLocationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:locationTimeout
                                                                   target:self
                                                                 selector:@selector(stopLocationUpdateTimerFired:)
                                                                 userInfo:nil
                                                                  repeats:NO];     
        return;
    }
    
    self.latLongLabel.text = latLongLabelText;
    self.streetAddressLabel.text = streetAddressLabelText;
    
    self.latLongWarningImageView.hidden = NO;
    self.streetAddressWarningImageView.hidden = NO;    
}

- (void)stopLocationUpdateTimerFired:(id)sender {
    [self.locationManager stopUpdatingLocation];
    self.latLongLabel.text = @"Unable to retrieve your location at this time. Please move around and try again.";
    self.latLongWarningImageView.hidden = NO;
    
    self.streetAddressLabel.text = @"Unable to retrieve your street address";
    self.streetAddressWarningImageView.hidden = NO;
    
    [self stopProgressViews];
}

- (void)updateLocationInfo {
    NSString *format = @"Latitude: %+.5f\nLongitude: %+.5f\nHorizontal Accuracy: %+.5f\n";
    
    self.latLongLabel.text = [NSString stringWithFormat:format,
                              currentLocation.coordinate.latitude,
                              currentLocation.coordinate.longitude,
                              currentLocation.horizontalAccuracy];
}

- (void)zoomMapViewIn {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([currentLocation coordinate],
                                                                   500,
                                                                   500);
    [self.mapView setRegion:region
                   animated:YES];
}

#pragma mark - Progress view methods

- (void)showLoadingIndicator {
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	indicator.frame = CGRectMake(0, 0, 24, 24);
	[indicator startAnimating];
	UIBarButtonItem *progress = [[UIBarButtonItem alloc] initWithCustomView:indicator];
	[self.navigationItem setRightBarButtonItem:progress animated:YES];
}

- (void)hideLoadingIndicator {
	UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)self.navigationItem.rightBarButtonItem;
	if ([indicator isKindOfClass:[UIActivityIndicatorView class]]) {
		[indicator stopAnimating];
	}
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(performLocationTask:)];
	[self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
}

- (void)startProgressViews {
    self.latLongLabel.text = @"";
    self.streetAddressLabel.text = @"";
    
    self.latLongWarningImageView.hidden = YES;
    self.streetAddressWarningImageView.hidden = YES;
    
    self.latLongActivityIndicator.hidden = NO;
    self.streetAddressActivityIndicator.hidden = NO;
    [self showLoadingIndicator];
}

- (void)stopProgressViews {
    self.latLongActivityIndicator.hidden = YES;
    self.streetAddressActivityIndicator.hidden = YES;
    [self hideLoadingIndicator];
}

#pragma mark - MDLocationManager delegate methods

- (void)didReceiveCurrentLocation:(CLLocation *)location {
    self.latLongActivityIndicator.hidden = YES;  
    currentLocation = location;
    [self updateLocationInfo];
    [stopLocationUpdateTimer invalidate];
}

- (void)didReceiveStreetAddress:(NSString *)address
                    forLocation:(CLLocation *)location
{
    streetAddress = address;
    currentLocation = location;
    [self.locationManager stopUpdatingLocation];

    [self zoomMapViewIn];
    [self stopProgressViews];
    self.streetAddressLabel.text = [NSString stringWithFormat:@"Street Address:\n%@", address];
}

- (void)fetchingCurrentLocationFailedWithError:(NSError *)error {
    [self stopProgressViews];
    [stopLocationUpdateTimer invalidate];
    [self.locationManager stopUpdatingLocation];
    
    if (error.code == kCLErrorDenied) {
        self.latLongLabel.text = @"Access to Location Services for this app is denied. Authorize this app from Settings app to retrieve your location.";
        self.streetAddressLabel.text = @"Unable to retrieve your street address.";
        
        self.latLongWarningImageView.hidden = NO;
        self.streetAddressWarningImageView.hidden = NO;
    }
    else {
        NSLog(@"Couldn't retrieve user's location.");
        NSLog(@"Error description: %@", error.localizedDescription);
        NSLog(@"Error code: %d", error.code);
    }
}

- (void)fetchingCurrentPlacemarkFailedWithError:(NSError *)error {
    [self stopProgressViews];
    [stopLocationUpdateTimer invalidate];
    [self.locationManager stopUpdatingLocation];
    self.streetAddressWarningImageView.hidden = NO;
    
    NSLog(@"Couldn't retrieve user's street address.");
    NSLog(@"Error description: %@", error.localizedDescription);
    NSLog(@"Error code: %d", error.code);    
    
    switch (error.code) {
        case kCLErrorGeocodeFoundNoResult: {
            self.streetAddressLabel.text = @"Unable to lookup latitude and longitude to find your street address.";
        } break;
            
        case kCLErrorGeocodeCanceled: {
            self.streetAddressLabel.text = @"Request to find your street address was canceled.";
        } break;
            
        case kCLErrorGeocodeFoundPartialResult: {
            self.streetAddressLabel.text = @"Only partial info about your address is found at this time.";
        } break;
            
        default: {
            self.streetAddressLabel.text = @"Unable to lookup latitude and longitude to find your street address.";            
        } break;
    }
}

@end
