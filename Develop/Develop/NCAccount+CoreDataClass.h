//
//  NCAccount+CoreDataClass.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCAPIKey, NCMailBox, NCSkillPlan;

NS_ASSUME_NONNULL_BEGIN

@interface NCAccount : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "NCAccount+CoreDataProperties.h"
