//
//  MDLocationManager.h
//  MobileDefense
//
//  Created by Pawan Poudel on 4/18/12.
//  Copyright (c) 2012 Mobile Defense Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MDLocationManagerDelegate.h"

@interface MDLocationManager : NSObject

@property (nonatomic, weak) id <MDLocationManagerDelegate> delegate;
@property (nonatomic, copy) NSString *purpose;
@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;

- (void)fetchCurrentLocation;
- (void)fetchCurrentPlacemark;
- (void)stopUpdatingLocation;

@end