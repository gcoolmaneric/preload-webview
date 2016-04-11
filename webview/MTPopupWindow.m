//
//  MTPopupWindow.m
//  TabPopupTest
//
//  Created by Marin Todorov on 05/09/2012.
//

// MIT License
//
// Copyright (C) 2012 Marin Todorov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "MTPopupWindow.h"
#import "QuartzCore/QuartzCore.h"
#import "AdsManager.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UnityAds/UnityAds.h>


#define kCloseBtnDiameter 50
//#define kDefaultMargin 5
static CGSize kWindowMarginSize;

int kDefaultMargin = 5;

//
// Interface to declare the private class variables
//
@interface MTPopupWindow() <UIWebViewDelegate, UnityAdsDelegate>
{
    UIView* _dimView;
    UIView* _bgView;
    UIActivityIndicatorView* _loader;
    
    UIImageView* _yesBtn;
    UIImageView* _noBtn;
    UIImageView* _closeBtn;
    
}
@end


//
// Few helper methods to make maximizing windows
// setting ui elements sizes, and positioning
// easier
//
@interface UIView(MTPopupWindowLayoutShortcuts)
-(void)replaceConstraint:(NSLayoutConstraint*)c;
-(void)layoutCenterInView:(UIView*)v;
-(void)layoutInView:(UIView*)v setSize:(CGSize)s;
-(void)layoutMaximizeInView:(UIView*)v withInset:(float)inset;
-(void)layoutMaximizeInView:(UIView*)v withInsetSize:(CGSize)insetSize;
@end


// UnityAds SDK
static NSString *GAME_ID = @"72089";

@implementation MTPopupWindow

static MTPopupWindow* sharedInstance = nil;


+(MTPopupWindow *) sharedInstance
{
    @synchronized(self)     {
        if (!sharedInstance)
        {
            sharedInstance = [[MTPopupWindow alloc] init];
        }
    }
    return sharedInstance;
}

-(void)preloadHtml:(NSString*)fileName
{
    [self preloadData:fileName];
    
}


+ (void)initialize
{
    kWindowMarginSize = CGSizeMake(kDefaultMargin, kDefaultMargin);
}

-(void)setWindowMargin:(CGSize)margin
{
    kWindowMarginSize = margin;
}

-(MTPopupWindow*)showWindowWithHTMLFile:(NSString*)fileName
{
    UIView* view = [[UIApplication sharedApplication] keyWindow].rootViewController.view;
    if ([UIApplication sharedApplication].statusBarHidden==NO) {
        
        [self setWindowMargin:CGSizeMake(kWindowMarginSize.width, 50)];
        
    }
    return [self showWindowWithHTMLFile:fileName insideView:view];
}

-(MTPopupWindow*)showWindowUnityPromoView:(NSString*)viewname insideView:(UIView*)view
{
    kDefaultMargin = 90;
    kWindowMarginSize = CGSizeMake(kDefaultMargin, kDefaultMargin);
    
    //initialize the popup window
    if(_myAppliProPopUp == nil)
    {
        _myAppliProPopUp = [[MTPopupWindow alloc] initWithFile:viewname];
        [_myAppliProPopUp setTranslatesAutoresizingMaskIntoConstraints:NO];
        
    }
    
    //setup and show
    [_myAppliProPopUp showAppliPromoView: view];
    
    return _myAppliProPopUp;
}

/**
 * This is the only public method, it opens a popup window and loads the given content
 * @param NSString* fileName provide a file name to load a file from the app resources, or a URL to load a web page
 * @param UIView* view provide a UIViewController's view here (or other view)
 */
-(MTPopupWindow*)showWindowWithHTMLFile:(NSString*)fileName insideView:(UIView*)view
{
    kDefaultMargin = 70;
    kWindowMarginSize = CGSizeMake(kDefaultMargin, kDefaultMargin);
    
    //initialize the popup window
    if(_myPopUp == nil)
    {
        _myPopUp = [[MTPopupWindow alloc] initWithFile:fileName];
        [_myPopUp setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    //setup and show
    [_myPopUp showInView: view];
    
    return _myPopUp;
}

/**
 * Inject setupUI into the init initializer
 */
-(id)init
{
    self = [super init];
    if (self) {
        //customzation
        [self setupUI];
    }
    return self;
}

/**
 * Inject setupUI into the initWithFrame initializer
 */
-(id)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        //customzation
        [self setupUI];
    }
    return self;
}

/**
 * Initializes the class instance, gets a view where the window will pop up in
 * and a file name/ URL
 */
- (id)initWithFile:(NSString*)fName
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.fileName = fName;
    }
    
    return self;
}

/**
 * Shows the popup window in the root view controller
 */
