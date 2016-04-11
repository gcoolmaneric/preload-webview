# Preload-webview

- Preload a html page in cahce to smoothly display the page without any time lag. 
- Include UnityAds SDK to display video ads

# How to use ? 

- Include .h files at the source file of .m.

  `#import "MTPopupWindow.h"`

  `#import "ASIHTTPRequest.h"`

  `#import "ASIFormDataRequest.h"`
  

- Preload a html page. 

 `NSString* serverUrl = [NSString stringWithFormat:@"%@?userId=%@", crossPageIP, [self genUUID]];`
  
  `[[MTPopupWindow sharedInstance] preloadHtml:serverUrl];`]
  
- Display the html page.
 
  `NSString* serverUrl = [NSString stringWithFormat:@"%@?userId=%@", crossPageIP, [self genUUID]];`

  `[[MTPopupWindow  sharedInstance] showWindowWithHTMLFile:serverUrl insideView:your view];`
