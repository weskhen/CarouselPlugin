//
//  WeakTimerTarget.m
//  PaoBa
//
//  Created by wujian on 4/18/16.
//  Copyright © 2016 wesk痕. All rights reserved.
//

#import "WeakTimerTarget.h"

//suppress warnning
#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

@interface WeakTimerTarget ()

@property (nonatomic, weak)     id target;
@property (nonatomic, assign)   SEL selector;
@property (nonatomic, weak)     NSTimer* timer;

@end
@implementation WeakTimerTarget

- (void)timerDidFire:(NSTimer *)timer {
    if(self.target) {
        SuppressPerformSelectorLeakWarning(
                                           [self.target performSelector:self.selector withObject:timer.userInfo];
                                           );
    } else {
        [self.timer invalidate];
    }
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                     target:(id)aTarget
                                   selector:(SEL)aSelector
                                   userInfo:(id)userInfo
                                    repeats:(BOOL)repeats {
    WeakTimerTarget* timerTarget = [[WeakTimerTarget alloc] init];
    timerTarget.target = aTarget;
    timerTarget.selector = aSelector;
    timerTarget.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                         target:timerTarget
                                                       selector:@selector(timerDidFire:)
                                                       userInfo:userInfo
                                                        repeats:repeats];
    
    //为了避免scroll滚动时 计时器不起作用
//    [[NSRunLoop currentRunLoop] addTimer:timerTarget.timer forMode:UITrackingRunLoopMode];
    return timerTarget.timer;
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                            target:(id)aTarget
                          selector:(SEL)aSelector
                          userInfo:(id)userInfo
                           repeats:(BOOL)repeats {
    WeakTimerTarget* timerTarget = [[WeakTimerTarget alloc] init];
    timerTarget.target = aTarget;
    timerTarget.selector = aSelector;
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval
                                             target:timerTarget
                                           selector:@selector(timerDidFire:)
                                           userInfo:userInfo
                                            repeats:repeats];
    [timer fire];
    timerTarget.timer = timer;
    return timer;
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                      block:(TimerHandler)block
                                   userInfo:(id)userInfo
                                    repeats:(BOOL)repeats {
    return [self scheduledTimerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(timerBlockInvoke:)
                                       userInfo:@[[block copy], userInfo]
                                        repeats:repeats];
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                             block:(TimerHandler)block
                          userInfo:(id)userInfo
                           repeats:(BOOL)repeats
{
    return [self timerWithTimeInterval:interval
                                target:self
                              selector:@selector(timerBlockInvoke:)
                              userInfo:@[[block copy], userInfo]
                               repeats:repeats];
}


+ (void)timerBlockInvoke:(NSArray*)userInfo {
    TimerHandler block = userInfo[0];
    id info = userInfo[1];
    if (block) {
        block(info);
    }
}
@end
