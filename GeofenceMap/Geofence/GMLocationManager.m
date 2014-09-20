//
//  GMLocationManager.m
//  Geofence
//
//  Created by HikaruSato on 2014/05/02.
//  Copyright (c) 2014年 HikaruSato. All rights reserved.
//

#import "GMLocationManager.h"


#if DEBUG
#define DEBUGLOG(args...) NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat: args])

#else

#define DEBUGLOG(args...)

#endif

@interface GMLocationManager () <CLLocationManagerDelegate>
{
    CLLocationManager* _locationManager;
}
@end


@implementation GMLocationManager

static GMLocationManager *_sharedManger = nil;


#pragma mark - class selector

+ (GMLocationManager *)sharedManager
{
    
    @synchronized(self)
    {
        if (!_sharedManger)
        {
            _sharedManger = [GMLocationManager new];
        }
    }
    return _sharedManger;
}

/**
 * @prief 領域観測が可能か
 * @param region 対象領域
 * @return YES:可能 / NO:不可
 */
+ (BOOL) isMonitoringAvailable:(CLRegion*)region
{
    BOOL ret = NO;
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    //iOS7以降
    if (iOSVersion >= 7.0)
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized &&
            [CLLocationManager isMonitoringAvailableForClass:[region class]])
        {
            ret = YES;
        }
        else
        {
            DEBUGLOG(@"領域観測の使用不可。 locationServicesEnabled:%@, isMonitoringAvailableForClass:%@",
                     ([CLLocationManager locationServicesEnabled] ? @"YES" : @"NO"),
                     ([CLLocationManager isMonitoringAvailableForClass:[region class]] ? @"YES" : @"NO"));
        }
    }
    //iOS6以前
    else
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized &&
            [CLLocationManager regionMonitoringAvailable])
        {
            ret = YES;
        }
        else
        {
            DEBUGLOG(@"領域観測の使用不可。 locationServicesEnabled:%@, regionMonitoringAvailable:%@",
                     ([CLLocationManager locationServicesEnabled] ? @"YES" : @"NO"),
                     ([CLLocationManager regionMonitoringAvailable] ? @"YES" : @"NO"));
        }
    }
    
    return ret;
}

/**
 * @prief 領域観測が可能か
 *
 * @return YES:可能 / NO:不可
 */
+ (BOOL) isMonitoringAvailable
{
    BOOL ret = NO;
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    //iOS7以降
    if (iOSVersion >= 7.0)
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized &&
            [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]])
        {
            ret = YES;
        }
    }
    //iOS6以前
    else
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized &&
            [CLLocationManager regionMonitoringAvailable])
        {
            ret = YES;
        }
    }
    
    return ret;
}

#pragma mark - member selector

/**
 * @brief 初期化
 *
 */
- (id) init
{
    if (self = [super init])
    {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
    }
    return self;
}

/**
 * @brief 破棄
 *
 */
-(void)dealloc
{
    _delegate = nil;
    if(_locationManager)
    {
        [self stopLocationRegion];
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
        _locationManager = nil;
    }
}

#pragma mark - public

/**
 * @brief 観測する領域の設定
 * @param center 対象領域の中心
 * @param radius 対象領域の半径
 * @param regionId 対象領域の識別子
 *
 */
- (void)startMonitoringForRegion:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius identifier:(NSString *)regionId
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    //最大半径を超えている場合、丸める
    if(radius > _locationManager.maximumRegionMonitoringDistance)
    {
        radius = _locationManager.maximumRegionMonitoringDistance;
    }
    
    //iOS7以降
    if (iOSVersion >= 7.0)
    {
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center
                                                                     radius:radius
                                                                 identifier:regionId];
        [_locationManager startMonitoringForRegion:region];
    }
    //iOS6以前
    else
    {
        CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter:center
                                                                   radius:radius
                                                               identifier:regionId];
        if(iOSVersion >= 5.0)
        {
            [_locationManager startMonitoringForRegion:region];
        }
        else
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [_locationManager startMonitoringForRegion:region desiredAccuracy:kCLLocationAccuracyBest];
#pragma clang diagnostic pop
        }
    }
}

/**
 * @prief monitoredRegions取得
 * @returns monitoredRegions(コピーオブジェクト)
 */
- (NSMutableSet*)getMonitoredRegions
{
    NSMutableSet* mset;
    if(_locationManager.monitoredRegions && [_locationManager.monitoredRegions count] > 0)
    {
        mset = [NSMutableSet setWithSet:_locationManager.monitoredRegions];
    }
    else
    {
        mset = [[NSMutableSet alloc]init];
    }
    return mset;
}


/**
 * @prief 領域観測の停止
 * @param 領域の識別子
 */
