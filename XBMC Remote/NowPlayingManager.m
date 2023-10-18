//
//  NowPlayingManager.m
//  Kodi Remote
//
//  Created by Alin Radut on 2023-10-15.
//  Copyright © 2023 Team Kodi. All rights reserved.
//

#import "NowPlayingManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SDImageCache.h"
#import "Utilities.h"
#import "AppDelegate.h"
#define ID_INVALID -2

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

- (void)applyTo:(MPNowPlayingInfoCenter *)nowPlayingCenter;

@end

@implementation NowPlayingItem

- (void)updateWith:(NSDictionary *)nowPlayingInfo playerID:(int)playerID {
    
    self.playerID = playerID;
    self.id = nowPlayingInfo[@"id"] ? [nowPlayingInfo[@"id"] longValue] : ID_INVALID;
    
    // Set NowPlaying text fields
    // 1st: title
    self.label = [Utilities getStringFromItem:nowPlayingInfo[@"label"]];
    self.title = [Utilities getStringFromItem:nowPlayingInfo[@"title"]];

    if (self.title.length == 0) {
        self.title = self.label;
    }
    
    // 2nd: artists
    self.artist = [Utilities getStringFromItem:nowPlayingInfo[@"artist"]];
    self.studio = [Utilities getStringFromItem:nowPlayingInfo[@"studio"]];
    self.channel = [Utilities getStringFromItem:nowPlayingInfo[@"channel"]];
    if (self.artist.length == 0 && self.studio.length) {
        self.artist = self.studio;
    }
    if (self.artist.length == 0 && self.channel.length) {
        self.artist = self.channel;
    }
    
    // 3rd: album
    self.album = [Utilities getStringFromItem:nowPlayingInfo[@"album"]];
    self.showTitle = [Utilities getStringFromItem:nowPlayingInfo[@"showtitle"]];
    self.season = [Utilities getStringFromItem:nowPlayingInfo[@"season"]];
    self.episode = [Utilities getStringFromItem:nowPlayingInfo[@"episode"]];
    if (self.album.length == 0 && self.showTitle.length) {
        self.album = [Utilities formatTVShowStringForSeasonTrailing:self.season episode:self.episode title:self.showTitle];
    }
    self.director = [Utilities getStringFromItem:nowPlayingInfo[@"director"]];
    if (self.album.length == 0 && self.director.length) {
        self.album = self.director;
    }

    // Set cover size and load covers
    _type = [Utilities getStringFromItem:nowPlayingInfo[@"type"]];
    NSString *serverURL = [Utilities getImageServerURL];
    _thumbnailPath = [self getNowPlayingThumbnailPath:nowPlayingInfo];
    NSString *stringURL = [Utilities formatStringURL:_thumbnailPath serverURL:serverURL];


    if (IS_IPAD) {
        _fanart = nowPlayingInfo[@"fanart"] == [NSNull null] ? @"" : nowPlayingInfo[@"fanart"];
    }
    if ([_thumbnailPath isEqualToString:@""]) {
        UIImage *image = [UIImage imageNamed:@"coverbox_back"];
//        [self processLoadedThumbImage:self thumb:thumbnailView image:image enableJewel:enableJewel];
    }
    else {
        _thumbnailURL = stringURL;
        [[SDImageCache sharedImageCache] queryDiskCacheForKey:stringURL done:^(UIImage *image, SDImageCacheType cacheType) {
            if (image != nil) {
                _thumbnail = image;
            }
            else {
                // download the image
//                [thumbnailView sd_setImageWithURL:[NSURL URLWithString:stringURL]
//                                 placeholderImage:[UIImage imageNamed:@"coverbox_back"]
//                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
//                    if (error == nil) {
//                        [sf processLoadedThumbImage:sf thumb:thumb image:image enableJewel:enableJewel];
//                    }
//                }];
            }
        }];
    }

    NSDictionary *art = nowPlayingInfo[@"art"];
    _clearLogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
    _clearArt = [Utilities getClearArtFromDictionary:art type:@"clearart"];
    if ([_clearLogo isEqualToString:@""]) {
        _clearLogo = _clearArt;
    }
    if (![_clearLogo isEqualToString:@""]) {
        NSString *stringURL = [Utilities formatStringURL:_clearLogo serverURL:serverURL];
    }
}

