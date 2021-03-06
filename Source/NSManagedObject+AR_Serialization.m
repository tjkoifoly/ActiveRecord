//
//  NSManagedObject+AR_Serialization.m
//  ActiveRecord
//
//  Created by Michal Konturek on 19/03/2014.
//  Copyright (c) 2014 Michal Konturek. All rights reserved.
//

#import "NSManagedObject+AR_Serialization.h"

#import "NSManagedObject+AR.h"
#import "NSManagedObject+AR_Context.h"
#import "NSManagedObject+AR_Finders.h"

#import "NSRelationshipDescription+AR.h"
#import "NSPredicate+AR.h"

#import "ARConverter.h"

@implementation NSManagedObject (AR_Serialization)

+ (instancetype)createOrUpdateWithData:(NSDictionary *)data {
    id pk = [self primaryKey];
    id value = [data objectForKey:pk];
    id predicate = [NSPredicate createFrom:@{pk: value}];
    return [self createOrUpdateWithData:data usingPredicate:predicate];
}

+ (instancetype)createOrUpdateWithData:(NSDictionary *)data
                        usingPredicate:(NSPredicate *)predicate {
    
    id object = [self objectWithPredicate:predicate];
    if (!object) object = [self create];
    
    object = [object updateWithData:data];
    
    return object;
}

- (instancetype)updateWithData:(NSDictionary *)data {
    return [[self updateWithAttributesData:data] updateWithRelationshipsData:data];
}

- (instancetype)updateWithAttributesData:(NSDictionary *)data {
    
    NSDictionary *attributes = [[self entity] attributesByName];
    for (NSString *attribute in [attributes allKeys]) {
        
        id value = [data objectForKey:attribute];
        if (((NSNull *)value != [NSNull null]) && (value != nil)) {
            NSAttributeType type = [[attributes objectForKey:attribute] attributeType];
            value = [[ARConverter create] convert:value toAttributeType:type];
            if (value) [self setValue:value forKey:attribute];
        }
    }
    
    return self;
}

- (instancetype)updateWithRelationshipsData:(NSDictionary *)data {
    
    NSDictionary *relationships = [[self entity] relationshipsByName];
    for (NSString *relationship in [relationships allKeys]) {
        
        id relatedObject = [data objectForKey:relationship];
        if (!relatedObject) continue;
        
        NSRelationshipDescription *description = [[[self entity] relationshipsByName] objectForKey:relationship];
        if ([description isToMany]) {
            
            if ([relatedObject isKindOfClass:[NSArray class]]) {
                NSMutableSet *relatedObjectSet = [self mutableSetValueForKey:relationship];
                
                for (id __strong item in relatedObject) {
                    item = [description managedObjectFrom:item];
                    if (item) [relatedObjectSet addObject:item];
                }
                
                [self setValue:relatedObjectSet forKey:relationship];
            }
        } else {
            relatedObject = [description managedObjectFrom:relatedObject];
            if (relatedObject) [self setValue:relatedObject forKey:relationship];
        }
    }
    
    return self;
}

- (NSDictionary *)dictionary {
    id result = [NSMutableDictionary dictionary];
    
    id attributes = [[self entity] attributesByName];
    for (NSString *key in [attributes allKeys]) {
        id value = [self valueForKey:key];
        if (value) [result setObject:value forKey:key];
    }
    
    return result;
}

@end
