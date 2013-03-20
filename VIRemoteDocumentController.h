//
//  VIExternalFileUtil.h
//
//  Created by Thomas Fallon on 3/20/13.
//

#import <UIKit/UIKit.h>


typedef void(^Completion)(BOOL success, id object);

@interface VIRemoteDocumentController : NSObject <UIDocumentInteractionControllerDelegate> {

}

//Completion fires on successful presentation of UIDocumentInteractionController
//Or on Error during presentation
@property (nonatomic, strong) Completion completion;

//All other interactions should be handled through the UIDocumentInteractionControllerDelegate
@property (nonatomic, strong) id<UIDocumentInteractionControllerDelegate> delegate;

@property (nonatomic, strong) UIDocumentInteractionController *controller;
@property (nonatomic, assign) CGPoint displayPoint;

//These will return nil on success.
- (void)openWith:(NSURL*)url
   forController:(UIViewController*)cont
         atPoint:(CGPoint)point
      completion:(void (^)(BOOL success, NSError *err))completion;

- (void)openWith:(NSURL*)url
   forController:(UIViewController*)cont
      completion:(void (^)(BOOL success, NSError *err))completion;

- (NSError*)cleanupTempFile:(UIDocumentInteractionController *)controller;

+ (NSString *)applicationDocumentsDirectory;
+ (BOOL)shouldHandleFileRequest:(NSURLRequest*)urlRequest;
+ (VIRemoteDocumentController *)getInstance;
@end