- (void)applyTo:(MPNowPlayingInfoCenter *)nowPlayingCenter {
    
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
    nowPlayingInfo[MPMediaItemPropertyArtist] = _artist;
    nowPlayingInfo[MPMediaItemPropertyTitle] = _title;
    nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:_coverArt.size requestHandler:^UIImage * _Nonnull(CGSize size) {
        return _coverArt;
    }];
    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = [NSNumber numberWithBool:_isLiveStream];
    
    nowPlayingCenter.nowPlayingInfo = nowPlayingInfo;
}

- (NSString*)getNowPlayingThumbnailPath:(NSDictionary*)item {
    // If a recording is played, we can use the iocn (typically the station logo)
    BOOL useIcon = [item[@"type"] isEqualToString:@"recording"] || [item[@"recordingid"] longValue] > 0;
    return [Utilities getThumbnailFromDictionary:item useBanner:NO useIcon:useIcon];
}


@end

@interface PlayerInfo : NSObject

@property (nonatomic) CGFloat percentage;
@property (nonatomic) CGFloat time;
@property (nonatomic) CGFloat totalTime;
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

- (void)updateWith:(NSDictionary *)playerInfo;
- (void)applyTo:(MPNowPlayingInfoCenter *)nowPlayingCenter;

@end

@implementation PlayerInfo

- (void)updateWith:(NSDictionary *)playerInfo {
    _percentage = [(NSNumber*)playerInfo[@"percentage"] floatValue];
    _partyMode = [playerInfo[@"partymode"] intValue] != 0;
    BOOL canrepeat = [playerInfo[@"canrepeat"] boolValue] && !_partyMode;
    _canRepeat = [playerInfo[@"canrepeat"] boolValue] && !_partyMode;
    if (_canRepeat) {
        NSString *repeatStatus = playerInfo[@"repeat"];
        if ([repeatStatus isEqualToString:@"all"]) {
            _repeatType = RepeatTypeAll;
        }
        else if ([repeatStatus isEqualToString:@"one"]) {
            _repeatType = RepeatTypeOne;
        }
        else {
            _repeatType = RepeatTypeOff;
        }
    }
    else {
        _repeatType = RepeatTypeOff;
    }
    _canShuffle = [playerInfo[@"canshuffle"] boolValue] && !_partyMode;
    if (_canShuffle) {
        _shuffled = [playerInfo[@"shuffled"] boolValue];
    }
    else {
        _shuffled = false;
    }
    
    _canSeek = [playerInfo[@"canseek"] boolValue];
    
    NSDictionary *timeGlobal = playerInfo[@"totaltime"];
    int hoursGlobal = [timeGlobal[@"hours"] intValue];
    int minutesGlobal = [timeGlobal[@"minutes"] intValue];
    int secondsGlobal = [timeGlobal[@"seconds"] intValue];
    _globalTime = [NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"" : [NSString stringWithFormat:@"%02i:", hoursGlobal], minutesGlobal, secondsGlobal];
    _duration = hoursGlobal * 3600 + minutesGlobal * 60 + secondsGlobal;
    
    NSDictionary *time = playerInfo[@"time"];
    int hours = [time[@"hours"] intValue];
    int minutes = [time[@"minutes"] intValue];
    int seconds = [time[@"seconds"] intValue];
    float percentage = [(NSNumber*)playerInfo[@"percentage"] floatValue];
    _actualTime = [NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"" : [NSString stringWithFormat:@"%02i:", hours], minutes, seconds];
    
    _playlistPosition = [playerInfo[@"position"] longValue];
    if (_playlistPosition > -1) {
        _playlistPosition += 1;
    }
    // Detect start of new song to update party mode playlist
    _posSeconds = ((hours * 60) + minutes) * 60 + seconds;
}

