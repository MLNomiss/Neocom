//
//  NCDBDgmppItemSpaceStructureResources+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemSpaceStructureResources+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemSpaceStructureResources (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemSpaceStructureResources *> *)fetchRequest;

@property (nonatomic) int16_t hiSlots;
@property (nonatomic) int16_t launchers;
@property (nonatomic) int16_t lowSlots;
@property (nonatomic) int16_t medSlots;
@property (nonatomic) int16_t rigSlots;
@property (nonatomic) int16_t serviceSlots;
@property (nonatomic) int16_t turrets;
@property (nullable, nonatomic, retain) NCDBDgmppItem *item;

@end

NS_ASSUME_NONNULL_END
