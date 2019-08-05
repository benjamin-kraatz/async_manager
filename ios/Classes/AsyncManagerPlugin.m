#import "AsyncManagerPlugin.h"
#import <async_manager/async_manager-Swift.h>

@implementation AsyncManagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAsyncManagerPlugin registerWithRegistrar:registrar];
}
@end
