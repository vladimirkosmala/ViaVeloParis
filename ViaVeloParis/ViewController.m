//
//  ViewController.m
//  ViaVeloParis
//
//  Created by Vladimir Kosmala on 25/09/12.
//  Copyright (c) 2012 Vladimir Kosmala. All rights reserved.
//

#import "ViewController.h"
#import "MarkerAnnotation.h"
#import "KMLParser.h"
#import "SMXMLDocument.h"

#import <MapKit/MapKit.h>

#import "GAI.h"


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.markerAnnotationArr = [[NSMutableArray alloc] init];
    //[self.map setUserTrackingMode:MKUserTrackingModeFollow];
    [self.map setShowsUserLocation:true];
    self.isVeloView = true;
    
    [self hideInfoView];
    [self setToParisCenter];
    [self parseKMLData];
    [self parseCarto];
    
    // Maps or Plans icon
    if ([[UIApplication sharedApplication] canOpenURL:
         [NSURL URLWithString:@"comgooglemaps://"]]) {
        [self.mapButton setImage:[UIImage imageNamed:@"maps.png"] forState:UIControlStateNormal];
    } else {
        [self.mapButton setImage:[UIImage imageNamed:@"plans.png"] forState:UIControlStateNormal];
    }

    //DetailViewController *detailViewController = [[DetailViewController alloc] init];
    //[self.navigationController pushViewController:detailViewController animated:true];
    //[self performSegueWithIdentifier:@"dddd" sender:self];
    
    // Add tracking button
    MKUserTrackingBarButtonItem *trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.map];
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.bar.items];
    [items insertObject:trackingButton atIndex:0];
    [self.bar setItems:items];
}

- (IBAction)viewModeChanged:(id)sender {
    NSInteger index = self.viewMode.selectedSegmentIndex;
    
    if (index == 0) {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker trackEventWithCategory:@"ui"
                             withAction:@"Action"
                              withLabel:@"Voir vélos"
                              withValue:nil];
        
        NSLog(@"viewMode = vélos");
        self.isVeloView = true;
        [self reinitAnnotations];
    }
    
    if (index == 1) {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker trackEventWithCategory:@"ui"
                             withAction:@"Action"
                              withLabel:@"Voir places"
                              withValue:nil];
        
        NSLog(@"viewMode = places");
        self.isVeloView = false;
        [self reinitAnnotations];
    }
}

- (IBAction)zoomMap:(id)sender {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker trackEventWithCategory:@"ui"
                         withAction:@"Action"
                          withLabel:@"Zoom"
                          withValue:nil];
    
    [self showAllKMLData];
}

- (IBAction)mapButtonAction:(id)sender {
    MarkerAnnotation *markerAnnotation = [self.map.selectedAnnotations objectAtIndex:0];
    if (markerAnnotation) {
        [self externalAppWithLat:markerAnnotation.coordinate.latitude lng:markerAnnotation.coordinate.longitude];
    }
}

// ------------------------------------
// Map
// ------------------------------------

- (void)setToParisCenter
{
    [self goToLat:48.856485 lng:2.351951];
}

- (void)goToLat:(double)lat lng:(double)lng
{
    CLLocationCoordinate2D loc = {lat, lng};
    [self.map setCenterCoordinate:loc animated:NO];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 700, 700);
    [self.map setRegion:region animated:NO];
}

- (void)externalAppWithLat:(double)lat lng:(double)lng
{
    if ([[UIApplication sharedApplication] canOpenURL:
         [NSURL URLWithString:@"comgooglemaps://"]])
    {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker trackEventWithCategory:@"ui"
                             withAction:@"Appli externe"
                              withLabel:@"Google Maps"
                              withValue:nil];
        
        NSString *str = [[NSString alloc] initWithFormat:@"comgooglemaps://?q=%f,%f", lat, lng];
        NSURL *url = [[NSURL alloc] initWithString:str];
        [[UIApplication sharedApplication] openURL:url];
    }
    else
    {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker trackEventWithCategory:@"ui"
                             withAction:@"Appli externe"
                              withLabel:@"Apple Plans"
                              withValue:nil];
        
        NSString *str = [[NSString alloc] initWithFormat:@"http://maps.apple.com/maps?q=%f,%f", lat, lng];
        NSURL *url = [[NSURL alloc] initWithString:str];
        [[UIApplication sharedApplication] openURL:url];
    }
}

