//
//  NCFittingEngine.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingEngine.h"
#import <Dgmpp/Dgmpp.h>
#import "NCFittingProtected.h"

@interface NCFittingEngine() {
	std::shared_ptr<dgmpp::Engine> _engine;
}

@end

@implementation NCFittingEngine

- (nonnull instancetype) init {
	if (self = [super init]) {
		_engine = std::make_shared<dgmpp::Engine>(std::make_shared<dgmpp::SqliteConnector>([[[NSBundle mainBundle] pathForResource:@"dgm" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
	}
	return self;
}

- (nonnull NCFittingGang*) gang {
	return [[NCFittingGang alloc] initWithItem: _engine->getGang()];
}

@end
