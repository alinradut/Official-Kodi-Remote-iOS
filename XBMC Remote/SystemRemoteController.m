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

@implementation SystemRemoteController

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
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onPauseCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onTogglePlayPauseCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onStopCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onSeekForwardCommand: (MPRemoteCommandEvent*) event {
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) onSeekBackwardCommand: (MPRemoteCommandEvent*) event {
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

@end