-(void)show
{
    UIView* view = [[UIApplication sharedApplication] keyWindow].rootViewController.view;
    [self showInView:view];
}

/**
 * PreLoad Web Page
 */
-(void) preloadData :(NSString*)fileName
{
    if([fileName length] == 0 ) return;
    
    //initialize the popup window
    _myPopUp = [[MTPopupWindow alloc] initWithFile:fileName];
    [_myPopUp setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _myPopUp.fileName = [NSString stringWithFormat:@"%@", fileName];
    
    //add the web view to show the HTML file
    _myPopUp.webView = [[UIWebView alloc] init];
    _myPopUp.webView.scrollView.bounces = NO;
    _myPopUp.webView.backgroundColor = [UIColor clearColor];
    
    _myPopUp.webView.alpha = 0.0f;
    _myPopUp.webView.delegate = _myPopUp;
    [_myPopUp addSubview: _myPopUp.webView];
    
    
    //load the content for the popup window
    if ([_myPopUp.fileName hasPrefix:@"http"]) {
        _myPopUp.webView.scalesPageToFit = YES;
        [_myPopUp.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: _myPopUp.fileName]]];
    
    }
}
/**
 * Adds a hierarchy of views to the target view
 * then calls the method to animate the popup window in
 *
 *  v is the target view
 *  +- _dimView - a semi-opaque black background
 *  +- _bgView - the container of the popup window
 *    +- self - this is the popup window instance
 *      +- self.webView - is the web view to show your HTML content
 *      +- btnClose - the custom close button
 *    +- fauxView - an empty view, where the popup window animates into
 *
 * @param UIView* v The view to add the popup window to
 */
-(void)showInView:(UIView*)v
{
    //add the dim layer behind the popup
    _dimView = [[UIView alloc] init];
    
    CGRect newFrame = CGRectMake(0.0, 0.0, 907.0, 565.0);
    _dimView.frame = newFrame;
    
    [v addSubview: _dimView];
    [_dimView layoutMaximizeInView:v withInset:0];
    
    //add the popup container
    _bgView = [[UIView alloc] init];
     //_bgView.frame = newFrame;
    
    [v addSubview: _bgView];
    [_bgView layoutMaximizeInView:v withInset:0];
    
 
    //add the web view to show the HTML file
    if (self.webView == nil) {
        self.webView = [[UIWebView alloc] init];
    }
    self.webView.scrollView.bounces = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    
    
    self.webView.alpha = 0.0f;
    self.webView.delegate = self;
    [self addSubview: self.webView];

    [self.webView layoutMaximizeInView:self withInset:1];

    //load the content for the popup window
    if ([self.fileName hasPrefix:@"http"]) {
    
        
        self.webView.scalesPageToFit = YES;
        
    } else {
        
        //load a local file
        NSError* error = nil;
        NSString* fileContents = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.fileName] encoding:NSUTF8StringEncoding error: &error];
        if (error!=NULL) {
            NSLog(@"error loading %@: %@", self.fileName, [error localizedDescription]);
        } else {
            [self.webView loadHTMLString: fileContents baseURL:[[NSBundle mainBundle] resourceURL]];
        }
    }

    
    // Close Button
    _closeBtn =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"close.png"]];
    _closeBtn.userInteractionEnabled = YES;
    [_closeBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerCloseTap:)]];
    [self addSubview:_closeBtn];
    _closeBtn.center = CGPointMake(self.bounds.size.width, 30);
    
    
    //animate the popup window in
    [self performSelector:@selector(animatePopup:) withObject:v afterDelay:0.01];
}

-(void) updateButtonPosition {
    
    _yesBtn.alpha = 0;
    _noBtn.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height*2/3+150);
}

-(void)showAppliPromoView:(UIView*)v
{

    //add the popup container
    _bgView = [[UIView alloc] init];
    
    CGRect newFrame = CGRectMake(0.0, 0.0, 907.0, 565.0);
    _bgView.frame = newFrame;
    self.frame = CGRectMake(0.0, 0.0, 880.0, 545.0);
    [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
    
    
    // Setup UI
    // Yes Button
    _yesBtn =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yes.png"]];
    _yesBtn.userInteractionEnabled = YES;
    [_yesBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerTap:)]];
    [self addSubview:_yesBtn];
    _yesBtn.center = CGPointMake(self.bounds.size.width/2-150, self.bounds.size.height*2/3+190);
    
    
    // No Button
    _noBtn =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no.png"]];
    _noBtn.userInteractionEnabled = YES;
    [_noBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerNoTap:)]];
    [self addSubview:_noBtn];
    _noBtn.center = CGPointMake(self.bounds.size.width/2+200, self.bounds.size.height*2/3+190);
    
    
    // Close Button
    _closeBtn =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"close.png"]];
    _closeBtn.userInteractionEnabled = YES;
    [_closeBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerCloseTap:)]];
    [self addSubview:_closeBtn];
    _closeBtn.center = CGPointMake(self.bounds.size.width+45, 10);
    
    [v addSubview: _bgView];
    [_bgView layoutMaximizeInView:v withInset:0];
    
    
    //animate the popup window in
    [self performSelector:@selector(animatePopup:) withObject:v afterDelay:0.01];
    
    
    [[UnityAds sharedInstance] setDelegate:self];
    

}




