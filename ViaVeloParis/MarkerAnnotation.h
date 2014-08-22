//
//  MarkerAnnotation
//  ViaVeloParis
//
//  Created by Vladimir Kosmala on 25/09/12.
//  Copyright (c) 2012 Vladimir Kosmala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface MarkerAnnotation : MKPointAnnotation <MKAnnotation>

@property NSString *name;
@property NSString *address;
@property NSInteger velos;
@property NSInteger places;
@property NSInteger stationNumber;
@property NSInteger state; //{unloaded, loading, loaded, failed}
@property NSInteger total;
@property NSInteger updated;
@property NSInteger open;
@property NSInteger connected;

@end