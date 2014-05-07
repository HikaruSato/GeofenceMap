//
//  GMViewController.m
//  GeofenceMap
//
//  Created by HikaruSato on 2014/05/02.
//  Copyright (c) 2014年 HikaruSato. All rights reserved.
//

#import "GMViewController.h"
#import <MapKit/MapKit.h>
#import "GMLocationManager.h"
#import "GMMKPointAnnotation.h"

@interface GMViewController ()<MKMapViewDelegate, GMLocationManagerDelegate>
{
    __weak IBOutlet MKMapView *_mapView;
    BOOL _isInitSetupGeofence;
    BOOL _isObserveLocation;
}

@end


@implementation GMViewController

static NSString *Const_GPMarkerDataCircle  = @"GPMarkerDataCircle";

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [GMLocationManager sharedManager].delegate = self;
    _isInitSetupGeofence = NO;
    [self initSetup];
}


- (void)initSetup
{
    if([GMLocationManager isMonitoringAvailable])
    {
        //ジオフェンスの初期化済みのとき
        if(_isInitSetupGeofence)
            return;
        
        _isInitSetupGeofence = YES;
        //既に観測済みの領域を観測対象から削除
        [[GMLocationManager sharedManager] stopLocationRegion];
        //観測したい領域を観測開始（２０個まで）。山手線の２０駅を観測開始。
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.690921,139.700258) radius:200. identifier:@"Shinjuku"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.683061,139.702042) radius:200. identifier:@"Yoyogi"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.670168,139.702687) radius:200. identifier:@"Harajuku"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.658517,139.701334) radius:200. identifier:@"Shibuya"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.64669,139.710106) radius:200. identifier:@"Ebisu"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.633998,139.715828) radius:200. identifier:@"Meguro"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.626446,139.723444) radius:200. identifier:@"Gotanda"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.6197,139.728553) radius:200. identifier:@"Ohsaki"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.630152,139.74044) radius:200. identifier:@"Shinagawa"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.645736,139.747575) radius:200. identifier:@"Tamachi"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.655646,139.756749) radius:200. identifier:@"HamamatsuCho"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.665498,139.75964) radius:200. identifier:@"Shinbashi"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.675069,139.763328) radius:200. identifier:@"Yu-rakucho"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.681382,139.766084) radius:200. identifier:@"Tokyo"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.69169,139.770883) radius:200. identifier:@"Kanda"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.698683,139.774219) radius:200. identifier:@"Akihabara"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.707893,139.774332) radius:200. identifier:@"Okachimachi"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.713768,139.777254) radius:200. identifier:@"Ueno"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.720495,139.778837) radius:200. identifier:@"Uguisudani"];
        [[GMLocationManager sharedManager] startMonitoringForRegion:CLLocationCoordinate2DMake(35.727772,139.770987) radius:200. identifier:@"Nippori"];
        
        [_mapView removeAnnotations:_mapView.annotations];
        for(CLRegion* region in [[GMLocationManager sharedManager] getMonitoredRegions])
        {
            MKPointAnnotation* pin = [MKPointAnnotation new];
            pin.coordinate = region.center;
            pin.title = region.identifier;
            pin.subtitle = [NSString stringWithFormat:@"%f(%f,%f)", region.radius, region.center.latitude, region.center.longitude];
            [_mapView addAnnotation:pin];
            
            //円作成
            MKCircle* circle = [MKCircle circleWithCenterCoordinate:region.center radius:region.radius];
            circle.title = Const_GPMarkerDataCircle;
            [_mapView addOverlay:circle];
        }
        //KVOで現在地(location)を観察
        [_mapView.userLocation addObserver:self forKeyPath:@"location" options:0 context:NULL];
        _isObserveLocation = YES;
    }
    else
    {
        [self sendLocalNotification:@"領域観測の利用が出来ません。"];
        _isObserveLocation = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if(_isObserveLocation)
    {
        _isObserveLocation = NO;
        [_mapView.userLocation removeObserver:self forKeyPath:@"location"];
    }
}

#pragma mark - KVO

/**
 * KVO
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"location"] && _mapView.userLocation != nil)
    {
        if(_isObserveLocation)
        {
            _isObserveLocation = NO;
            [_mapView.userLocation removeObserver:self forKeyPath:@"location"];
            //現在地にマップ表示を移動
            MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
            MKCoordinateRegion region = MKCoordinateRegionMake(_mapView.userLocation.coordinate , span);
            [_mapView setRegion:region animated:YES];
        }
    }
}


#pragma mark - MKMapViewDelegate

//
/**
 * @brief アノテーションが表示される時にコールされる
 */
