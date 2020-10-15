//
//  FlutterRealm.m
//  flutter_realm
//
//  Created by German Saprykin on 4/8/19.
//

#import "FlutterRealm.h"

#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>
#import "Recording.h"

@interface FlutterRealm ()
@property (strong, nonatomic) RLMRealm *realm;
@property (strong, nonatomic) FlutterMethodChannel *channel;
@property (strong, nonatomic) NSMutableDictionary<NSString *,RLMNotificationToken *> *tokens;
@property (copy, nonatomic) NSString *realmId;

@end

@implementation RLMObject (FlutterRealm)

- (NSDictionary *)toMap {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    
    for (RLMProperty *p in [[self objectSchema] properties]) {
        
        if ([self[p.name] isKindOfClass:[RLMArray class]]){
            RLMArray *data = self[p.name];
            NSMutableArray *sendData = [NSMutableArray array];
            for (id item in data) {
                [sendData addObject:item];
            }
            map[p.name] = sendData;
        }else {
            map[p.name] = self[p.name];
        }
    }
    
    return map;
}

@end

@implementation FlutterRealm

- (instancetype)initWithRealm:(RLMRealm *)realm channel:(FlutterMethodChannel *)channel identifier:(NSString *)identifier {
    self = [super init];
    
    if (self != nil) {
        _realmId = identifier;
        _channel = channel;
        _tokens = [NSMutableDictionary dictionary];
        _realm = realm;
    }
    
    return self;
}

