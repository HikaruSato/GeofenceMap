//
//  GMLocationManager.m
//  Geofence
//
//  Created by HikaruSato on 2014/05/02.
//  Copyright (c) 2014年 HikaruSato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@protocol GMLocationManagerDelegate<NSObject>
@optional
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didFailForRegion:(CLRegion *)region withError:(NSError *)error;
- (void)locationManager:(CLLocation*)userLocation didStateInsideRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
@end

@interface GMLocationManager : NSObject

@property (nonatomic, weak) id<GMLocationManagerDelegate> delegate;

+ (GMLocationManager *)sharedManager;
+ (BOOL) isMonitoringAvailable;
- (void) startMonitoringForRegion:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius identifier:(NSString *)regionId;
- (NSMutableSet*)getMonitoredRegions;
- (void) requestStateForRegion;
- (void) stopRegionWithRegionId:(NSString *)regionId;
- (void) stopLocationRegion;

@end