// ------------------------------------
// Arrondissements KML
// ------------------------------------

- (void)parseKMLData
{
    // KMLParser.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LesarrondissementsdeParis" ofType:@"kml"];
    NSURL *url = [NSURL fileURLWithPath:path];
    self.kmlParser = [[KMLParser alloc] initWithURL:url];
    [self.kmlParser parseKML];
}

- (void)showAllKMLData
{
    [self showKMLData];
    
    NSArray *overlays = [self.kmlParser overlays];
    NSArray *annotations = [self.kmlParser points];
    
    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.
    MKMapRect flyTo = MKMapRectNull;
    for (id <MKOverlay> overlay in overlays) {
        if (MKMapRectIsNull(flyTo)) {
            flyTo = [overlay boundingMapRect];
        } else {
            flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
        }
    }
    
    for (id <MKAnnotation> annotation in annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    // Position the map so that all overlays and annotations are visible on screen.
    self.map.visibleMapRect = flyTo;
}

- (void)showKMLData
{
    NSArray *overlays = [self.kmlParser overlays];
    NSArray *annotations = [self.kmlParser points];
    
    [self.map addOverlays:overlays];
    [self.map addAnnotations:annotations];
}

- (void)hideKMLData
{
    NSArray *overlays = [self.kmlParser overlays];
    NSArray *annotations = [self.kmlParser points];
    
    [self.map removeOverlays:overlays];
    [self.map removeAnnotations:annotations];
}

// ------------------------------------
// MapView Delelegate
// ------------------------------------

#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [self.kmlParser viewForOverlay:overlay];
}

