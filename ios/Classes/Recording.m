#import "Recording.h"


@implementation Recording

+ (NSString *)primaryKey {
    return @"uuid";
}

+ (NSArray *)indexedProperties {
    return @[@"title", @"scheduleId"];
}
@end