- (void)triggerTap:(UIGestureRecognizer *)sender {
    
    NSLog(@"### Push triggerTap Button ###");
    
    
    
    if ([[UnityAds sharedInstance] canShow])
    {

        NSLog(@"show: %i", [[UnityAds sharedInstance] show:@{
                                                         kUnityAdsOptionNoOfferscreenKey:@true,
                                                         kUnityAdsOptionOpenAnimatedKey:@true,
                                                         kUnityAdsOptionGamerSIDKey:@"gom",
                                                         kUnityAdsOptionMuteVideoSounds:@false,
                                                         kUnityAdsOptionVideoUsesDeviceOrientation:@true
                                                         }]);
        
        
    }

}



- (void)triggerCloseTap:(UIGestureRecognizer *)sender {
    
    NSLog(@"### Push NO Button ###");
    
    [self closePopupWindow];
    
}


- (void)triggerNoTap:(UIGestureRecognizer *)sender {
    
    NSLog(@"### Push NO Button ###");
    
    [self closePopupWindow];

    // Show Cross Promotion UI
    [[AdsManager sharedInstance] showCrosspPromo];
    
}

- (void)didReceiveMemoryWarning {
   
    // Dispose of any resources that can be recreated.
}


/**
 * Adds a blank view and then animates the popup window
 * into the parent view
 *
 * @param UIView* v the parent view to do the animations in
 */
-(void)animatePopup:(UIView*)v
{

    //add the faux view to transition from
    UIView* fauxView = [[UIView alloc] init];
    fauxView.backgroundColor = [UIColor redColor];
    [_bgView addSubview: fauxView];

    [fauxView layoutMaximizeInView:_bgView withInset: kDefaultMargin];

    //animation options
    UIViewAnimationOptions options =
        UIViewAnimationOptionTransitionFlipFromRight |
        UIViewAnimationOptionAllowUserInteraction    |
        UIViewAnimationOptionBeginFromCurrentState;
    
    //run the animations
    [UIView transitionWithView:_bgView
                      duration:.4
                       options:options
                    animations:^{
                        
                        //replace the blank view with the popup window
                        [fauxView removeFromSuperview];
                        [_bgView addSubview: self];
                        
                        //maximize the popup window in the parent view
                        [self layoutMaximizeInView:_bgView withInsetSize: kWindowMarginSize];
                        
                        //turn the background view to black color
                        _dimView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
                        
                        //fade in the web view
                        self.webView.alpha = 1.0f;
                        
                    } completion:^(BOOL finished) {
                        //NSLog(@"Finsihed");
                    }];
}

/**
 * Closes the popup window
 * the method animates the popup window out
 * and removes it from the view hierarchy
 */
-(void)closePopupWindow
{
 
    //animation options
    UIViewAnimationOptions options =
        UIViewAnimationOptionTransitionFlipFromLeft |
        UIViewAnimationOptionAllowUserInteraction   |
        UIViewAnimationOptionBeginFromCurrentState;
    
    //animate the popup window out
    [UIView transitionWithView:_bgView
                      duration:.4
                       options:options
                    animations:^{
                        
                        //fade out the black background
                        _dimView.backgroundColor = [UIColor clearColor];
                        
                        //remove the popup window from the view hierarchy
                        [self removeFromSuperview];
                        
                    } completion:^(BOOL finished) {
                        
                        //remove the container view
                        [_bgView removeFromSuperview];
                        _bgView = nil;
                        
                        //remove the black backgorund
                        [_dimView removeFromSuperview];
                        _dimView = nil;
                    }];
    
    
    [_yesBtn removeFromSuperview];
    [_noBtn removeFromSuperview];
    [_closeBtn removeFromSuperview];
    
    
    // The ad has closed
    [[AdsManager sharedInstance]  adClosed];
    
}


/**
 * Sets up some basic UI properties
 */
-(void)setupUI
{
    self.layer.frame = CGRectMake(0.0, 0.0, 907.0, 565.0);
    self.layer.borderWidth = 0.0;
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.layer.cornerRadius = 15.0;
    self.backgroundColor = [UIColor blackColor];
    //self.backgroundColor  = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
    
}

