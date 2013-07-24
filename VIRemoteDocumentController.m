//
//  VIExternalFileUtil.h
//
//  Created by Thomas Fallon on 3/20/13.
//

#import "VIRemoteDocumentController.h"
#import "MBProgressHUD.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuickLook/QuickLook.h>

NSString *supportedMimeTypes[] =
{
    @"image/png",
    @"image/jpeg",
    @"image/gif",
    @"audio/mpeg"
};

@interface VIRemoteDocumentController ()

@property (strong) NSString *localFile;

@end

@implementation VIRemoteDocumentController

- (void)openWith:(NSURL*)url
   forController:(UIViewController*)cont
      completion:(void (^)(BOOL success, NSError *err))completion
{
    [self openWith:url forController:cont atPoint:CGPointMake(0,cont.view.center.y) completion:completion];
}

- (void)openWith:(NSURL*)url
   forController:(UIViewController*)cont
         atPoint:(CGPoint)point
      completion:(void (^)(BOOL success, NSError *err))completion
{
    self.displayPoint = point;
    self.completion = completion;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD HUDForView:cont.view];
        if (!hud) {
            hud = [[MBProgressHUD alloc]initWithView:cont.view];
            [cont.view addSubview:hud];
        }
        
        [hud setLabelText:@"Loading..."];
        [hud setMode:MBProgressHUDModeIndeterminate];
        [hud setAnimationType:MBProgressHUDAnimationZoom];
        
        [hud show:YES];
        
        [self proceedWithDownloadForURL:url forController:cont];
    });
}

- (void)proceedWithDownloadForURL:(NSURL*)url forController:(UIViewController*)cont
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        //This should eventually be updated to use a download mechanism with a callback.
        NSData *fileRemote = [[NSData alloc] initWithContentsOfURL:url];
    
        NSString *previewDocumentFileName = [[url.absoluteString componentsSeparatedByString:@"/"] lastObject];
        self.localFile = [[VIRemoteDocumentController applicationDocumentsDirectory] stringByAppendingPathComponent:previewDocumentFileName];
        
        NSError *err;
        [fileRemote writeToFile:self.localFile options:NSDataWritingAtomic error:&err];
        
        if (err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MBProgressHUD HUDForView:cont.view] hide:YES];
                self.completion(NO, err);
                self.completion = nil;
            });
        }else{
            [self displayDIForController:cont];
        }
    });
}

- (void)displayDIForController:(UIViewController*)cont
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *fileURL = [NSURL fileURLWithPath:self.localFile];
        
        self.controller = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        self.controller.delegate = self;
        self.controller.UTI = [VIRemoteDocumentController fileMIMEType:fileURL.absoluteString];

        BOOL success = [self.controller presentOptionsMenuFromRect:CGRectMake(self.displayPoint.x,
                                                                             self.displayPoint.y,
                                                                             1, 1)
                                                           inView:cont.view
                                                         animated:YES];
        
        [[MBProgressHUD HUDForView:cont.view] hide:YES];
        self.completion(success, nil);
        self.completion = nil;
    });
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if ([self.delegate respondsToSelector:@selector(documentInteractionControllerDidDismissOpenInMenu:)]) {
        [self.delegate documentInteractionControllerDidDismissOpenInMenu:controller];
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
            didEndSendingToApplication:(NSString *)application
{
    if ([self.delegate respondsToSelector:@selector(documentInteractionController:didEndSendingToApplication:)]) {
        [self.delegate documentInteractionController:controller
                          didEndSendingToApplication:application];
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    if ([self.delegate respondsToSelector:@selector(documentInteractionController:willBeginSendingToApplication:)]) {
        [self.delegate documentInteractionController:controller
                       willBeginSendingToApplication:application];
    }
}

- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    if ([self.delegate respondsToSelector:@selector(documentInteractionControllerWillBeginPreview:)]) {
        [self.delegate documentInteractionControllerWillBeginPreview:controller];
    }
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    if ([self.delegate respondsToSelector:@selector(documentInteractionControllerDidEndPreview:)]) {
        [self.delegate documentInteractionControllerDidEndPreview:controller];
    }
}

- (NSError*)cleanupTempFile:(UIDocumentInteractionController *)controller
{    
    //This doesn't need to be called, because iOS will clean out the Temp directory when it feels like it.
    //However, I'm leaving it here in case someone wants to be a good memory citizen.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:self.localFile];

    if (fileExists) {
        NSError *error = nil;
        [fileManager removeItemAtPath:self.localFile error:&error];
        
        return error;
    } else {
        NSLog(@"File already deleted");
        return nil;
    }
}

#pragma mark - Mime Type Stuff
+ (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSString*)fileMIMEType:(NSString*)filePath {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (__bridge CFStringRef)[filePath pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);

    if (UTI) {
        CFRelease(UTI);
    }

    return (__bridge NSString *)(MIMEType);
}

+ (BOOL)canHandleFileRequest:(NSURLRequest*)urlRequest;
{
    NSLog(@"Header fields %@", urlRequest.allHTTPHeaderFields);
    
    NSString *mimeType = [urlRequest valueForHTTPHeaderField:@"Content-Type"];
    
    if (mimeType == nil) {
        //Use low level mobile core services if Content-Type is not set.
        mimeType = [VIRemoteDocumentController fileMIMEType:urlRequest.URL.absoluteString];
    }

    int count = sizeof(supportedMimeTypes)/sizeof(supportedMimeTypes[0]);
    
    for(int i = 0; i < count; i++)
    {
        if ([supportedMimeTypes[i] isEqualToString:mimeType]) {
            return TRUE;
        }
    }
    
    return FALSE;
}

@end
