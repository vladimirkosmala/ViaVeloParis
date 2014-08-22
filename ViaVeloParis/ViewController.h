//
//  ViewController.h
//  ViaVeloParis
//
//  Created by Vladimir Kosmala on 25/09/12.
//  Copyright (c) 2012 Vladimir Kosmala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "KMLParser.h"

@interface ViewController : UIViewController

// Data binding
@property NSMutableArray *markerAnnotationArr;
@property NSInteger nbConnections;
@property NSMutableArray *stations;
@property BOOL isVeloView;
@property KMLParser *kmlParser;

// View binding
@property IBOutlet MKMapView *map;
@property IBOutlet UIToolbar *bar;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *labelAddress;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;
@property (weak, nonatomic) IBOutlet UIButton *mapButton;
- (IBAction)mapButtonAction:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *viewMode;
- (IBAction)viewModeChanged:(id)sender;
- (IBAction)zoomMap:(id)sender;

// interface

- (void)goToLat:(double)lat lng:(double)lng;

@end
