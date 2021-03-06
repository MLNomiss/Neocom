//
//  NCFittingGang.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"

@class NCFittingCharacter;
@interface NCFittingGang : NCFittingItem
@property (readonly, nonnull) NSArray<NCFittingCharacter*>* pilots;

- (nullable NCFittingCharacter*) addPilot;
- (void) removePilot:(nonnull NCFittingCharacter*) character;

@end
