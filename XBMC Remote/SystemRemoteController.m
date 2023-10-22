//
//  SystemRemoteController.m
//  Kodi Remote
//
//  Created by Alin Radut on 2023-10-14.
//  Copyright © 2023 Team Kodi. All rights reserved.
//

#import "SystemRemoteController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Utilities.h"
#import "AppDelegate.h"
#import "NowPlayingManager.h"

#define TAG_BUTTON_SEEK_BACKWARD 2
#define TAG_BUTTON_PLAY_PAUSE 3
#define TAG_BUTTON_SEEK_FORWARD 4
#define TAG_BUTTON_PREVIOUS 5
#define TAG_BUTTON_STOP 6
#define TAG_BUTTON_NEXT 8

@class NowPlayingItem;

@interface SystemRemoteController ()

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation SystemRemoteController

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                             pathForResource:@"silence"
                                             ofType:@"mp3"]];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        _player.numberOfLoops = -1;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNowPlayingUpdatedNotification:) name:@"NowPlayingUpdated" object:nil];
    }
    return self;
}

- (void)onNowPlayingUpdatedNotification:(NSNotification *)notification {
    if (notification.object != nil && [notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *nowPlayingInfo = notification.object;

        NSNumber *playbackRate = nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate];
        if (playbackRate) {
            if (playbackRate.floatValue > 0.0) {
                [_player play];
            }
            else {
                [_player pause];
            }
        }
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
    }
    else {
        [_player stop];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    }
}

-(void)setup {
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    [center.playCommand addTarget:self action:@selector(onPlayCommand:)];
    [center.pauseCommand addTarget:self action:@selector(onPauseCommand:)];
    [center.togglePlayPauseCommand addTarget:self action:@selector(onTogglePlayPauseCommand:)];
    
    [center.stopCommand addTarget:self action:@selector(onStopCommand:)];

    [center.seekForwardCommand addTarget:self action:@selector(onSeekForwardCommand:)];
    [center.seekBackwardCommand addTarget:self action:@selector(onSeekBackwardCommand:)];

    [center.nextTrackCommand addTarget:self action:@selector(onNextTrackCommand:)];
    [center.previousTrackCommand addTarget:self action:@selector(onPreviousTrackCommand:)];
    
    [center.changePlaybackPositionCommand addTarget:self action:@selector(onChangePlaybackPositionCommand:)];
}

- (MPRemoteCommandHandlerStatus) onPlayCommand: (MPRemoteCommandEvent*) event {
    [self handleAction:TAG_BUTTON_PLAY_PAUSE];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onPauseCommand: (MPRemoteCommandEvent*) event {
    [self handleAction:TAG_BUTTON_PLAY_PAUSE];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onTogglePlayPauseCommand: (MPRemoteCommandEvent*) event {
    [self handleAction:TAG_BUTTON_PLAY_PAUSE];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onStopCommand: (MPRemoteCommandEvent*) event {
    [self handleAction:TAG_BUTTON_STOP];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onSeekForwardCommand: (MPRemoteCommandEvent*) event {
    [self handleAction:TAG_BUTTON_SEEK_FORWARD];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onSeekBackwardCommand: (MPRemoteCommandEvent*) event {
    [self handleAction:TAG_BUTTON_SEEK_BACKWARD];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onNextTrackCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onPreviousTrackCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onChangePlaybackPositionCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (void)handleAction:(int)actionX {
    NSString *action;
    NSDictionary *params;
    switch (actionX) {
        case TAG_BUTTON_SEEK_BACKWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params];
            break;
            
        case TAG_BUTTON_PLAY_PAUSE:
            action = @"Player.PlayPause";
            params = nil;
            [self playbackAction:action params:nil];
            break;
            
        case TAG_BUTTON_SEEK_FORWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallforward"];
            [self playbackAction:action params:params];
            break;
            
        case TAG_BUTTON_PREVIOUS:
            if (AppDelegate.instance.serverVersion > 11) {
                action = @"Player.GoTo";
                params = @{@"to": @"previous"};
                [self playbackAction:action params:params];
            }
            else {
                action = @"Player.GoPrevious";
                params = nil;
                [self playbackAction:action params:nil];
            }
            break;
            
        case TAG_BUTTON_STOP:
            action = @"Player.Stop";
            params = nil;
            [self playbackAction:action params:nil];
            break;
            
        case TAG_BUTTON_NEXT:
            if (AppDelegate.instance.serverVersion > 11) {
                action = @"Player.GoTo";
                params = @{@"to": @"next"};
                [self playbackAction:action params:params];
            }
            else {
                action = @"Player.GoNext";
                params = nil;
                [self playbackAction:action params:nil];
            }
            break;

        default:
            break;
    }
}

- (void)playbackAction:(NSString*)action params:(NSDictionary*)parameters {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                NSMutableDictionary *commonParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
                NSNumber *response = methodResult[0][@"playerid"] != [NSNull null] ? methodResult[0][@"playerid"] : nil;
                if (response != nil) {
                    commonParams[@"playerid"] = @([response intValue]);
                }
                [[Utilities getJsonRPC] callMethod:action withParameters:commonParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                }];
            }
        }
    }];
}


@end
