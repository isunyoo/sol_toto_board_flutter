#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FIRAppCheckInterop.h"
#import "FIRAppCheckTokenResultInterop.h"

FOUNDATION_EXPORT double FirebaseAppCheckInteropVersionNumber;
FOUNDATION_EXPORT const unsigned char FirebaseAppCheckInteropVersionString[];

