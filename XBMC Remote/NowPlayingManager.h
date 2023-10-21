//
//  NowPlayingManager.h
//  Kodi Remote
//
//  Created by Alin Radut on 2023-10-15.
//  Copyright © 2023 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    RepeatTypeOff,
    RepeatTypeOne,
    RepeatTypeAll,
} RepeatType;

@interface NowPlayingItem : NSObject

@property (nonatomic) int playerID;
@property (nonatomic) long id;

@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *thumbnailPath;
@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, strong) NSString *track;
@property (nonatomic, strong) NSString *studio;
@property (nonatomic, strong) NSString *showTitle;
@property (nonatomic, strong) NSString *episode;
@property (nonatomic, strong) NSString *season;
@property (nonatomic, strong) NSString *fanart;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *description_;
@property (nonatomic, strong) NSString *year;
@property (nonatomic, strong) NSString *director;
@property (nonatomic, strong) NSString *plot;

@property (nonatomic, strong) NSString *type;

@property (nonatomic, strong) NSString *clearArt;
@property (nonatomic, strong) NSString *clearLogo;

@property (nonatomic, strong) UIImage *coverArt;
@property (nonatomic, strong) UIImage *thumbnail;

@property (nonatomic) BOOL isLiveStream;
@property (nonatomic) NSTimeInterval position;
@property (nonatomic) NSTimeInterval duration;

@end

@interface PlayerInfo : NSObject

@property (nonatomic) CGFloat percentage;
@property (nonatomic) CGFloat time;
@property (nonatomic) CGFloat totalTime;
@property (nonatomic) CGFloat speed;
@property (nonatomic) BOOL partyMode;
@property (nonatomic) NSInteger playlistPosition;
@property (nonatomic) BOOL canRepeat;
@property (nonatomic) BOOL canShuffle;
@property (nonatomic) BOOL repeat;
@property (nonatomic) BOOL shuffled;
@property (nonatomic) BOOL canSeek;
@property (nonatomic) RepeatType repeatType;

@property (nonatomic) CGFloat duration;
@property (nonatomic) CGFloat posSeconds;
@property (nonatomic, strong) NSString *globalTime;
@property (nonatomic, strong) NSString *actualTime;

@end


@interface NowPlayingManager : NSObject {
    NSTimer *_refreshTimer;
}

@property (nonatomic) BOOL isEnabled;
@property (nonatomic, strong) NowPlayingItem *nowPlayingItem;
@property (nonatomic, strong) PlayerInfo *playerInfo;

+ (id)sharedManager;
- (void)register;

@end

NS_ASSUME_NONNULL_END
