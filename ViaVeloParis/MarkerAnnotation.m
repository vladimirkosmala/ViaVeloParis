//
//  MarkerAnnotation
//  ViaVeloParis
//
//  Created by Vladimir Kosmala on 25/09/12.
//  Copyright (c) 2012 Vladimir Kosmala. All rights reserved.
//

#import "MarkerAnnotation.h"

@implementation MarkerAnnotation


- (id) init
{
    self.velos = -1;
    self.places = -1;
    self.open = -1;
    self.state = 0;
    
    return self;
}

@end