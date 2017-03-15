//
//  KeyboardView.m
//  Audio Test
//
//  Created by Johannes Wärn on 30/06/16.
//  Copyright © 2016 Johannes Wärn. All rights reserved.
//

#import "KeyboardView.h"
#import "ToneGeneratorViewController.h"

@implementation KeyboardView

- (void)setScale:(NSArray *)scale
{
    _scale = scale;
    [self setNeedsDisplay];
}

- (double)frequencyForPoint:(CGPoint)point
{
    if (!self.scale) { return 0.0; }
    
    double x = (point.x - self.bounds.size.width / 2.0) / self.bounds.size.width;
    double y = (point.y - self.bounds.size.height / 2.0) / self.bounds.size.width;
    double angle = atan2(y, x);
    double distance = sqrt(pow(x, 2) + pow(y, 2));
    
    double trueDistance = distance * self.bounds.size.width;
    
    int numberOfTones = 12;
    
    double normalisedAngle = angle / (M_PI * 2.0) + 0.5;
    int step = normalisedAngle * _scale.count;
    if (step > _scale.count-1) { step = _scale.count-1; }
    double tone = [[_scale objectAtIndex:step] doubleValue];
    int toneStep = floor((trueDistance - normalisedAngle * 60.0) / 60.0) - 1;
    
    /*
     The basic formula for the frequencies of the notes of the equal tempered scale is given by
     fn = f0 * (a)n
     where
     f0 = The frequency of one fixed note which must be defined.
     n = The number of half steps away from the fixed note you are.
     fn = The frequency of the note n half steps away.
     a = (2)^(1/12), the number which when multiplied by itself 12 times equals 2 = 1.059463094359...
     */
    
    double a = 1.059463094;
    double n = tone + toneStep * numberOfTones;
    double frequency = 440.0 * pow(a, n);
    
    return frequency;
    
    /*
     double x = (point.x - self.bounds.size.width / 2.0) / self.bounds.size.width;
     double y = (point.y - self.bounds.size.height / 2.0) / self.bounds.size.width;
     double angle = atan2(y, x);
     double distance = sqrt(pow(x, 2) + pow(y, 2));
     
     double trueDistance = distance * self.bounds.size.width;
     
     double normalisedAngle = angle / (M_PI * 2.0) + 0.5;
     double baseTones[8] = {261.626, 293.665, 329.628, 349.228, 391.995, 415.305, 440, 493.883};
     double outerBaseTones[8] = {261.626, 293.665, 329.628, 349.228, 391.995, 415.305, 440, 493.883};
     int tone = normalisedAngle * 8;
     int toneStep = floor((trueDistance - (normalisedAngle * 2.0 - 1.0) * 60.0) / 60.0) - 4;
     
     double baseTone = toneStep % 2 ? baseTones[tone] : 440.0 * pow(pow(2.0, 1.0/8.0), fmod(tone, 8));
     double frequency = baseTone * pow(2, toneStep / 2);// * (1 - 0.01 * (fmod(trueDistance - normalisedAngle*60.0, 60.0) / 60.0));
     
     return frequency;
     */
}

- (void)handleTouches:(NSSet<UITouch *> *)touches
{
    for (UITouch *touch in touches) {
        CGPoint point = [touch locationInView:self];
        [self.toneGenerator playFrequency:[self frequencyForPoint:point] forTouch:touch];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self handleTouches:touches];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self handleTouches:touches];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        [self.toneGenerator playFrequency:0.0 forTouch:touch];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)drawRect:(CGRect)rect
{
    CGRect pixel = CGRectMake(0.0, 0.0, 0.5, 0.5);
    for (double x = rect.origin.x; x < rect.size.width; x += 0.5) {
        pixel.origin.x = x;
        for (double y = rect.origin.y; y < rect.size.height; y += 0.5) {
            pixel.origin.y = y;
            
            double frequency = [self frequencyForPoint:pixel.origin];
            
            // base freqencies should be in the range [55.0, 110.0]
            double baseFrequency = frequency;
            while (baseFrequency > 110.0) {
                baseFrequency /= 2;
            }
            
            [[UIColor colorWithHue:(baseFrequency-55.0) / (110.0-55.0) saturation:0.8+frequency/8000.0 brightness:0.4+sqrt(frequency)/100.0 alpha:1.0] setFill];
            UIRectFill(pixel);
        }
    }
}

@end
