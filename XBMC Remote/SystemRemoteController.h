//
//  SystemRemoteController.h
//  Kodi Remote
//
//  Created by Alin Radut on 2023-10-14.
//  Copyright © 2023 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SystemRemoteController : NSObject

@property (nonatomic) BOOL isEnabled;

+ (id)sharedManager;
- (void)setup;

@end

NS_ASSUME_NONNULL_END
