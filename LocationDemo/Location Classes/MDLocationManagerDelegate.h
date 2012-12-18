//
//  MDLocationManagerDelegate.h
//  MobileDefense
//
//  Created by PAWAN POUDEL on 11/15/12.
//  Copyright (c) 2012 Mobile Defense Inc. All rights reserved.
//

@class CLLocation;
@class CLPlacemark;

@protocol MDLocationManagerDelegate <NSObject>

@optional

- (void)didReceiveCurrentLocation:(CLLocation *)location;
- (void)fetchingCurrentLocationFailedWithError:(NSError *)error;

- (void)didReceiveCurrentPlacemark:(CLPlacemark *)placemark;
- (void)fetchingCurrentPlacemarkFailedWithError:(NSError *)error;

- (void)didReceiveStreetAddress:(NSString *)address
                    forLocation:(CLLocation *)location;

@end