#pragma mark - Unity Ads delegate methods

- (void)unityAdsFetchCompleted {
    NSLog(@"unityAdsFetchCompleted");
    
}

-(void) unityAdsFetchFailed {
    
    [self closePopupWindow];
}

- (void)unityAdsWillShow {
    NSLog(@"unityAdsWillShow");
}

- (void)unityAdsDidShow {
    NSLog(@"unityAdsDidShow");
}

- (void)unityAdsWillHide {
    NSLog(@"unityAdsWillHide");
}

- (void)unityAdsDidHide {
    NSLog(@"unityAdsDidHide");
}

- (void)unityAdsVideoStarted {
    NSLog(@"unityAdsVideoStarted");
}


- (void)unityAdsVideoCompleted:(NSString *)rewardItemKey skipped:(BOOL)skipped {
   // NSLog(@"unityAdsVideoCompleted:rewardItemKey:skipped -- key: %@ -- skipped: %@", rewardItemKey, skipped ? @"true" : @"false");
    
    
    NSLog(@"Close AppliPromo Ads");
    [self updateButtonPosition];
    
    [[AdsManager sharedInstance] setLoading:YES];
    
    [[UnityAds sharedInstance] hide];
    
    // Give reward
    [[AdsManager sharedInstance]  adOk:@"15"];
    
}


#pragma mark - webview delegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    
    NSLog(@"#### shouldStartLoadWithRequest url %@", url);
   
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"####  Load webViewDidFinishLoad Suu Corss Banner OK ");
    
    if (_loader) [_loader removeFromSuperview];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:@"The requested document cannot be loaded, try again later"
                               delegate:nil
                      cancelButtonTitle:@"Close"
                      otherButtonTitles: nil] show];
    
    if (_loader) [_loader removeFromSuperview];
}

@end


//
// Few handy helper methods as a category to UIView
// to help building contraints
//
@implementation UIView(MTPopupWindowLayoutShortcuts)

-(void)replaceConstraint:(NSLayoutConstraint*)c
{
    for (int i=0;i<[self.constraints count];i++) {
        NSLayoutConstraint* c1 = self.constraints[i];
        if (c1.firstItem==c.firstItem && c1.firstAttribute == c.firstAttribute) {
            [self removeConstraint:c1];
        }
    }
    [self addConstraint:c];
}

-(void)layoutCenterInView:(UIView*)v
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint* centerX = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterX
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterX
                                                              multiplier: 1.0f
                                                                constant: 0.0f];
    
    NSLayoutConstraint* centerY = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterY
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterY
                                                              multiplier: 1.0f
                                                                constant: 0.0f];
    
    [v replaceConstraint:centerX];
    [v replaceConstraint:centerY];
    
    [v setNeedsLayout];
}

-(void)layoutInView:(UIView*)v setSize:(CGSize)s
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint* wwidth = [NSLayoutConstraint constraintWithItem: self
                                                              attribute: NSLayoutAttributeWidth
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: v
                                                              attribute: NSLayoutAttributeWidth
                                                             multiplier: 0.0f
                                                               constant: s.width];
    
    NSLayoutConstraint* hheight = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeHeight
                                                              multiplier: 0.0f
                                                                constant: s.height];
    [v replaceConstraint: wwidth];
    [v replaceConstraint: hheight];
    
    [v setNeedsLayout];
}

-(void)layoutMaximizeInView:(UIView*)v withInset:(float)inset
{
    [self layoutMaximizeInView:v withInsetSize:CGSizeMake(inset, inset)];
}

-(void)layoutMaximizeInView:(UIView*)v withInsetSize:(CGSize)insetSize
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint* centerX = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterX
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterX
                                                              multiplier: 1.0f
                                                                constant: 0.0f];
    
    NSLayoutConstraint* centerY = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterY
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterY
                                                              multiplier: 1.0f
                                                                constant: 0.0f];
    
    NSLayoutConstraint* wwidth = [NSLayoutConstraint constraintWithItem: self
                                                              attribute: NSLayoutAttributeWidth
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: v
                                                              attribute: NSLayoutAttributeWidth
                                                             multiplier: 1.0f
                                                               constant: -insetSize.width];
    
    NSLayoutConstraint* hheight = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeHeight
                                                              multiplier: 1.0f
                                                                constant: -insetSize.height-27];
    
    
    [v replaceConstraint: centerX];
    [v replaceConstraint: centerY];
    [v replaceConstraint: wwidth];
    [v replaceConstraint: hheight];
    
    [v setNeedsLayout];
}

@end