- (void)applyTo:(MPNowPlayingInfoCenter *)nowPlayingCenter {
    
    NSMutableDictionary *nowPlayingInfo = [nowPlayingCenter.nowPlayingInfo mutableCopy];
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithFloat:_duration];
//    nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:_coverArt.size requestHandler:^UIImage * _Nonnull(CGSize size) {
//        return _coverArt;
//    }];
//    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = [NSNumber numberWithBool:_isLiveStream];
    
    nowPlayingCenter.nowPlayingInfo = nowPlayingInfo;
}

@end

@implementation NowPlayingManager

- (void)updateNowPlayingItem:(NowPlayingItem *)item {
    self.nowPlayingItem = item;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NowPlayingItemUpdated" object:_nowPlayingItem];
}

- (void)updatePlayerInfo:(PlayerInfo *)playerInfo {
    self.playerInfo = playerInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NowPlayingPlayerInfoUpdated" object:_playerInfo];
}

- (void)refresh {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] withTimeout:2.0 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        // Do not process further, if the view is already off the view hierarchy.
        if (!self.isEnabled) {
            return;
        }
        BOOL nothingIsPlaying = false;
        int currentPlayerID = 0;
        int lastPlayerID = 0;
        int selectedPlayerID = 0;
        
        if (error == nil && methodError == nil) {
            if ([methodResult isKindOfClass:[NSArray class]] && [methodResult count] > 0) {
                nothingIsPlaying = NO;
                NSNumber *response = methodResult[0][@"playerid"] != [NSNull null] ? methodResult[0][@"playerid"] : nil;
                currentPlayerID = [response intValue];
                
                NSMutableArray *properties = [@[@"album",
                                                @"artist",
                                                @"title",
                                                @"thumbnail",
                                                @"track",
                                                @"studio",
                                                @"showtitle",
                                                @"episode",
                                                @"season",
                                                @"fanart",
                                                @"channel",
                                                @"description",
                                                @"year",
                                                @"director",
                                                @"plot"] mutableCopy];
                if (AppDelegate.instance.serverVersion > 11) {
                    [properties addObject:@"art"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetItem"
                 withParameters:@{@"playerid": @(currentPlayerID),
                                  @"properties": properties}
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                    if (!self.isEnabled) {
                        return;
                    }
                    long storedItemID = 0;
                    NSString *storeLiveTVTitle = @"";
                    
                    if (error == nil && methodError == nil) {
                        if ([methodResult isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *nowPlayingInfo = methodResult[@"item"];
                            if (![nowPlayingInfo isKindOfClass:[NSDictionary class]]) {
                                return;
                            }
                            NowPlayingItem *item = [[NowPlayingItem alloc] init];
                            [item updateWith:nowPlayingInfo playerID:currentPlayerID];
                            [self updateNowPlayingItem:item];
                        }
                        else {
                            // not playing anything
//                            storedItemID = SELECTED_NONE;
//                            lastThumbnail = @"";
//                            [self setCoverSize:@"song"];
//                            UIImage *image = [UIImage imageNamed:@"coverbox_back"];
//                            [self processLoadedThumbImage:self thumb:thumbnailView image:image enableJewel:enableJewel];
                        }
                    }
                    else {
                        // not playing anything
//                        storedItemID = SELECTED_NONE;
                    }
                }];
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:@{@"playerid": @(currentPlayerID),
                                  @"properties": @[@"percentage",
                                                   @"time",
                                                   @"totaltime",
                                                   @"partymode",
                                                   @"position",
                                                   @"canrepeat",
                                                   @"canshuffle",
                                                   @"repeat",
                                                   @"shuffled",
                                                   @"canseek"]}
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                    // Do not process further, if the view is already off the view hierarchy.
                    if (!self.isEnabled) {
                        return;
                    }
                    if (error == nil && methodError == nil) {
                        if ([methodResult isKindOfClass:[NSDictionary class]]) {
                            if ([methodResult count]) {
                                PlayerInfo *info = [[PlayerInfo alloc] init];
                                [info updateWith:methodResult];
                            }
                        }
                    }
                }];
            }
            else {
                [self nothingIsPlaying];
            }
        }
        else {
            [self nothingIsPlaying];
        }
    }];

}

- (void)nothingIsPlaying {
    
}

@end
