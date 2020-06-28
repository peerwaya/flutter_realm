  

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>


@interface Recording : RLMObject

@property NSString *uuid;
@property NSNumber<RLMInt> *createdAt;
@property NSNumber<RLMInt> *videoWidth;
@property NSNumber<RLMInt> *videoHeight;
@property NSString* scheduleId;
@property NSString* title;
@property NSNumber<RLMDouble>* duration;
@property NSNumber<RLMInt> *thumbnailWidth;
@property NSNumber<RLMInt> *thumbnailHeight;
@property NSData* thumbnailData;
@property NSNumber<RLMDouble> *frameRate;
@property NSNumber<RLMInt> *fileSize;
@property NSString* digest;
@property NSString* cloudSyncTaskId;
@property NSString* cloudSyncStatus;
@property NSString* cloudStorageProvider;
@property NSString* cloudStorageProviderId;
@property NSString* path;
@property NSString* mimeType;
@end