- (instancetype)initWithArguments:(NSDictionary *)arguments channel:(FlutterMethodChannel *)channel identifier:(NSString *)identifier{
    self = [super init];
    
    if (self != nil) {
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        
        if ([arguments[@"inMemoryIdentifier"] isKindOfClass:[NSString class]]){
            config.inMemoryIdentifier = arguments[@"inMemoryIdentifier"];
        }
        if ([arguments[@"encryptionKey"] isKindOfClass:[NSData class]]){
            config.encryptionKey = arguments[@"encryptionKey"];
        }
        _realmId = identifier;
        _channel = channel;
        _tokens = [NSMutableDictionary dictionary];
        _realm = [RLMRealm realmWithConfiguration:config error:nil];
    }
    
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];
    NSString *method = [call method];
    @try {
        
        if ([@"createObject" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            if (classname == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            
            NSDictionary *value = [self sanitizeReceivedValue:arguments];
            [self.realm beginWriteTransaction];
            RLMObject *object = [self.realm createObject:classname withValue:value];
            [self.realm commitWriteTransaction];
            
            result([object toMap]);
        }   else if ([@"object" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            id primaryKey = arguments[@"primaryKey"];
            
            if (classname == nil || primaryKey == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMObject *object = [self.realm objectWithClassName:classname forPrimaryKey:primaryKey];
            if (object == nil) {
                result([self notFoundFor:call]);
                return;
            }
            
            result([object toMap]);
        }    else if ([@"allObjects" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            if (classname == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMResults *allObjects = [self.realm allObjects:classname];
            NSArray *items = [self convert:allObjects limit:nil];
            result(items);
        }  else if ([@"updateObject" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            NSDictionary *value = arguments[@"value"];
            id primaryKey = arguments[@"primaryKey"];
            
            if (classname == nil || primaryKey == nil|| value == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMObject *object = [self.realm objectWithClassName:classname forPrimaryKey:primaryKey];
            if (object == nil) {
                result([self notFoundFor:call]);
                return;
            }
            
            value = [self sanitizeReceivedValue:value];
            
            [self.realm beginWriteTransaction];
            [object setValuesForKeysWithDictionary:value];
            [self.realm commitWriteTransaction];
            
            result([object toMap]);
        }   else if ([@"deleteObject" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            id primaryKey = arguments[@"primaryKey"];
            
            if (classname == nil || primaryKey == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMObject *object = [self.realm objectWithClassName:classname forPrimaryKey:primaryKey];
            if (object == nil) {
                result([self notFoundFor:call]);
                return;
            }
            
            [self.realm transactionWithBlock:^{
                [self.realm deleteObject:object];
            }];
            
            result(nil);
        }   else if ([@"deleteRecording" isEqualToString:method]) {
            id primaryKey = arguments[@"primaryKey"];
            NSString* scheduleId = arguments[@"scheduleId"];
            
            if (primaryKey == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            Recording *recording = [Recording objectForPrimaryKey:primaryKey];
            if (recording == nil) {
                result([self notFoundFor:call]);
                return;
            }
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"scheduleId = %@",
                                 scheduleId];
            [self.realm transactionWithBlock:^{
                NSString *path = recording.path;
                NSError *error;
                [self.realm deleteObject:recording];
                NSLog(@"Start delete file at path: %@", path);
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error) {
                    NSLog(@"Error removing file at path: %@", path);
                }
            }];
            RLMResults<Recording *> *recordingsForSchedule = [Recording objectsWithPredicate:pred];
            
            result([NSNumber numberWithLong:recordingsForSchedule.count]);
        }   else if ([@"deleteAllRecordings" isEqualToString:method]) {
            NSArray<NSString*>* ids = arguments[@"primaryKeys"];
            NSString* scheduleId = arguments[@"scheduleId"];
            
            if (ids == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"scheduleId = %@",
                                 scheduleId];
             RLMResults<Recording *> *recordingsForSchedule = [Recording objectsWithPredicate:pred];
            [self.realm transactionWithBlock:^{
                NSMutableArray<NSString*> *items = [NSMutableArray array];
                for (Recording *item in recordingsForSchedule) {
                    [items addObject:item.path];
                }
                [self.realm deleteObjects:recordingsForSchedule];
                for (NSString *item in items) {
                    NSError *error;
                    NSLog(@"Start delete file at path: %@", item);
                    [[NSFileManager defaultManager] removeItemAtPath:item error:&error];
                    if (error) {
                        NSLog(@"Error removing file at path: %@", item);
                    }
                }
            }];
            result([NSNumber numberWithLong:recordingsForSchedule.count]);
        }   else if ([@"getRecordingIdsForScheduleIds" isEqualToString:method]) {
            NSArray<NSString*>* scheduleIds = arguments[@"scheduleIds"];
            NSString *orderBy = arguments[@"orderBy"];
            NSNumber *ascending = arguments[@"ascending"];
            BOOL isAscending = [ascending boolValue];
            
            if (scheduleIds == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"scheduleId IN %@",
                                 scheduleIds];
            RLMResults<Recording *> *results = [Recording objectsWithPredicate:pred];
            if (orderBy) {
                results = [results sortedResultsUsingKeyPath:orderBy ascending:isAscending];
            }
            NSMutableArray *items = [NSMutableArray array];
            for (Recording *item in results) {
                [items addObject:@{
                    @"uuid": item.uuid,
                    @"scheduleId": item.scheduleId,
                }];
            }
            result(@{
              @"results":items,
              @"count": @(results.count)
            });
        }   else if ([@"getRecordingIdsForSchedule" isEqualToString:method]) {
                 NSString* scheduleId = arguments[@"scheduleId"];
                 NSString *orderBy = arguments[@"orderBy"];
                 NSNumber *ascending = arguments[@"ascending"];
                 BOOL isAscending = [ascending boolValue];
                 
                 if (scheduleId == nil){
                     result([self invalidParametersFor:call]);
                     return;
                 }
                 NSPredicate *pred = [NSPredicate predicateWithFormat:@"scheduleId == %@",
                                      scheduleId];
                 RLMResults<Recording *> *results = [Recording objectsWithPredicate:pred];
                if (orderBy) {
                    results = [results sortedResultsUsingKeyPath:orderBy ascending:isAscending];
                }
                 NSMutableArray *items = [NSMutableArray array];
                 for (Recording *item in results) {
                     [items addObject:item.uuid];
                 }
                 result(@{
                   @"results":items,
                   @"count": @(results.count)
                 });
             }
        else if ([@"getScheduleIdsWithRecordings" isEqualToString:method]) {
            NSArray<NSString*>* scheduleIds = arguments[@"scheduleIds"];
            
            if (scheduleIds == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"scheduleId IN %@",
                                 scheduleIds];
            RLMResults<Recording *> *results = [Recording objectsWithPredicate:pred];
            results = [results distinctResultsUsingKeyPaths:@[@"scheduleId"]];
            NSMutableArray *items = [NSMutableArray array];
            for (Recording *item in results) {
                [items addObject:item.scheduleId];
            }
            result(@{
              @"results":items,
              @"count": @(results.count)
            });
        }   else if ([@"getAllScheduleIds" isEqualToString:method]) {
            NSNumber *limit = arguments[@"limit"];
            NSString *orderBy = arguments[@"orderBy"];
            NSNumber *ascending = arguments[@"ascending"];
            BOOL isAscending = [ascending boolValue];
            RLMResults<Recording *> *results = [Recording allObjects];
            results = [results distinctResultsUsingKeyPaths:@[@"scheduleId"]];
            if (orderBy) {
                results = [results sortedResultsUsingKeyPath:orderBy ascending:isAscending];
            }
            NSMutableArray *items = [NSMutableArray array];
            if (limit >= 0) {
                uint64_t realLimit = MIN([limit longValue], results.count);
                for (int i = 0; i < realLimit; ++i) {
                    [items addObject:results[i].scheduleId];
                }
            } else {
                for (Recording *item in results) {
                    [items addObject:item.scheduleId];
                }
            }
            result(@{
                  @"results":items,
                  @"count": @(results.count)
                });
        }
        else if ([@"subscribeAllObjects" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            NSString *subscriptionId = arguments[@"subscriptionId"];
            
            if (classname == nil || subscriptionId == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMResults *allObjects = [self.realm allObjects:classname];
            
            id subscribeResult = [self subscribe:allObjects
                                  subscriptionId:subscriptionId
                                            call:call limit:nil];
            result(subscribeResult);
        } else if ([@"objects"  isEqualToString:method]) {
            
            NSString *classname = arguments[@"$"];
            NSArray *predicate = arguments[@"predicate"];
            NSNumber *limit = arguments[@"limit"];
            NSString *orderBy = arguments[@"orderBy"];
            NSNumber *ascending = arguments[@"ascending"];
            BOOL isAscending = [ascending boolValue];
            
            if (classname == nil || predicate == nil ){
                result([self invalidParametersFor:call]);
                return;
            }
            NSMutableArray *items = [NSMutableArray array];
            RLMResults *results = [self.realm objects:classname withPredicate:[self generatePredicate:predicate]];
            if (orderBy) {
                results = [results sortedResultsUsingKeyPath:orderBy ascending:isAscending];
            }
            if (limit >= 0) {
                uint64_t realLimit = MIN([limit longValue], results.count);
                for (int i = 0; i < realLimit; ++i) {
                    [items addObject:[results[i] toMap]];
                }
            } else {
                for (RLMObject *item in results) {
                    [items addObject:[item toMap]];
                }
            }
            result(@{
              @"results":items,
              @"count": @(results.count)
            });
        }  else if ([@"subscribeObjects"  isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            NSString *subscriptionId = arguments[@"subscriptionId"];
            NSArray *predicate = arguments[@"predicate"];
            NSNumber *limit = arguments[@"limit"];
            NSString *orderBy = arguments[@"orderBy"];
            NSNumber *ascending = arguments[@"ascending"];
            BOOL isAscending = [ascending boolValue];
            
            
            if (classname == nil || predicate == nil || subscriptionId == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            
            RLMResults *results = [self.realm objects:classname withPredicate:[self generatePredicate:predicate]];
            if (orderBy) {
                results = [results sortedResultsUsingKeyPath:orderBy ascending:isAscending];
            }
            id subscribeResult = [self subscribe:results
                                  subscriptionId:subscriptionId
                                            call:call limit:limit >= 0 ? limit : nil];
            result(subscribeResult);
        } else if ([@"unsubscribe" isEqualToString:method]) {
            NSString *subscriptionId = arguments[@"subscriptionId"];
            if (subscriptionId == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            
            RLMNotificationToken *token = self.tokens[subscriptionId];
            if (token == nil) {
                result([self notSubcribed:call]);
                return;
            }
            [token invalidate];
            [self.tokens removeObjectForKey:subscriptionId];
            result(nil);
        } else if ([@"deleteAllObjects" isEqualToString:method]){
            [self deleteAllObjects];
            result(nil);
        }  else if ([@"filePath" isEqualToString:method]){
            result([[self.realm.configuration fileURL] absoluteString]);
        } else {
            result(FlutterMethodNotImplemented);
        }
    } @catch (NSException *exception) {
        if ([self.realm inWriteTransaction]){
            [self.realm cancelWriteTransaction];
        }
        NSLog(@"%@", exception.callStackSymbols);
        
        result([FlutterError errorWithCode:@"-1" message:exception.reason details:[exception.userInfo description]]);
    }
}

- (void)reset {
    for (RLMNotificationToken *token in self.tokens.allValues) {
        [token invalidate];
    }
    [self.tokens removeAllObjects];
    [self deleteAllObjects];
}


- (void)deleteAllObjects {
    [self.realm beginWriteTransaction];
    [self.realm deleteAllObjects];
    [self.realm commitWriteTransaction];
}


- (NSArray *)convert:(RLMResults *)results limit:(NSNumber*)limit{
    NSMutableArray *items = [NSMutableArray array];
    if (limit) {
        uint64_t realLimit = MIN([limit longValue], results.count);
        for (int i = 0; i < realLimit; ++i) {
            [items addObject:[results[i] toMap]];
        }
    } else {
        for (RLMObject *item in results) {
            [items addObject:[item toMap]];
        }
    }
    return items;
}

- (FlutterError *)invalidParametersFor:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"1"
                                message:@"Invalid parameter's type"
                                details:@{
                                    @"method":call.method,
                                    @"arguments":call.arguments
                                }
             ];
    
}
- (FlutterError *)alreadySubcribed:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"2"
                                message:@"Already subscribed"
                                details:@{
                                    @"method":call.method,
                                    @"arguments":call.arguments
                                }
             ];
    
}

- (FlutterError *)notSubcribed:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"3"
                                message:@"Not subscribed"
                                details:@{
                                    @"method":call.method,
                                    @"arguments":call.arguments
                                }
             ];
    
}

- (FlutterError *)notFoundFor:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"4"
                                message:@"Object not found"
                                details:@{
                                    @"method":call.method,
                                    @"arguments":call.arguments
                                }
             ];
    
}

- (FlutterError *)deletErrorFor:(FlutterMethodCall *)call error:(NSError*) error{
    return  [FlutterError errorWithCode:@"5"
                                message:error.localizedDescription
                                details:@{
                                    @"method":call.method,
                                    @"arguments":call.arguments
                                }
             ];
    
}

- (id)subscribe:(RLMResults *)results subscriptionId:(NSString *) subscriptionId call:(FlutterMethodCall *)call limit:(NSNumber *)limit{
    if (self.tokens[subscriptionId] != nil){
        return [self alreadySubcribed:call];
    }
    
    RLMNotificationToken *token = [results addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        [self.channel invokeMethod:@"onResultsChange" arguments:@{
            @"realmId": self.realmId,
            @"subscriptionId": subscriptionId,
            @"results" : [self convert:results limit:limit],
            @"count": @(results.count),
        }];
    }];
    
    self.tokens[subscriptionId] = token;
    
    return nil;
}

- (NSPredicate *)generatePredicate:(NSArray *) items{
    NSMutableString *format = [NSMutableString string];
    
    NSDictionary *codeToOperator = @{
        @"greaterThan":@">",
        @"greaterThanOrEqualTo":@">=",
        @"lessThan":@"<",
        @"lessThanOrEqualTo":@"<=",
        @"equalTo":@"==",
        @"notEqualTo":@"!=",
        @"contains":@"CONTAINS",
        @"in":@"IN"
    };
    NSMutableArray *arguments = [NSMutableArray array];
    
    for (NSArray *item in items){
        NSString *code = item[0];
        if ([code isEqualToString:@"and"] || [code isEqualToString:@"or"]){
            [format appendString:code];
        }else {
            NSString *operator = codeToOperator[code];
            NSParameterAssert(operator);
            
            [format appendFormat:@"%@ %@ %%@", item[1], operator];
            [arguments addObject:item[2]];
        }
        [format appendString:@" "];
    }
    return [NSPredicate predicateWithFormat:format argumentArray:arguments];
}


- (NSDictionary *)sanitizeReceivedValue:(NSDictionary *)value {
    NSMutableDictionary *result = [value mutableCopy];
    [result removeObjectForKey:@"$"];
    for (NSString *key in value.allKeys) {
        if ([result[key] isKindOfClass:[FlutterStandardTypedData class]]){
            FlutterStandardTypedData *data = result[key];
            result[key] = [data data];
        }
    }
    return result;
}

@end
