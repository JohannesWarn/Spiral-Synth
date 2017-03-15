//
//  ToneGeneratorViewController.h
//  Audio Test
//
//  Created by Johannes Wärn on 30/06/16.
//  Copyright © 2016 Johannes Wärn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToneGeneratorViewController : UIViewController

- (void)playFrequency:(double)newFrequency forTouch:(UITouch *)touch;

@end