- (void) stopRegionWithRegionId:(NSString *)regionId
{
	for (CLRegion *region in _locationManager.monitoredRegions)
    {
		if ([region.identifier isEqual:regionId])
        {
			[_locationManager stopMonitoringForRegion:region];
            break;
		}
	}
}

/**
 * @prief 領域観測の停止
 * 登録されている領域観測を全て停止
 */
- (void) stopLocationRegion
{
	for (CLRegion *region in _locationManager.monitoredRegions)
    {
        DEBUGLOG(@"*** stopLocationRegion id:%@", region.identifier);
        [_locationManager stopMonitoringForRegion:region];
    }
}

/**
 * @prief すでに領域に入っているかどうかを確認
 * @note 結果は[delegate locationManager:didStateInsideRegion:]でCallBackする。
 */
- (void) requestStateForRegion
{
    //[CLLocationManger requestStateForRegion:](iOS7以降で使用可能)だと、現在地情報がわからないため、startUpdatingLocationを使用する。
    if([CLLocationManager locationServicesEnabled])
    {
        //一度だけユーザ位置を取得する
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        [_locationManager startUpdatingLocation];
    }
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if([self.delegate respondsToSelector:@selector(locationManager:didStartMonitoringForRegion:)])
    {
        [self.delegate locationManager:manager didStartMonitoringForRegion:region];
    }
}

/**
 * @brief 指定した領域に入った場合
 */
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{    
    if([self.delegate respondsToSelector:@selector(locationManager:didEnterRegion:)])
    {
        [self.delegate locationManager:manager didEnterRegion:region];
    }
}


/**
 * @brief 指定した領域から出た場合
 */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if([self.delegate respondsToSelector:@selector(locationManager:didExitRegion:)])
    {
        [self.delegate locationManager:manager didExitRegion:region];
    }
}

/**
 * @brief 領域観測でエラー発生時（領域観測の登録に失敗したときなど）
 */
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(locationManager:didFailForRegion:withError:)])
    {
        [self.delegate locationManager:manager didFailForRegion:region withError:error];
    }
}

///**
// * @brief 領域の状態遷移時にコールされる
// * @note 引数のmanagerにユーザー位置情報が入っていなかった。iOS7以降で使用可能。
// */
//- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
//{
//    switch (state) {
//        case CLRegionStateInside:
//            DEBUGLOG(@"regionId:%@の内側にいます。", region.identifier);
//            break;
//        case CLRegionStateOutside:
//            DEBUGLOG(@"regionId:%@の外側にいます。", region.identifier);
//            break;
//        case CLRegionStateUnknown:
//            DEBUGLOG(@"CLRegionState is Unknown. regionId:%@", region.identifier);
//            break;
//        default:
//            break;
//    }
//}

/**
 * @brief ユーザー位置がコールされる
 * @note iOS6以降でコールされる。
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* userLocation = [locations lastObject];
    //ユーザ位置観測停止
    [_locationManager stopUpdatingLocation];
    
    for (CLRegion *region in _locationManager.monitoredRegions)
    {
        BOOL inside = [self checkLocationAtRegionInside:region Location:userLocation];
        if(inside)
        {
            if([self.delegate respondsToSelector:@selector(locationManager:didStateInsideRegion:)])
            {
                [self.delegate locationManager:userLocation didStateInsideRegion:region];
            }
        }
    }
}

/**
 * @brief ユーザー位置がコールされる
 * @note iOS2~5でコールされる。
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //ユーザ位置観測停止
    [_locationManager stopUpdatingLocation];
    
    for (CLRegion *region in _locationManager.monitoredRegions)
    {
        BOOL inside = [self checkLocationAtRegionInside:region Location:newLocation];
        if(inside)
        {
            if([self.delegate respondsToSelector:@selector(locationManager:didStateInsideRegion:)])
            {
                [self.delegate locationManager:newLocation didStateInsideRegion:region];
            }
        }
    }
}

/**
 * GPS測位が失敗した場合に呼ばれる
 */
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DEBUGLOG(@"%@",[error localizedDescription]);
}

/*
 *  本アプリの位置情報使用の認証状態が変更されたとき
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)])
    {
        [self.delegate locationManager:manager didChangeAuthorizationStatus:status];
    }
}

#pragma mark - プライベート

/**
 * @brief 指定位置が指定領域の内側か
 * @param region 指定領域
 * @param location 指定位置
 */
- (BOOL)checkLocationAtRegionInside:(CLRegion*)region Location:(CLLocation*)location
{
    BOOL isInside = NO;
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    CLLocation *regionLocation = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
    
    //　距離(merters)を取得
    CLLocationDistance distance = [location distanceFromLocation:regionLocation];
    if(iOSVersion >= 7.0)
    {
        if(distance <= ((CLCircularRegion*)region).radius)
            isInside = YES;
    }
    else
    {
        if(distance <= region.radius)
            isInside = YES;
    }

    return isInside;
}

@end
