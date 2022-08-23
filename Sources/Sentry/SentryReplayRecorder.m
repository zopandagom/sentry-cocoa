//
//  SentryReplayRecorder.m
//  Sentry
//
//  Created by Indragie Karunaratne on 8/22/22.
//  Copyright © 2022 Sentry. All rights reserved.
//

#import "SentryReplayRecorder.h"
#import "SentrySwizzle.h"
#import "SentryUIApplication.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSDictionary<NSString *, id> *
serializeCGPoint(CGPoint point)
{
    return @{@"x" : @(point.x), @"y" : @(point.y)};
}

static NSDictionary<NSString *, id> *
serializeCGSize(CGSize size)
{
    return @{@"width" : @(size.width), @"height" : @(size.height)};
}

static NSDictionary<NSString *, id> *
serializeCGRect(CGRect rect)
{
    return @ { @"origin" : serializeCGPoint(rect.origin), @"size" : serializeCGSize(rect.size) };
}

static NSDictionary<NSString *, id> *
serializeUIColor(UIColor *color)
{
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    const unsigned int rgb
        = (unsigned int)(r * 255) << 16 | (unsigned int)(g * 255) << 8 | (unsigned int)(b * 255);
    return @{@"color" : [NSString stringWithFormat:@"#%06x", rgb], @"alpha" : @(a)};
}

static NSDictionary<NSString *, id> *
serializeUIFont(UIFont *font)
{
    return @{
        @"familyName" : font.familyName,
        @"fontName" : font.fontName,
        @"pointSize" : @(font.pointSize)
    };
}

static NSString *
serializeContentMode(UIViewContentMode contentMode)
{
    switch (contentMode) {
    case UIViewContentModeScaleAspectFit:
        return @"scaleAspectFit";
    case UIViewContentModeScaleToFill:
        return @"scaleToFill";
    case UIViewContentModeScaleAspectFill:
        return @"scaleAspectFill";
    case UIViewContentModeTop:
        return @"top";
    case UIViewContentModeLeft:
        return @"left";
    case UIViewContentModeRight:
        return @"right";
    case UIViewContentModeBottom:
        return @"bottom";
    case UIViewContentModeCenter:
        return @"center";
    case UIViewContentModeRedraw:
        return @"redraw";
    case UIViewContentModeTopLeft:
        return @"topLeft";
    case UIViewContentModeTopRight:
        return @"topRight";
    case UIViewContentModeBottomLeft:
        return @"bottomLeft";
    case UIViewContentModeBottomRight:
        return @"bottomRight";
    default:
        return @"";
    }
}

static NSString *
serializeTextAlignment(NSTextAlignment alignment)
{
    switch (alignment) {
    case NSTextAlignmentCenter:
        return @"center";
    case NSTextAlignmentRight:
        return @"right";
    case NSTextAlignmentLeft:
        return @"left";
    case NSTextAlignmentNatural:
        return @"natural";
    case NSTextAlignmentJustified:
        return @"justified";
    default:
        return @"";
    }
}

@protocol SentryIntrospectableView <NSObject>
- (NSDictionary<NSString *, id> *)introspect_getAttributes;
@end

@interface
UIView (SentryReplay) <SentryIntrospectableView>
@end

@implementation
UIView (SentryReplay)
- (NSDictionary<NSString *, id> *)introspect_getAttributes
{
    NSMutableDictionary<NSString *, id> *const attributes =
        [NSMutableDictionary<NSString *, id> dictionary];
    attributes[@"frame"] = serializeCGRect(self.frame);
    if (self.alpha != 1.0) {
        attributes[@"alpha"] = @(self.alpha);
    }
    if (self.contentMode != UIViewContentModeScaleToFill) {
        attributes[@"contentMode"] = serializeContentMode(self.contentMode);
    }
    if (self.backgroundColor != nil) {
        attributes[@"backgroundColor"] = serializeUIColor(self.backgroundColor);
    }
    return attributes;
}
@end

