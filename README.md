VIRemoteDocumentController
===

This is a class for opening remote file URL's in UIDocumentInteractionController with Open In options aligning with the Mime Type of the file at the url passed in.

How To Use
----------

- Add MobileCoreServices framework into your project.
- Copy MBProgressHUD and VIRemoteDocumentController classes into your project
- Update supportedMimeTypes[] if you plan on using shouldHandleFileRequest: to determine whether or not you want to handle a file based on it's file type.

- For iPhone only apps call it using:

     - (void)openWith:(NSURL*)url
       forController:(UIViewController*)cont
          completion:(void (^)(BOOL success, NSError *err))completion;

- For iPad or Universal, you can use this method to pick an origin for the iPad popover:

     - (void)openWith:(NSURL*)url
       forController:(UIViewController*)cont
             atPoint:(CGPoint)point
          completion:(void (^)(BOOL success, NSError *err))completion;


Example:

    [[VIRemoteDocumentController getInstance] openWith:request.URL
                                     	 forController:self.someViewController
                                               atPoint:self.someDisplayPoint 
                                     	    completion:^(BOOL success, NSError *err) {
                                        	    NSLog(@"Successfully displayed.");
                                        	}];


Protips
--------

- If the UIViewController used responds to UIDocumentInteractionControllerDelegate Protocol, VIRemoteDocumentController will call those methods on your UIViewController.

- VIRemoteDocumentController will default to displaying the "Open In <App Name>" menu, but if a user does not have any apps who are registered to open a file type, it will instead open the "Options" menu.


Current Limitations
----------

- Is currently based on MBProgressHUD for loading.

- Loading is Indeterminate, instead of progress based.