- (void)hideInfoView
{
    self.infoView.hidden = true;
}
- (void)showInfoView
{
    self.infoView.hidden = false;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didDeselectAnnotationView");
    if ([view.annotation isKindOfClass:[MarkerAnnotation class]]) {
        [self hideInfoView];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didSelectAnnotationView");
    if ([view.annotation isKindOfClass:[MarkerAnnotation class]]) {
        
        MarkerAnnotation *markerAnnotation = (MarkerAnnotation*)view.annotation;
        self.labelAddress.text = markerAnnotation.address;
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker trackEventWithCategory:@"ui"
                             withAction:@"Station sélectionnée"
                              withLabel:markerAnnotation.name
                              withValue:nil];
                
        /*[UIView beginAnimations:@"fade in" context:nil];
        [UIView setAnimationDuration:3.0];
        
        [UIView commitAnimations];*/
        [self showInfoView];

        CLLocation *loc = self.map.userLocation.location;
        if (loc)
        {
            self.labelDistance.text = @"Calcul en cours...";
            NSString *coordUser = [[NSString alloc] initWithFormat:@"%f,%f",
                                loc.coordinate.latitude, loc.coordinate.longitude];
            NSString *coordMarker = [[NSString alloc] initWithFormat:@"%f,%f",
                                markerAnnotation.coordinate.latitude, markerAnnotation.coordinate.longitude];
            
            NSDate *startTime = [NSDate date];
            [self calculateDistanceFrom:coordUser to:coordMarker callback:
             ^(NSURLResponse *res, NSData *data, NSError *err)
             {
                 NSTimeInterval elapsedTime = -[startTime timeIntervalSinceNow];
                 id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                 [tracker trackTimingWithCategory:@"internet" withValue:elapsedTime withName:@"load distance from google" withLabel:nil];
                 
                 if (err) {
                     NSLog(@"ERROR : calcul distance : %@", err);
                     id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                     [tracker trackException:NO // Boolean indicates non-fatal exception.
                             withDescription:@"Calcul distance : %@", err];
                     self.labelDistance.text = @"Calcul impossible, erreur connexion :(";
                 } else {
                     SMXMLDocument *document = [SMXMLDocument documentWithData:data error:nil];
                     SMXMLElement *root = document.root;
                     BOOL isOK = [[[root childNamed:@"status"] value] isEqualToString:@"OK"];
                     if (isOK)
                     {
                         NSArray *rows = [root childrenNamed:@"row"];
                         NSString *duration = 0;
                         NSString *distance = 0;
                         for (SMXMLElement *row in rows)
                         {
                             SMXMLElement *element = [row childNamed:@"element"];
                             if([[[element childNamed:@"status"] value] isEqualToString:@"OK"])
                             {
                                 duration = [[[element childNamed:@"duration"] childNamed:@"text"] value];
                                 distance = [[[element childNamed:@"distance"] childNamed:@"text"] value];
                             }
                         }
                         if (duration && distance) {
                             NSString *txtDistance = [[NSString alloc] initWithFormat:@"%@, %@", distance, duration];
                             self.labelDistance.text = txtDistance;
                         } else {
                             self.labelDistance.text = @"Itinéraire introuvable";
                         }
                     }
                     else
                     {
                         self.labelDistance.text = @"Calcul impossible, erreur serveur :(";
                     }
                 }
             }];
        }
        else
        {
            self.labelDistance.text = @"Position GPS indéterminée";
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // user location
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
    
    // station
	if ([annotation isKindOfClass:[MarkerAnnotation class]]) {
        
        NSString *imageName;
        MarkerAnnotation *markerAnnotation = (MarkerAnnotation*)annotation;
        int nbVelos = markerAnnotation.velos;
        int nbPlaces = markerAnnotation.places;
        int number = self.isVeloView ? nbVelos : nbPlaces;
        
        if (number >= 0)
        {
            NSString *formatVelos;
            if (nbVelos == 0) {
                formatVelos = @"aucun vélo";
            } else if (nbVelos == 1) {
                formatVelos = @"1 vélo";
            } else if (nbVelos > 1) {
                formatVelos = [[NSString alloc] initWithFormat:@"%d vélos", nbVelos];
            }
            
            NSString *formatPlaces;
            if (nbPlaces == 0) {
                formatPlaces = @"aucune place";
            } else if (nbPlaces == 1) {
                formatPlaces = @"1 place";
            } else if (nbPlaces > 1) {
                formatPlaces = [[NSString alloc] initWithFormat:@"%d places", nbPlaces];
            }
            
            NSString *formatSubtitle = [[NSString alloc] initWithFormat:@"%@, %@", formatVelos, formatPlaces];
            markerAnnotation.subtitle = formatSubtitle;
            
            if (number == 0) {
                imageName = @"pin_0.png";
            } else if (number == 1) {
                imageName = @"pin_1.png";
            } else if (number == 2) {
                imageName = @"pin_2.png";
            } else if (number == 3) {
                imageName = @"pin_3.png";
            } else if (number == 4) {
                imageName = @"pin_4.png";
            } else if (number == 5) {
                imageName = @"pin_5.png";
            } else if (number > 5) {
                imageName = @"pin_5+.png";
            }
        }
        else
        {
            imageName = @"pin_empty.png";
            markerAnnotation.subtitle = @"";
        }
        
        if (markerAnnotation.open == 0)
        {
            imageName = @"pin_closed.png";
            markerAnnotation.subtitle = @"Station fermée";
        }
        
        if (markerAnnotation.state == 3) {
            imageName = @"pin_surprise.png";
            markerAnnotation.subtitle = @"Erreur connexion ?";
        }
        
		// try to dequeue an existing pin view first
		MKAnnotationView* pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:imageName];
        
		if (!pinView) {
            
            MKAnnotationView *annView = [[MKAnnotationView alloc ] initWithAnnotation:annotation reuseIdentifier:imageName];
            
            annView.image = [ UIImage imageNamed:imageName ];
            UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            //[infoButton addTarget:self action:@selector(showDetailsView)
              //   forControlEvents:UIControlEventTouchUpInside];
            annView.rightCalloutAccessoryView = nil;
            annView.canShowCallout = YES;
                        
			return annView;
		} else {
			pinView.annotation = annotation;
		}
        
		return pinView;
	}
    
    // map
    return [self.kmlParser viewForAnnotation:annotation];
}

- (bool)annotationIsInsideScreen:(MarkerAnnotation*)annotation
{
    CLLocationCoordinate2D centerLocation = self.map.region.center;
    if (isnan(centerLocation.latitude) || isnan(centerLocation.longitude))
        return false;
    
    float delta = 0.0065;
    double lat = [annotation coordinate].latitude;
    double lng = [annotation coordinate].longitude;
    
    BOOL insideScreen = !(
                          lng > centerLocation.longitude+delta ||
                          lng < centerLocation.longitude-delta ||
                          lat > centerLocation.latitude+delta-0.0005 ||
                          lat < centerLocation.latitude-delta-0.0005);
    
    return insideScreen;
}

- (void)retriveMoreInfoForAnnotation:(MarkerAnnotation*)annotation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
    self.nbConnections++;
    
    NSDate *startTime = [NSDate date];
    [self moreAboutStationNumber:annotation.stationNumber callback:
     ^(NSURLResponse *res, NSData *data, NSError *err)
     {
         NSTimeInterval elapsedTime = -[startTime timeIntervalSinceNow];
         id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
         [tracker trackTimingWithCategory:@"internet" withValue:elapsedTime withName:@"load station" withLabel:nil];
         
         self.nbConnections--;
         if (self.nbConnections == 0) {
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
         }
         
         if (err) {
             NSLog(@"ERROR : chargement infos sur une station : %@", err);
             annotation.state = 3;
             [tracker trackException:NO // Boolean indicates non-fatal exception.
                     withDescription:@"Erreur chargement station : %@", err];
         } else {
             // XML explore
             NSError *nserror = [NSError alloc];
             SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&nserror];
             SMXMLElement *root = document.root;
             annotation.velos = [[[root childNamed:@"available"] value] integerValue];
             annotation.places = [[[root childNamed:@"free"] value] integerValue];
             annotation.total = [[[root childNamed:@"total"] value] integerValue];
             annotation.open = [[[root childNamed:@"open"] value] integerValue];
             annotation.updated = [[[root childNamed:@"updated"] value] integerValue];
             annotation.connected = [[[root childNamed:@"connected"] value] integerValue];
             annotation.state = 2;
         }
         
         [self.map removeAnnotation:annotation];
         [self.map addAnnotation:annotation];
     }];
}

