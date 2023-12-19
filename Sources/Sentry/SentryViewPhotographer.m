#import "SentryViewPhotographer.h"

@implementation SentryViewPhotographer {
    Class _CGDrawingViewClass;
    Class _UIShapeHitTestingView;
    Class _UIGraphicsView;
    Class _ImageLayer;
}

+(SentryViewPhotographer *)shared {
    static SentryViewPhotographer* _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[SentryViewPhotographer alloc] init];
    });
        
    return _shared;
}

-(instancetype)init {
    if (self = [super init]) {
        _CGDrawingViewClass = NSClassFromString(@"_TtCOCV7SwiftUI11DisplayList11ViewUpdater8Platform13CGDrawingView");
        _UIShapeHitTestingView = NSClassFromString(@"_TtC7SwiftUIP33_A34643117F00277B93DEBAB70EC0697122_UIShapeHitTestingView");
        _UIGraphicsView = NSClassFromString(@"SwiftUI._UIGraphicsView");
        _ImageLayer = NSClassFromString(@"SwiftUI.ImageLayer");
    }
    return self;
}

-(UIImage*)imageFromUIView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    
    [self maskText:view context:currentContext];
    
    
    UIImage* screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenshot;
}

- (void)maskText:(UIView *)view context:(CGContextRef)context {
//    CGRect mask = [view convertRect:view.bounds toView:nil];
//    CGRect tfRect = CGRectMake(52,111, 299, 19);
//    //x = 52, y = 111), size = (width = 299, height = 19)
//    if (CGRectIntersectsRect(mask, tfRect)) {
//        NSLog(@"intersection");
//    }cdcds
//
//    if ([view isKindOfClass:UITextField.class]) {
//        NSLog(@"dae");
//    }
//    
//    if ([self shouldRedact:view]) {
//        [UIColor.orangeColor setStroke];
//        CGContextSetLineWidth(context, 4);
//        CGContextStrokeRect(context, mask);
//    //  CGContextFillRect(context, mask);
//    } else {
//        if ([self isOpaqueOrHasBackground:view]) {
//            [UIColor.greenColor setStroke];
//            CGContextSetLineWidth(context, 2);
//            CGContextStrokeRect(context, mask);
//        }
//        for (UIView * child in view.subviews) {
//            [self maskText:child context:context];
//        }
//    }

    [UIColor.blackColor setFill];
    CGPathRef maskPath = [self buildPathForView:view inPath:CGPathCreateMutable()];
    CGContextAddPath(context, maskPath);
    CGContextFillPath(context);
}

- (BOOL)shouldIgnoreView:(UIView *)view {
    return [view isKindOfClass:UISwitch.class];
}

- (BOOL)shouldRedact:(UIView *)view {
    return !view.isHidden && view.alpha > 0 && (
    [view isKindOfClass:UILabel.class]
    || [view isKindOfClass:UITextField.class]
    || [view isKindOfClass:UITextView.class]
    || [view isKindOfClass:_CGDrawingViewClass]
    || [view isKindOfClass:_UIShapeHitTestingView]
    || ([view isKindOfClass:_UIGraphicsView] && [view.layer isKindOfClass:_ImageLayer])
    || ([view isKindOfClass:UIImageView.class] && [self shouldRedactImageView:(UIImageView *)view])
                             );
}

- (BOOL)shouldRedactImageView:(UIImageView *)imageView {
    return imageView.image != nil
    && [imageView.image.imageAsset valueForKey:@"_containingBundle"] == nil
    && (imageView.image.size.width > 10 && imageView.image.size.height > 10); //This is to avoid redact gradient backgroud that are usually small lines repeating
}

- (CGMutablePathRef)buildPathForView:(UIView *)view inPath:(CGMutablePathRef)path {
    CGRect rectInWindow = [view convertRect:view.bounds toView:nil];
       
    if ([self shouldRedact:view]) {
        CGPathAddRect(path, NULL, rectInWindow);
    } else if ([self isOpaqueOrHasBackground:view]) {
        CGMutablePathRef newPath = [self excludeRect:rectInWindow fromPath:path];
        CGPathRelease(path);
        path = newPath;
    }

    for (UIView *subview in view.subviews) {
        path = [self buildPathForView:subview inPath:path];
    }
    
    return path;
}

- (CGMutablePathRef) excludeRect:(CGRect)rectangle fromPath:(CGMutablePathRef)path {
    if (@available(iOS 16.0, *)) {
        CGPathRef exclude = CGPathCreateWithRect(rectangle, nil);
        CGPathRef newPath = CGPathCreateCopyBySubtractingPath(path, exclude, YES);
        return CGPathCreateMutableCopy(newPath);
    } 
    return path;
}

- (BOOL)isOpaqueOrHasBackground:(UIView *)view {
    return (view.isOpaque || (view.backgroundColor != nil && CGColorGetAlpha(view.backgroundColor.CGColor) > 0.9));
}

@end
  
