//
//  MDLocationManager.m
//  MobileDefense
//
//  Created by Pawan Poudel on 4/18/12.
//  Copyright (c) 2012 Mobile Defense Inc. All rights reserved.
//

#import "MDLocationManager.h"
#import <CoreLocation/CoreLocation.h>

double const kMDLocationAccuracyNeeded = 100.0;    // meters
double const kMDLocationFallbackAccuracy = 200.0;  // meters
double const kMDCachedLocationAge = 180;           // 3 minutes

@interface MDLocationManager () <CLLocationManagerDelegate> {
    BOOL shouldFetchStreetAddress;
    NSInteger numberOfAttemptsToGetGoodLocation;
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLPlacemark *currentPlacemark;

@end

@implementation MDLocationManager

#pragma mark - Accessors

- (void)setDelegate:(id <MDLocationManagerDelegate>)newDelegate {
    if (newDelegate &&
        ([newDelegate conformsToProtocol:@protocol(MDLocationManagerDelegate)] == NO))
    {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Delegate object does not conform to the delegate protocol"
                               userInfo:nil] raise];
    }
    _delegate = newDelegate;
}

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = self.desiredAccuracy;
        _locationManager.distanceFilter = self.distanceFilter;
        _locationManager.delegate = self;
        
        if (self.purpose) {
            _locationManager.purpose = self.purpose;
        }
    }
    return _locationManager;
}

- (CLGeocoder *)geocoder {
    if (_geocoder == nil) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

#pragma mark - Initializers

- (id)init {
    self = [super init];
    if (self) {
        _distanceFilter = kCLDistanceFilterNone;
        _desiredAccuracy = kCLLocationAccuracyBest;
    }
    return self;
}

#pragma mark - Actions

- (void)fetchCurrentLocation {
    shouldFetchStreetAddress = NO;
    [self.locationManager startUpdatingLocation];
}

- (void)fetchCurrentPlacemark {
    shouldFetchStreetAddress = YES;
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManager delegate methods

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (void)foundNewGoodLocation:(CLLocation *)newLocation {
    numberOfAttemptsToGetGoodLocation = 0;
    self.currentLocation = newLocation;
    
    if ([self.delegate respondsToSelector:@selector(didReceiveCurrentLocation:)]) {
        [self.delegate didReceiveCurrentLocation:self.currentLocation];
    }
    
    if (shouldFetchStreetAddress) {
        [self fetchStreetAddressForLocation:self.currentLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{    
    // How many seconds ago was this new location created?
    NSTimeInterval locationAge = [[NSDate date] timeIntervalSinceDate:newLocation.timestamp];
    
    // CLLocationManager will return the last found location of the device first
    if (locationAge > kMDCachedLocationAge) {
       // This is cached data, you don't want it, keep looking
        return;
    }
    
    if ((newLocation.horizontalAccuracy <= kMDLocationAccuracyNeeded) ||
        ((numberOfAttemptsToGetGoodLocation > 3) && (newLocation.horizontalAccuracy <= kMDLocationFallbackAccuracy)))
    {
        [self foundNewGoodLocation:newLocation];
    }
    else {
        numberOfAttemptsToGetGoodLocation++;
    }    
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorLocationUnknown) {
        // Location is currently unknown, but CLLocationManager will keep trying.
        // So, ignore this error.
        return;
    }    
    
    self.currentLocation = nil;
    self.currentPlacemark = nil;
    [self.delegate fetchingCurrentLocationFailedWithError:error];
}

#pragma mark - Geocoder methods

- (void)fetchStreetAddressForLocation:(CLLocation *)location {
    [self.geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray *placemarks, NSError *error) {
                            if (error) {
                                self.currentPlacemark = nil;
                                if ([self.delegate respondsToSelector:@selector(fetchingCurrentPlacemarkFailedWithError:)]) {
                                    [self.delegate fetchingCurrentPlacemarkFailedWithError:error];
                                }
                            }
                            else {
                                self.currentPlacemark = placemarks[0];
                                if ([self.delegate respondsToSelector:@selector(didReceiveStreetAddress:forLocation:)]) {
                                    [self.delegate didReceiveStreetAddress:[self streetAddressFromPlacemark:self.currentPlacemark]
                                                               forLocation:self.currentPlacemark.location];
                                }
                                
                                if ([self.delegate respondsToSelector:@selector(didReceiveCurrentPlacemark:)]) {
                                    [self.delegate didReceiveCurrentPlacemark:self.currentPlacemark];
                                }
                            }
                        }];
}

- (NSString *)streetAddressFromPlacemark:(CLPlacemark *)placemark {
    NSMutableString *address = [[NSMutableString alloc] init];
    if (placemark.subThoroughfare)
        [address appendFormat:@"%@ ", placemark.subThoroughfare];
    
    if (placemark.thoroughfare)
        [address appendFormat:@"%@ ", placemark.thoroughfare];
    
    if (placemark.locality)
        [address appendFormat:@"%@ ", placemark.locality];
    
    if (placemark.administrativeArea)
        [address appendFormat:@"%@ ", placemark.administrativeArea];
    
    if (placemark.postalCode)
        [address appendFormat:@"%@ ", placemark.postalCode];
    
    if (placemark.country)
        [address appendFormat:@"%@", placemark.country];
    
    return address;
}

@end