- (void)mapView:mapView regionDidChangeAnimated:(BOOL)animated
{
    [self updateMapView];
}

- (void)mapView:mapView regionWillChangeAnimated:(BOOL)animated
{
    [self updateMapView];
}

- (void)updateMapView
{
    MKCoordinateSpan span = [self.map region].span;
    double lat = span.latitudeDelta;
    if (lat == 0) return;
    
    if (lat <= 0.022985) {
        [self hideKMLData];
        [self.map addAnnotations:self.markerAnnotationArr];
        [self loadStationsDetails];
    } else {
        [self.map removeAnnotations:self.markerAnnotationArr];
        [self showKMLData];
    }
    NSLog(@"Delta lat: %f", lat);
}

- (void)loadStationsDetails
{
    int nbAnnotationLoading = 0;
    
    NSArray *annotations = self.map.annotations;
    for (MarkerAnnotation *annotation in annotations)
    {
        if (nbAnnotationLoading > 30) {
            NSLog(@"Trop de stations à charger !");
            return;
        }
        
        if ([annotation isKindOfClass:[MarkerAnnotation class]]) {
            if ([self annotationIsInsideScreen:annotation] && annotation.state < 1) {
                annotation.state = 1;
                nbAnnotationLoading++;
                [self retriveMoreInfoForAnnotation:annotation];
            }
        }
    }
    
    NSLog(@"Nb stations à charger : %d", nbAnnotationLoading);
}