@interface
UILabel (SentryReplay) <SentryIntrospectableView>
@end

@implementation
UILabel (SentryReplay)
- (NSDictionary<NSString *, id> *)introspect_getAttributes
{
    NSMutableDictionary<NSString *, id> *const attributes =
        [NSMutableDictionary<NSString *, id> dictionary];
    [attributes addEntriesFromDictionary:[super introspect_getAttributes]];
    if (self.text != nil) {
        attributes[@"text"] = self.text;
    }
    attributes[@"font"] = serializeUIFont(self.font);
    attributes[@"textColor"] = serializeUIColor(self.textColor);
    attributes[@"textAlignment"] = serializeTextAlignment(self.textAlignment);
    return attributes;
}
@end

@interface
UIButton (SentryReplay) <SentryIntrospectableView>
@end

@implementation
UIButton (SentryReplay)
- (NSDictionary<NSString *, id> *)introspect_getAttributes
{
    NSMutableDictionary<NSString *, id> *const attributes =
        [NSMutableDictionary<NSString *, id> dictionary];
    [attributes addEntriesFromDictionary:[super introspect_getAttributes]];
    if (self.currentTitle != nil) {
        attributes[@"title"] = self.currentTitle;
    }
    if (self.currentTitleColor != nil) {
        attributes[@"titleColor"] = serializeUIColor(self.currentTitleColor);
    }
    return attributes;
}
@end

@implementation SentryReplayRecorder {
    NSUInteger _nodeID;
}

- (instancetype)init
{
    if (self = [super init]) {
        _nodeID = 0;
    }
    return self;
}

- (void)startRecording
{
    NSNotificationCenter *const nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(windowDidBecomeKey:)
               name:UIWindowDidBecomeKeyNotification
             object:nil];
//    swizzleLayoutSubviews(
//        ^(UIView *swizzeldSelf) { NSLog(@"[REPLAY] RELAYOUT %@", swizzeldSelf); });
    swizzleDidAddSubview(^(UIView *__unsafe_unretained superview, UIView *subview) {
        NSLog(@"[REPLAY] PARENT %@ ADDED %@", superview, subview);
    });
    swizzleWillRemoveSubview(^(UIView *__unsafe_unretained superview, UIView *subview) {
        NSLog(@"[REPLAY] PARENT %@ REMOVED %@", superview, subview);
    });
}

- (void)stopRecording
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    UIWindow *const keyWindow = (UIWindow *)notification.object;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{ [self serializeReplayForWindow:keyWindow]; });
}

- (NSUInteger)nextNodeID
{
    return ++_nodeID;
}

static void *kNodeIDAssociatedObjectKey = &kNodeIDAssociatedObjectKey;