-(MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id)annotation
{
    //ユーザー現在地のとき
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        //現在地はnilを返してデフォルト表示(青いドット)のままにする
        return nil;
    }
    
    static NSString *PinIdentifier = @"Pin";
     // 再利用可能な MKAnnotationView を取得
    MKAnnotationView *pav = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:PinIdentifier];
    if(pav == nil)
    {
        //IN/OUT アノテーションのとき
        if([annotation isKindOfClass:[GMMKPointAnnotation class]])
        {
            GMMKPointAnnotation *ann = annotation;
            pav = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PinIdentifier];
            // 吹き出しあり
            pav.canShowCallout = YES;
            pav.image = ann.pinImage;
            pav.centerOffset = CGPointMake(7.5, 7.5);
            pav.calloutOffset = CGPointMake(0., 0.);
        }
        else
        {
            //デフォルトのMKAnnotationViewを表示
            pav = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PinIdentifier];
            pav.canShowCallout = YES;
        }
    }
    return pav;
}

/**
 * @brief ジオフェンスの円を描画
 */
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id < MKOverlay >)overlay
{
    MKCircle* circle = overlay;
    NSLog(@"%@",circle.title);
    MKCircleView* circleOverlayView = [[MKCircleView alloc] initWithCircle:circle];
    
    if([circle.title isEqualToString:Const_GPMarkerDataCircle])
    {
        circleOverlayView.strokeColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        circleOverlayView.lineWidth = 1.;
        circleOverlayView.fillColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.15];
    }
    
    return circleOverlayView;
}


#pragma mark - GMLocationManagerDelegate

/**
 * @brief 領域に入ったときにコールされる
 * @params manager ユーザー位置情報など
 * @params region 対象領域
 */
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    GMMKPointAnnotation* pin = [GMMKPointAnnotation new];
    pin.coordinate = manager.location.coordinate;
    pin.title = [NSString stringWithFormat:@"%@ に入りました。", region.identifier];
    pin.pinImage = [UIImage imageNamed:@"checkIn"];
    pin.subtitle = [NSString stringWithFormat:@"(%f,%f)", manager.location.coordinate.latitude, manager.location.coordinate.longitude];
    [_mapView addAnnotation:pin];
    [self sendLocalNotification:[NSString stringWithFormat:@"領域：%@ に入りました。" ,region.identifier]];
}

/**
 * @brief 領域を出たときにコールされる
 * @params manager 対象のロケーションマネージャー。ユーザー位置情報など
 * @params region 対象領域
 */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    GMMKPointAnnotation* pin = [GMMKPointAnnotation new];
    pin.coordinate = manager.location.coordinate;
    pin.title = [NSString stringWithFormat:@"%@ を出ました。", region.identifier];
    pin.pinImage = [UIImage imageNamed:@"checkOut"];
    pin.subtitle = [NSString stringWithFormat:@"(%f,%f)", manager.location.coordinate.latitude, manager.location.coordinate.longitude];
    [_mapView addAnnotation:pin];
    [self sendLocalNotification:[NSString stringWithFormat:@"領域：%@ を出ました。" ,region.identifier]];
}


/**
 * @brief 領域観測に既に入っていたとき
 * @params userLocation ユーザー位置情報
 * @params region 対象領域
 */
- (void)locationManager:(CLLocation*)userLocation didStateInsideRegion:(CLRegion *)region
{
    [self sendLocalNotification:[NSString stringWithFormat:@"領域：%@ 内にいます。" ,region.identifier]];
}

/**
 * @brief 領域観測でエラー発生時（領域観測の登録に失敗したときなど）
 * @params manager 対象のロケーションマネージャー。ユーザー位置情報など
 * @params region 対象領域
 */
- (void)locationManager:(CLLocationManager *)manager didFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self sendLocalNotification:[NSString stringWithFormat:@"領域：%@ でエラー発生。" ,region.identifier]];
}

/**
 * @brief 本アプリの位置情報使用の認証状態が変更されたときにコールされる
 * @params manager 対象のロケーションマネージャー。ユーザー位置情報など
 * @params status 認証状態
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status == kCLAuthorizationStatusAuthorized)
    {
        [self sendLocalNotification:@"領域観測の利用が出来ます。"];
        [self initSetup];
    }
}

#pragma mark - action

/**
 * @brief 現在地ボタンタップ
 */
- (IBAction)touchUpInsideMyLocationButton:(id)sender
{
    //現在地にマップ表示を移動
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
    MKCoordinateRegion region = MKCoordinateRegionMake(_mapView.userLocation.coordinate , span);
    [_mapView setRegion:region animated:YES];
}


#pragma mark - private

/**
 * @brief ローカル通知表示
 * @params 通知メッセージ
 */
- (void)sendLocalNotification:(NSString*)msg
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = nil;//すぐ配信
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = [NSString stringWithFormat:@"%@", msg];
    notification.alertAction = @"Open";
    notification.soundName = UILocalNotificationDefaultSoundName;
    // 通知を登録する
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

@end