// ------------------------------------
// Get more about station
// ------------------------------------

- (void)moreAboutStationNumber:(NSInteger)number callback:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    // URL
    NSString *url = @"http://www.velib.paris.fr/service/stationdetails/paris/%d";
    NSString *queryURL = [NSString stringWithFormat:url, number];
    NSURL *nsURL = [NSURL URLWithString:queryURL];
    
    // Get content of film
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsURL                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:handler];
}

- (void)calculateDistanceFrom:(NSString*)src to:(NSString*)dst callback:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    // URL
    NSString *url = @"http://maps.googleapis.com/maps/api/distancematrix/xml?origins=%@&destinations=%@&language=fr-FR&sensor=false";
    NSString *queryURL = [NSString stringWithFormat:url, src, dst];
    NSURL *nsURL = [NSURL URLWithString:queryURL];
    
    // Get content of film
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsURL                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:handler];
}
// ------------------------------------
// Parse carto 
// ------------------------------------

- (void)parseCarto
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"xml"];
    NSData *stationsXML = [[NSData alloc] initWithContentsOfFile:path];
    
    SMXMLDocument *document = [SMXMLDocument documentWithData:stationsXML error:nil];
    SMXMLElement *root = document.root;
    NSArray *markers = [[root childNamed:@"markers"] childrenNamed:@"marker"];
    
    for (SMXMLElement *marker in markers) {
        double lat = [[marker attributeNamed:@"lat"] doubleValue];
        double lng = [[marker attributeNamed:@"lng"] doubleValue];
        NSString *markerName = [[marker attributeNamed:@"name"] substringFromIndex:8];
        NSString *markerAddr = [marker attributeNamed:@"fullAddress"];
        NSInteger markerNumber = [[marker attributeNamed:@"number"] integerValue];
        
        CLLocation *location = [[CLLocation alloc]
                                initWithLatitude:lat
                                longitude:lng
                                ];
        
        MarkerAnnotation *annotation = [[MarkerAnnotation alloc] init];
        annotation.title = markerName;
        annotation.name = markerName;
        annotation.subtitle = markerAddr;
        annotation.address = markerAddr;
        annotation.coordinate = [location coordinate];
        annotation.stationNumber = markerNumber;
        
        [self.map addAnnotation:annotation];
        [self.markerAnnotationArr addObject:annotation];
    }
}

- (void) reinitAnnotations
{
    NSArray *annotations = self.markerAnnotationArr;
    [self.map removeAnnotations:[self.map annotations]];
    for (MarkerAnnotation *annotation in annotations)
    {
        [annotation init];
    }
    [self.map addAnnotations:annotations];
    [self updateMapView];
}

- (void)showStations
{
    NSArray *stationsArr = [NSArray arrayWithArray:self.stations];
    [self.map addAnnotations:stationsArr];
}

- (void)hideStations
{
    NSArray *stationsArr = [NSArray arrayWithArray:self.stations];
    [self.map removeAnnotations:stationsArr];
}

// ------------------------------------
// Memory & unload
// ------------------------------------

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    
    [self setMap:nil];
    [self setBar:nil];
    [self setViewMode:nil];
    [self setLabelAddress:nil];
    [self setLabelDistance:nil];
    [self setInfoView:nil];
    [self setMapButton:nil];
    [super viewDidUnload];
}
@end