- (NSNumber *)idForNode:(id)node
{
    NSNumber *nodeID = objc_getAssociatedObject(node, kNodeIDAssociatedObjectKey);
    if (nodeID == nil) {
        nodeID = @([self nextNodeID]);
        objc_setAssociatedObject(
            node, kNodeIDAssociatedObjectKey, nodeID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return nodeID;
}

- (void)serializeReplayForWindow:(UIWindow *)window
{
    NSMutableArray<NSDictionary<NSString *, id> *> *const replay =
        [NSMutableArray<NSDictionary<NSString *, id> *> array];
    const CGRect screenBounds = window.screen.bounds;
    NSNumber *const timestamp = getCurrentTimestamp();
    [replay addObject:@{
        @"type" : @4,
        @"data" :
            @ { @"width" : @(screenBounds.size.width), @"height" : @(screenBounds.size.height) },
        @"timestamp" : timestamp,
    }];
    NSNumber *const screenID = [self idForNode:window.screen];
    NSMutableArray<NSDictionary<NSString *, id> *> *const childNodes =
        [NSMutableArray<NSDictionary<NSString *, id> *> array];
    NSDictionary<NSString *, id> *const serializedWindow = [self serializeViewHierarchy:window];
    if (serializedWindow != nil) {
        [childNodes addObject:serializedWindow];
    }
    [replay addObject:@{
        @"type" : @2,
        @"data" : @ {
            @"node" : @ {
                @"type" : @0,
                @"childNodes" : childNodes,
                @"id" : screenID,
            }
        },
        @"timestamp" : timestamp
    }];

    NSData *data = [NSJSONSerialization dataWithJSONObject:replay options:0 error:nil];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"replay.json"];
    [data writeToFile:path atomically:YES];
    NSLog(@"[REPLAY] PATH: %@", path);
}

- (NSDictionary<NSString *, id> *)serializeViewHierarchy:(UIView *)view
{
    if (view == nil || view.isHidden || view.alpha == 0.0) {
        return nil;
    }
    NSMutableDictionary<NSString *, id> *const node =
        [NSMutableDictionary<NSString *, id> dictionary];
    node[@"type"] = @2;
    node[@"id"] = [self idForNode:view];
    node[@"viewClass"] = NSStringFromClass(view.class);
    node[@"attributes"] = [view introspect_getAttributes];

    NSMutableArray<NSDictionary<NSString *, id> *> *const childNodes =
        [NSMutableArray<NSDictionary<NSString *, id> *> array];
    for (UIView *subview in view.subviews) {
        NSDictionary<NSString *, id> *const childNode = [self serializeViewHierarchy:subview];
        if (childNode != nil) {
            [childNodes addObject:childNode];
        }
    }
    node[@"childNodes"] = childNodes;
    return node;
}

// static UIWindow *getKeyWindow() {
//     SentryUIApplication *const app = [[SentryUIApplication alloc] init];
//     for (UIWindow *window in app.windows) {
//         if (window.isKeyWindow) {
//             return window;
//         }
//     }
//     return nil;
// }

//static void
//swizzleLayoutSubviews(void (^block)(__unsafe_unretained UIView *))
//{
//    const SEL selector = @selector(layoutSubviews);
//    [SentrySwizzle
//        swizzleInstanceMethod:selector
//                      inClass:[UIView class]
//                newImpFactory:^id(SentrySwizzleInfo *swizzleInfo) {
//                    return ^void(__unsafe_unretained id self) {
//                        void (*originalIMP)(__unsafe_unretained id, SEL);
//                        originalIMP
//                            = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
//                        originalIMP(self, selector);
//                        block((UIView *)self);
//                    };
//                }
//                         mode:SentrySwizzleModeAlways
//                          key:NULL];
//}

static NSNumber *getCurrentTimestamp() {
    return @([[NSDate date] timeIntervalSince1970]);
}

static void swizzleDidAddSubview(void (^block)(__unsafe_unretained UIView *superview, UIView *subview)) {
    const SEL selector = @selector(didAddSubview:);
    [SentrySwizzle
        swizzleInstanceMethod:selector
                      inClass:[UIView class]
                newImpFactory:^id(SentrySwizzleInfo *swizzleInfo) {
                    return ^void(__unsafe_unretained id self, id subview) {
                        void (*originalIMP)(__unsafe_unretained id, SEL, id);
                        originalIMP
                            = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
                        originalIMP(self, selector, subview);
                        block((UIView *)self, (UIView *)subview);
                    };
                }
                         mode:SentrySwizzleModeAlways
                          key:NULL];
}

static void swizzleWillRemoveSubview(void (^block)(__unsafe_unretained UIView *superview, UIView *subview)) {
    const SEL selector = @selector(willRemoveSubview:);
    [SentrySwizzle
        swizzleInstanceMethod:selector
                      inClass:[UIView class]
                newImpFactory:^id(SentrySwizzleInfo *swizzleInfo) {
                    return ^void(__unsafe_unretained id self, id subview) {
                        void (*originalIMP)(__unsafe_unretained id, SEL, id);
                        originalIMP
                            = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
                        originalIMP(self, selector, subview);
                        block((UIView *)self, (UIView *)subview);
                    };
                }
                         mode:SentrySwizzleModeAlways
                          key:NULL];
}

@end
