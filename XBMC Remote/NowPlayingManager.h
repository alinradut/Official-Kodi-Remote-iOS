//
//  NowPlayingManager.h
//  Kodi Remote
//
//  Created by Alin Radut on 2023-10-15.
//  Copyright © 2023 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NowPlayingItem;
@class PlayerInfo;

@interface NowPlayingManager : NSObject

@property (nonatomic) BOOL isEnabled;
@property (nonatomic, strong) NowPlayingItem *nowPlayingItem;
@property (nonatomic, strong) PlayerInfo *playerInfo;

@end

NS_ASSUME_NONNULL_END
