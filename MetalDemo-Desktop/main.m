//
//  main.m
//  MetalDemo-Desktop
//
//  Created by r.kuznetsov on 08.06.2018.
//  Copyright © 2018 rokuz. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[])
{
  @autoreleasepool
  {
    AppDelegate * delegate = [AppDelegate new];
    NSApplication.sharedApplication.delegate = delegate;
    return NSApplicationMain(argc, argv);
  }
}
