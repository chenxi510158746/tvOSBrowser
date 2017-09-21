//
//  ViewController.m
//  Browser
//
//  Created by Steven Troughton-Smith on 20/09/2015.
//  Improved by Jip van Akker on 14/10/2015
//  Traduit en francais par Vincent Deniau le 08/08/2017
//  Copyright © 2015 High Caffeine Content. All rights reserved.
//

#import "ViewController.h"
#import <GameController/GameController.h>

typedef struct _Input
{
    CGFloat x;
    CGFloat y;
} Input;


@interface ViewController ()
{
    UIImageView *cursorView;
    UIActivityIndicatorView *loadingSpinner;
    Input input;
    NSString *requestURL;
    NSString *previousURL;
}

@property UIWebView *webview;
@property (strong) CADisplayLink *link;
@property (strong, nonatomic) GCController *controller;
@property BOOL cursorMode;
@property BOOL displayedHintsOnLaunch;
@property BOOL scrollViewAllowBounces;
@property CGPoint lastTouchLocation;
@property NSUInteger textFontSize;

@end

@implementation ViewController {
    UITapGestureRecognizer *touchSurfaceDoubleTapRecognizer;
    UITapGestureRecognizer *playPauseOrMenuDoubleTapRecognizer;
}
-(void) webViewDidStartLoad:(UIWebView *)webView {
    //[self.view bringSubviewToFront:loadingSpinner];
    if (![previousURL isEqualToString:requestURL]) {
        [loadingSpinner startAnimating];
    }
    previousURL = requestURL;
}
-(void) webViewDidFinishLoad:(UIWebView *)webView {
    [loadingSpinner stopAnimating];
    //[self.view bringSubviewToFront:loadingSpinner];
    NSString *theTitle=[webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSString *currentURL = webView.request.URL.absoluteString;
    NSArray *toSaveItem = [NSArray arrayWithObjects:currentURL, theTitle, nil];
    NSMutableArray *historyArray = [NSMutableArray arrayWithObjects:toSaveItem, nil];
    if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"HISTORY"] != nil) {
        NSMutableArray *savedArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"HISTORY"] mutableCopy];
        if ([savedArray count] > 0) {
            if ([savedArray[0][0] isEqualToString: currentURL]) {
                [historyArray removeObjectAtIndex:0];
            }
        }
        [historyArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"HISTORY"]];
    }
    while ([historyArray count] > 100) {
        [historyArray removeLastObject];
    }
    NSArray *toStoreArray = historyArray;
    [[NSUserDefaults standardUserDefaults] setObject:toStoreArray forKey:@"HISTORY"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)viewDidAppear:(BOOL)animated {
    loadingSpinner.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"savedURLtoReopen"] != nil) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"savedURLtoReopen"]]]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedURLtoReopen"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if (_webview.request == nil) {
        //[self requestURLorSearchInput];
        [self loadHomePage];
    }
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DontShowHintsOnLaunch"] && !_displayedHintsOnLaunch) {
        [self showHintsAlert];
    }
    _displayedHintsOnLaunch = YES;
}
-(void)loadHomePage {
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"homepage"] != nil) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"homepage"]]]];
    }
    else {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: @"https://www.baidu.com"]]];
    }
}
-(void)viewDidLoad {
    _scrollViewAllowBounces = NO;
    [super viewDidLoad];
    touchSurfaceDoubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTouchSurfaceDoubleTap:)];
    touchSurfaceDoubleTapRecognizer.numberOfTapsRequired = 2;
    touchSurfaceDoubleTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [self.view addGestureRecognizer:touchSurfaceDoubleTapRecognizer];
    
    playPauseOrMenuDoubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleDoubleTapMenuOrPlayPause:)];
    playPauseOrMenuDoubleTapRecognizer.numberOfTapsRequired = 2;
    playPauseOrMenuDoubleTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause], [NSNumber numberWithInteger:UIPressTypeMenu]];
    [self.view addGestureRecognizer:playPauseOrMenuDoubleTapRecognizer];
    
    cursorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    cursorView.image = [UIImage imageNamed:@"Cursor"];
    cursorView.backgroundColor = [UIColor clearColor];
    cursorView.hidden = YES;
    
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [self.view addGestureRecognizer:longPress];
    
    self.webview = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    //[self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    
    [self.view addSubview:self.webview];
    [self.view addSubview:cursorView];
    
    self.webview.delegate = self;
    self.webview.scrollView.bounces = _scrollViewAllowBounces;
    self.webview.scrollView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
    loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    loadingSpinner.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    loadingSpinner.tintColor = [UIColor blackColor];
    loadingSpinner.hidesWhenStopped = true;
    //[loadingSpinner startAnimating];
    [self.view addSubview:loadingSpinner];
    [self.view bringSubviewToFront:loadingSpinner];
    //ENABLE CURSOR MODE INITIALLY
    self.cursorMode = YES;
    self.webview.scrollView.scrollEnabled = NO;
    self.webview.userInteractionEnabled = NO;
    self.webview.scalesPageToFit = NO;
    cursorView.hidden = NO;
    self.textFontSize = 100;
}
-(void)handleDoubleTapMenuOrPlayPause:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"菜单"
                                              message:@""
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *loadHomePageAction = [UIAlertAction
                                             actionWithTitle:@"转到主页"
                                             style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action)
                                             {
                                                 [self loadHomePage];
                                             }];
        UIAlertAction *setHomePageAction = [UIAlertAction
                                            actionWithTitle:@"设为首页"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                                            {
                                                if (_webview.request != nil) {
                                                    if (![_webview.request.URL.absoluteString isEqual:@""]) {
                                                        [[NSUserDefaults standardUserDefaults] setObject:_webview.request.URL.absoluteString forKey:@"homepage"];
                                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                                    }
                                                }
                                            }];
        UIAlertAction *showHintsAction = [UIAlertAction
                                          actionWithTitle:@"帮助"
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action)
                                          {
                                              [self showHintsAlert];
                                          }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"取消"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                       }];
        UIAlertAction *viewFavoritesAction = [UIAlertAction
                                              actionWithTitle:@"收藏夹"
                                              style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action)
                                              {
                                                  NSArray *indexableArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITES"];
                                                  UIAlertController *historyAlertController = [UIAlertController
                                                                                               alertControllerWithTitle:@"收藏夹"
                                                                                               message:@""
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction *editFavoritesAction = [UIAlertAction
                                                                                        actionWithTitle:@"删除收藏夹"
                                                                                        style:UIAlertActionStyleDestructive
                                                                                        handler:^(UIAlertAction *action)
                                                                                        {
                                                                                            NSArray *editingIndexableArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITES"];
                                                                                            UIAlertController *editHistoryAlertController = [UIAlertController
                                                                                                                                             alertControllerWithTitle:@"删除收藏夹"
                                                                                                                                             message:@"选择要删除的收藏夹"
                                                                                                                                             preferredStyle:UIAlertControllerStyleAlert];
                                                                                            if (editingIndexableArray != nil) {
                                                                                                for (int i = 0; i < [editingIndexableArray count]; i++) {
                                                                                                    NSString *objectTitle = editingIndexableArray[i][1];
                                                                                                    NSString *objectSubtitle = editingIndexableArray[i][0];
                                                                                                    if (![[objectSubtitle stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                                                                                                        if ([[objectTitle stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                                                                                                            objectTitle = objectSubtitle;
                                                                                                        }
                                                                                                        UIAlertAction *favoriteItem = [UIAlertAction
                                                                                                                                       actionWithTitle:objectTitle
                                                                                                                                       style:UIAlertActionStyleDefault
                                                                                                                                       handler:^(UIAlertAction *action)
                                                                                                                                       {
                                                                                                                                           NSMutableArray *editingArray = [editingIndexableArray mutableCopy];
                                                                                                                                           [editingArray removeObjectAtIndex:i];
                                                                                                                                           NSArray *toStoreArray = editingArray;
                                                                                                                                           [[NSUserDefaults standardUserDefaults] setObject:toStoreArray forKey:@"FAVORITES"];
                                                                                                                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                                                                       }];
                                                                                                        [editHistoryAlertController addAction:favoriteItem];
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                            [editHistoryAlertController addAction:cancelAction];
                                                                                            [self presentViewController:editHistoryAlertController animated:YES completion:nil];
                                                                                            
                                                                                        }];
                                                  UIAlertAction *addToFavoritesAction = [UIAlertAction
                                                                                         actionWithTitle:@"加入收藏夹"
                                                                                         style:UIAlertActionStyleDefault
                                                                                         handler:^(UIAlertAction *action)
                                                                                         {
                                                                                             NSString *theTitle=[_webview stringByEvaluatingJavaScriptFromString:@"document.title"];
                                                                                             NSString *currentURL = _webview.request.URL.absoluteString;
                                                                                             UIAlertController *favoritesAddToController = [UIAlertController
                                                                                                                                            alertControllerWithTitle:@"命名新的收藏夹"
                                                                                                                                            message:currentURL
                                                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                                                             
                                                                                             [favoritesAddToController addTextFieldWithConfigurationHandler:^(UITextField *textField)
                                                                                              {
                                                                                                  textField.keyboardType = UIKeyboardTypeDefault;
                                                                                                  textField.placeholder = @"命名新的收藏夹";
                                                                                                  textField.text = theTitle;
                                                                                                  textField.textColor = [UIColor blackColor];
                                                                                                  textField.backgroundColor = [UIColor whiteColor];
                                                                                                  [textField setReturnKeyType:UIReturnKeyDone];
                                                                                                  [textField addTarget:self
                                                                                                                action:@selector(alertTextFieldShouldReturn:)
                                                                                                      forControlEvents:UIControlEventEditingDidEnd];
                                                                                                  
                                                                                              }];
                                                                                             
                                                                                             UIAlertAction *saveAction = [UIAlertAction
                                                                                                                          actionWithTitle:@"记录"
                                                                                                                          style:UIAlertActionStyleDestructive
                                                                                                                          handler:^(UIAlertAction *action)
                                                                                                                          {
                                                                                                                              UITextField *urltextfield = favoritesAddToController.textFields[0];
                                                                                                                              NSString *toMod = urltextfield.text;
                                                                                                                              if ([toMod isEqualToString:@""]) {
                                                                                                                                  toMod = currentURL;
                                                                                                                              }
                                                                                                                              NSArray *toSaveItem = [NSArray arrayWithObjects:currentURL, theTitle, nil];
                                                                                                                              NSMutableArray *historyArray = [NSMutableArray arrayWithObjects:toSaveItem, nil];
                                                                                                                              if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITES"] != nil) {
                                                                                                                                  historyArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITES"] mutableCopy];
                                                                                                                                  [historyArray addObject:toSaveItem];
                                                                                                                              }
                                                                                                                              NSArray *toStoreArray = historyArray;
                                                                                                                              [[NSUserDefaults standardUserDefaults] setObject:toStoreArray forKey:@"FAVORITES"];
                                                                                                                              [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                                                              
                                                                                                                          }];
                                                                                             [favoritesAddToController addAction:saveAction];
                                                                                             [favoritesAddToController addAction:cancelAction];
                                                                                             [self presentViewController:favoritesAddToController animated:YES completion:nil];
                                                                                             //UITextField *textFieldAlert = favoritesAddToController.textFields[0];
                                                                                             //[textFieldAlert becomeFirstResponder];
                                                                                             
                                                                                         }];
                                                  if (indexableArray != nil) {
                                                      for (int i = 0; i < [indexableArray count]; i++) {
                                                          NSString *objectTitle = indexableArray[i][1];
                                                          NSString *objectSubtitle = indexableArray[i][0];
                                                          if (![[objectSubtitle stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                                                              if ([[objectTitle stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                                                                  objectTitle = objectSubtitle;
                                                              }
                                                              UIAlertAction *favoriteItem = [UIAlertAction
                                                                                             actionWithTitle:objectTitle
                                                                                             style:UIAlertActionStyleDefault
                                                                                             handler:^(UIAlertAction *action)
                                                                                             {
                                                                                                 [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: indexableArray[i][0]]]];
                                                                                             }];
                                                              [historyAlertController addAction:favoriteItem];
                                                          }
                                                      }
                                                  }
                                                  if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITES"] != nil) {
                                                      if ([[[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITES"] count] > 0) {
                                                          [historyAlertController addAction:editFavoritesAction];
                                                      }
                                                  }
                                                  [historyAlertController addAction:addToFavoritesAction];
                                                  [historyAlertController addAction:cancelAction];
                                                  [self presentViewController:historyAlertController animated:YES completion:nil];
                                              }];
        UIAlertAction *viewHistoryAction = [UIAlertAction
                                            actionWithTitle:@"历史记录"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                                            {
                                                NSArray *indexableArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"HISTORY"];
                                                UIAlertController *historyAlertController = [UIAlertController
                                                                                             alertControllerWithTitle:@"历史记录"
                                                                                             message:@""
                                                                                             preferredStyle:UIAlertControllerStyleAlert];
                                                UIAlertAction *clearHistoryAction = [UIAlertAction
                                                                                     actionWithTitle:@"清空历史记录"
                                                                                     style:UIAlertActionStyleDestructive
                                                                                     handler:^(UIAlertAction *action)
                                                                                     {
                                                                                         [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HISTORY"];
                                                                                         [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                         
                                                                                     }];
                                                if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"HISTORY"] != nil) {
                                                    [historyAlertController addAction:clearHistoryAction];
                                                }
                                                for (int i = 0; i < [indexableArray count]; i++) {
                                                    NSString *objectTitle = indexableArray[i][1];
                                                    NSString *objectSubtitle = indexableArray[i][0];
                                                    if (![[objectSubtitle stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                                                        if ([[objectTitle stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                                                            objectTitle = objectSubtitle;
                                                        }
                                                        else {
                                                            objectTitle = [NSString stringWithFormat:@"%@ - %@",objectTitle,objectSubtitle ];
                                                        }
                                                        UIAlertAction *historyItem = [UIAlertAction
                                                                                      actionWithTitle:objectTitle
                                                                                      style:UIAlertActionStyleDefault
                                                                                      handler:^(UIAlertAction *action)
                                                                                      {
                                                                                          [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: indexableArray[i][0]]]];
                                                                                      }];
                                                        [historyAlertController addAction:historyItem];
                                                    }
                                                }
                                                [historyAlertController addAction:cancelAction];
                                                [self presentViewController:historyAlertController animated:YES completion:nil];
                                            }];
        UIAlertAction *mobileModeAction = [UIAlertAction
                                           actionWithTitle:@"切换到移动模式"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
                                               NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0 Mobile/12B410 Safari/601.2.7", @"UserAgent", nil];
                                               [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
                                               [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MobileMode"];
                                               [[NSUserDefaults standardUserDefaults] synchronize];
                                               if (_webview.request != nil) {
                                                   if (![_webview.request.URL.absoluteString isEqual:@""]) {
                                                       [[NSUserDefaults standardUserDefaults] setObject:_webview.request.URL.absoluteString forKey:@"savedURLtoReopen"];
                                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                                   }
                                               }
                                               exit(0);
                                               
                                           }];
        UIAlertAction *desktopModeAction = [UIAlertAction
                                            actionWithTitle:@"切换到桌面模式"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                                            {
                                                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.7", @"UserAgent", nil];
                                                [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
                                                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MobileMode"];
                                                [[NSUserDefaults standardUserDefaults] synchronize];
                                                if (_webview.request != nil) {
                                                    if (![_webview.request.URL.absoluteString isEqual:@""]) {
                                                        [[NSUserDefaults standardUserDefaults] setObject:_webview.request.URL.absoluteString forKey:@"savedURLtoReopen"];
                                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                                    }
                                                }
                                                exit(0);
                                            }];
        UIAlertAction *clearCacheAction = [UIAlertAction
                                           actionWithTitle:@"清除缓存"
                                           style:UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction *action)
                                           {
                                               [[NSURLCache sharedURLCache] removeAllCachedResponses];
                                               [[NSUserDefaults standardUserDefaults] synchronize];
                                               previousURL = @"";
                                               [self.webview reload];
                                               
                                           }];
        UIAlertAction *clearCookiesAction = [UIAlertAction
                                             actionWithTitle:@"删除Cookie"
                                             style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *action)
                                             {
                                                 NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                                                 for (NSHTTPCookie *cookie in [storage cookies]) {
                                                     [storage deleteCookie:cookie];
                                                 }
                                                 [[NSUserDefaults standardUserDefaults] synchronize];
                                                 previousURL = @"";
                                                 [self.webview reload];
                                                 
                                             }];
        
        UIAlertAction *increaseFontSizeAction = [UIAlertAction
                                             actionWithTitle:@"增加字体大小"
                                             style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action)
                                             {
                                                 self.textFontSize = (self.textFontSize < 160) ? self.textFontSize +5 : self.textFontSize;
                                                 
                                                 NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                                                                       (unsigned long)self.textFontSize];
                                                 [self.webview stringByEvaluatingJavaScriptFromString:jsString];
                                             }];
        
        UIAlertAction *decreaseFontSizeAction = [UIAlertAction
                                                 actionWithTitle:@"减小字体大小"
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action)
                                                 {
                                                     self.textFontSize = (self.textFontSize > 50) ? self.textFontSize -5 : self.textFontSize;
                                                     
                                                     NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                                                                           (unsigned long)self.textFontSize];
                                                     [self.webview stringByEvaluatingJavaScriptFromString:jsString];
                                                 }];
        
        UIAlertAction *scalePageToFitAction = [UIAlertAction
                                                 actionWithTitle:@"将页面调整到屏幕大小"
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action)
                                                 {
                                                     if (self.webview.scalesPageToFit) {
                                                         self.webview.scalesPageToFit = NO;
                                                     } else {
                                                         self.webview.scalesPageToFit = YES;
                                                         self.webview.contentMode = UIViewContentModeScaleAspectFit;
                                                     }
                                                     [self.webview reload];
                                                 }];
        /*
         UIAlertAction *reloadAction = [UIAlertAction
         actionWithTitle:@"重新加载页面"
         style:UIAlertActionStyleDefault
         handler:^(UIAlertAction *action)
         {
         _inputViewVisible = NO;
         previousURL = @"";
         [self.webview reload];
         }];
         if (_webview.request != nil) {
         if (![_webview.request.URL.absoluteString  isEqual: @""]) {
         [alertController addAction:reloadAction];
         }
         }
         */
        [alertController addAction:viewFavoritesAction];
        [alertController addAction:viewHistoryAction];
        [alertController addAction:loadHomePageAction];
        [alertController addAction:setHomePageAction];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MobileMode"]) {
            [alertController addAction:desktopModeAction];
        }
        else {
            [alertController addAction:mobileModeAction];
        }
        [alertController addAction:clearCacheAction];
        [alertController addAction:clearCookiesAction];
        [alertController addAction:increaseFontSizeAction];
        [alertController addAction:decreaseFontSizeAction];
        [alertController addAction:scalePageToFitAction];
        [alertController addAction:showHintsAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}
-(void)handleTouchSurfaceDoubleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self toggleMode];
    }
}
-(void)requestURLorSearchInput
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"输入网址或搜索字词"
                                          message:@""
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.keyboardType = UIKeyboardTypeURL;
         textField.placeholder = @"输入网址或搜索字词";
         textField.textColor = [UIColor blackColor];
         textField.backgroundColor = [UIColor whiteColor];
         [textField setReturnKeyType:UIReturnKeyDone];
         [textField addTarget:self
                       action:@selector(alertTextFieldShouldReturn:)
             forControlEvents:UIControlEventEditingDidEnd];
         
     }];
    
    UIAlertAction *goAction = [UIAlertAction
                               actionWithTitle:@"打开网址"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   UITextField *urltextfield = alertController.textFields[0];
                                   NSString *toMod = urltextfield.text;
                                   /*
                                    if ([toMod containsString:@" "] || ![temporaryURL containsString:@"."]) {
                                    toMod = [toMod stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                                    toMod = [toMod stringByReplacingOccurrencesOfString:@"." withString:@"+"];
                                    toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                    toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                    toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                    toMod = [toMod stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                    if (toMod != nil) {
                                    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.baidu.com/s?wd=%@", toMod]]]];
                                    }
                                    else {
                                    [self requestURLorSearchInput];
                                    }
                                    }
                                    else {
                                    */
                                   if (![toMod isEqualToString:@""]) {
                                       if ([toMod containsString:@"http://"] || [toMod containsString:@"https://"]) {
                                           [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", toMod]]]];
                                       }
                                       else {
                                           [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", toMod]]]];
                                       }
                                   }
                                   else {
                                       [self requestURLorSearchInput];
                                   }
                                   //}
                                   
                               }];
    UIAlertAction *searchAction = [UIAlertAction
                                   actionWithTitle:@"在百度上搜索"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       UITextField *urltextfield = alertController.textFields[0];
                                       NSString *toMod = urltextfield.text;
                                       toMod = [toMod stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                                       toMod = [toMod stringByReplacingOccurrencesOfString:@"." withString:@"+"];
                                       toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       toMod = [toMod stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                       if (toMod != nil) {
                                           [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.baidu.com/s?wd=%@", toMod]]]];
                                       }
                                       else {
                                           [self requestURLorSearchInput];
                                       }
                                   }];
    
    UIAlertAction *reloadAction = [UIAlertAction
                                   actionWithTitle:@"重新加载页面"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       previousURL = @"";
                                       [self.webview reload];
                                   }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"取消"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    [alertController addAction:goAction];
    [alertController addAction:searchAction];
    if (_webview.request != nil) {
        if (![_webview.request.URL.absoluteString  isEqual: @""]) {
            [alertController addAction:reloadAction];
            [alertController addAction:cancelAction];
        }
    }
    [self presentViewController:alertController animated:YES completion:nil];
    if (_webview.request == nil) {
        UITextField *loginTextField = alertController.textFields[0];
        [loginTextField becomeFirstResponder];
    }
    else if ([_webview.request.URL.absoluteString  isEqual: @""]) {
        UITextField *loginTextField = alertController.textFields[0];
        [loginTextField becomeFirstResponder];
    }
    
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    requestURL = request.URL.absoluteString;
    return YES;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [loadingSpinner stopAnimating];
    if (![[NSString stringWithFormat:@"%lid", (long)error.code] containsString:@"999"] && ![[NSString stringWithFormat:@"%lid", (long)error.code] containsString:@"204"]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"无法加载页面"
                                              message:[error localizedDescription]
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *searchAction = [UIAlertAction
                                       actionWithTitle:@"在百度上搜索此页面"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           if (requestURL != nil) {
                                               if ([requestURL length] > 1) {
                                                   NSString *lastChar = [requestURL substringFromIndex: [requestURL length] - 1];
                                                   if ([lastChar isEqualToString:@"/"]) {
                                                       NSString *newString = [requestURL substringToIndex:[requestURL length]-1];
                                                       requestURL = newString;
                                                   }
                                               }
                                               requestURL = [requestURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                                               requestURL = [requestURL stringByReplacingOccurrencesOfString:@"https://" withString:@""];
                                               requestURL = [requestURL stringByReplacingOccurrencesOfString:@"www." withString:@""];
                                               [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.baidu.com/s?wd=%@", requestURL]]]];
                                           }
                                           
                                       }];
        UIAlertAction *reloadAction = [UIAlertAction
                                       actionWithTitle:@"重新加载页面"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           previousURL = @"";
                                           [self.webview reload];
                                       }];
        UIAlertAction *newurlAction = [UIAlertAction
                                       actionWithTitle:@"输入网址或搜索"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self requestURLorSearchInput];
                                       }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"确定"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                       }];
        if (requestURL != nil) {
            if ([requestURL length] > 1) {
                [alertController addAction:searchAction];
            }
        }
        if (_webview.request != nil) {
            if (![_webview.request.URL.absoluteString  isEqual: @""]) {
                [alertController addAction:reloadAction];
            }
            else {
                [alertController addAction:newurlAction];
            }
        }
        else {
            [alertController addAction:newurlAction];
        }
        
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}
-(void)toggleMode
{
    self.cursorMode = !self.cursorMode;
    
    if (self.cursorMode)
    {
        self.webview.scrollView.scrollEnabled = NO;
        self.webview.userInteractionEnabled = NO;
        cursorView.hidden = NO;
    }
    else
    {
        self.webview.scrollView.scrollEnabled = YES;
        self.webview.userInteractionEnabled = YES;
        cursorView.hidden = YES;
    }
}
- (void)showHintsAlert
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"帮助"
                                          message:@"双击Apple TV遥控器触摸区域的中心，在光标和滚动模式之间切换；单击触摸区域以选择；单击菜单返回上一页；单击播放/暂停按钮可让您输入网址（无模糊匹配或自动搜索）；双击播放/暂停或菜单更多的选择。"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *hideForeverAction = [UIAlertAction
                                        actionWithTitle:@"不要再显示"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                                        {
                                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DontShowHintsOnLaunch"];
                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                        }];
    UIAlertAction *showForeverAction = [UIAlertAction
                                        actionWithTitle:@"始终显示"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                                        {
                                            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DontShowHintsOnLaunch"];
                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                        }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"确定"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DontShowHintsOnLaunch"]) {
        [alertController addAction:showForeverAction];
    }
    else {
        [alertController addAction:hideForeverAction];
    }
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}
- (void)alertTextFieldShouldReturn:(UITextField *)sender
{
    /*
     _inputViewVisible = NO;
     UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
     if (alertController)
     {
     [alertController dismissViewControllerAnimated:true completion:nil];
     if ([temporaryURL containsString:@" "] || ![temporaryURL containsString:@"."]) {
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@" " withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"." withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
     temporaryURL = [temporaryURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
     if (temporaryURL != nil) {
     [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.baidu.com/s?wd=%@", temporaryURL]]]];
     }
     else {
     [self requestURLorSearchInput];
     }
     temporaryURL = nil;
     }
     else {
     if (temporaryURL != nil) {
     if ([temporaryURL containsString:@"http://"] || [temporaryURL containsString:@"https://"]) {
     [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", temporaryURL]]]];
     temporaryURL = nil;
     }
     else {
     [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
     temporaryURL = nil;
     }
     }
     else {
     [self requestURLorSearchInput];
     }
     }
     
     }
     */
}
-(void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    
    if (presses.anyObject.type == UIPressTypeMenu)
    {
        UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
        if (alertController)
        {
            [self.presentedViewController dismissViewControllerAnimated:true completion:nil];
        }
        else if ([self.webview canGoBack]) {
            [self.webview goBack];
        }
        else {
            [self requestURLorSearchInput];
        }
        
    }
    else if (presses.anyObject.type == UIPressTypeUpArrow)
    {
        // Zoom testing (needs work) (requires old remote for up arrow)
        //UIScrollView * sv = self.webview.scrollView;
        //[sv setZoomScale:30];
    }
    else if (presses.anyObject.type == UIPressTypeDownArrow)
    {
    }
    else if (presses.anyObject.type == UIPressTypeSelect)
    {
        if(!self.cursorMode)
        {
            //[self toggleMode];
        }
        else
        {
            /* Gross. */
            CGPoint point = [self.webview convertPoint:cursorView.frame.origin toView:nil];
            
            [self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
            // Make the UIWebView method call
            NSString *fieldType = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).type;", (int)point.x, (int)point.y]];
            /*
             if (fieldType == nil) {
             NSString *contentEditible = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).getAttribute('contenteditable');", (int)point.x, (int)point.y]];
             NSLog(contentEditible);
             if ([contentEditible isEqualToString:@"true"]) {
             fieldType = @"text";
             }
             }
             else if ([[fieldType stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
             NSString *contentEditible = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).getAttribute('contenteditable');", (int)point.x, (int)point.y]];
             NSLog(contentEditible);
             if ([contentEditible isEqualToString:@"true"]) {
             fieldType = @"text";
             }
             }
             NSLog(fieldType);
             */
            fieldType = fieldType.lowercaseString;
            if ([fieldType isEqualToString:@"date"] || [fieldType isEqualToString:@"datetime"] || [fieldType isEqualToString:@"datetime-local"] || [fieldType isEqualToString:@"email"] || [fieldType isEqualToString:@"month"] || [fieldType isEqualToString:@"number"] || [fieldType isEqualToString:@"password"] || [fieldType isEqualToString:@"tel"] || [fieldType isEqualToString:@"text"] || [fieldType isEqualToString:@"time"] || [fieldType isEqualToString:@"url"] || [fieldType isEqualToString:@"week"]) {
                NSString *fieldTitle = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).title;", (int)point.x, (int)point.y]];
                if ([fieldTitle isEqualToString:@""]) {
                    fieldTitle = fieldType;
                }
                NSString *placeholder = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).placeholder;", (int)point.x, (int)point.y]];
                if ([placeholder isEqualToString:@""]) {
                    if (![fieldTitle isEqualToString:fieldType]) {
                        placeholder = [NSString stringWithFormat:@"输入%@", fieldTitle];
                    }
                    else {
                        placeholder = @"输入文字";
                    }
                }
                NSString *testedFormResponse = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).form.hasAttribute('onsubmit');", (int)point.x, (int)point.y]];
                UIAlertController *alertController = [UIAlertController
                                                      alertControllerWithTitle:@"键入文本"
                                                      message: [fieldTitle capitalizedString]
                                                      preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
                 {
                     if ([fieldType isEqualToString:@"url"]) {
                         textField.keyboardType = UIKeyboardTypeURL;
                     }
                     else if ([fieldType isEqualToString:@"email"]) {
                         textField.keyboardType = UIKeyboardTypeEmailAddress;
                     }
                     else if ([fieldType isEqualToString:@"tel"] || [fieldType isEqualToString:@"number"] || [fieldType isEqualToString:@"date"] || [fieldType isEqualToString:@"datetime"] || [fieldType isEqualToString:@"datetime-local"]) {
                         textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                     }
                     else {
                         textField.keyboardType = UIKeyboardTypeDefault;
                     }
                     textField.placeholder = [placeholder capitalizedString];
                     if ([fieldType isEqualToString:@"password"]) {
                         textField.secureTextEntry = YES;
                     }
                     textField.text = [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).value;", (int)point.x, (int)point.y]];
                     textField.textColor = [UIColor blackColor];
                     textField.backgroundColor = [UIColor whiteColor];
                     [textField setReturnKeyType:UIReturnKeyDone];
                     [textField addTarget:self
                                   action:@selector(alertTextFieldShouldReturn:)
                         forControlEvents:UIControlEventEditingDidEnd];
                     
                 }];
                UIAlertAction *inputAndSubmitAction = [UIAlertAction
                                                       actionWithTitle:@"发送"
                                                       style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action)
                                                       {
                                                           UITextField *inputViewTextField = alertController.textFields[0];
                                                           NSString *javaScript = [NSString stringWithFormat:@"var textField = document.elementFromPoint(%i, %i);"
                                                                                   "textField.value = '%@';"
                                                                                   "textField.form.submit();"
                                                                                   //"var ev = document.createEvent('KeyboardEvent');"
                                                                                   //"ev.initKeyEvent('keydown', true, true, window, false, false, false, false, 13, 0);"
                                                                                   //"document.body.dispatchEvent(ev);"
                                                                                   , (int)point.x, (int)point.y, inputViewTextField.text];
                                                           [_webview stringByEvaluatingJavaScriptFromString:javaScript];
                                                       }];
                UIAlertAction *inputAction = [UIAlertAction
                                              actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action)
                                              {
                                                  UITextField *inputViewTextField = alertController.textFields[0];
                                                  NSString *javaScript = [NSString stringWithFormat:@"var textField = document.elementFromPoint(%i, %i);"
                                                                          "textField.value = '%@';", (int)point.x, (int)point.y, inputViewTextField.text];
                                                  [_webview stringByEvaluatingJavaScriptFromString:javaScript];
                                              }];
                UIAlertAction *cancelAction = [UIAlertAction
                                               actionWithTitle:@"取消"
                                               style:UIAlertActionStyleCancel
                                               handler:^(UIAlertAction *action)
                                               {
                                               }];
                [alertController addAction:inputAction];
                if (testedFormResponse != nil) {
                    if ([testedFormResponse isEqualToString:@"true"]) {
                        [alertController addAction:inputAndSubmitAction];
                    }
                }
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
                UITextField *inputViewTextField = alertController.textFields[0];
                if ([[inputViewTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]) {
                    [inputViewTextField becomeFirstResponder];
                }
            }
            else {
                //[self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
            }
            //[self toggleMode];
        }
    }
    
    else if (presses.anyObject.type == UIPressTypePlayPause)
    {
        UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
        if (alertController)
        {
            [self.presentedViewController dismissViewControllerAnimated:true completion:nil];
        }
        else {
            [self requestURLorSearchInput];
        }
    }
}
- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateBegan) {
        //[self toggleMode];
        /*
         //if ([_webview.scrollView zoomScale] != 1.0) {
         if (![[_webview stringByEvaluatingJavaScriptFromString:@"document. body.style.zoom;"]  isEqual: @"1.0"]) {
         [_webview stringByEvaluatingJavaScriptFromString:@"document. body.style.zoom = 1.0;"];
         }
         else {
         [_webview stringByEvaluatingJavaScriptFromString:@"document. body.style.zoom = 5.0;"];
         }
         */
        
    }
    else if ( gesture.state == UIGestureRecognizerStateEnded) {
        //[self toggleMode];
    }
}

#pragma mark - Cursor Input

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.lastTouchLocation = CGPointMake(-1, -1);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInView:self.webview];
        
        if(self.lastTouchLocation.x == -1 && self.lastTouchLocation.y == -1)
        {
            // Prevent cursor from recentering
            self.lastTouchLocation = location;
        }
        else
        {
            CGFloat xDiff = location.x - self.lastTouchLocation.x;
            CGFloat yDiff = location.y - self.lastTouchLocation.y;
            CGRect rect = cursorView.frame;
            
            if(rect.origin.x + xDiff >= 0 && rect.origin.x + xDiff <= 1920)
                rect.origin.x += xDiff;//location.x - self.startPos.x;//+= xDiff; //location.x;
            
            if(rect.origin.y + yDiff >= 0 && rect.origin.y + yDiff <= 1080)
                rect.origin.y += yDiff;//location.y - self.startPos.y;//+= yDiff; //location.y;
            
            cursorView.frame = rect;
            self.lastTouchLocation = location;
        }
        
        // We only use one touch, break the loop
        break;
    }
    
}



@end
