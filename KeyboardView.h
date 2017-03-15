//
//  KeyboardView.h
//  Audio Test
//
//  Created by Johannes Wärn on 30/06/16.
//  Copyright © 2016 Johannes Wärn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ToneGeneratorViewController;

@interface KeyboardView : UIView

@property (nonatomic, weak) ToneGeneratorViewController *toneGenerator;
@property (nonatomic) NSArray *scale;

@end
