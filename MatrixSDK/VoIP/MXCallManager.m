/*
 Copyright 2015 OpenMarket Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXCallManager.h"

#import "MXSession.h"

#pragma mark - Constants definitions
NSString *const kMXCallManagerDidReceiveCallInvite = @"kMXCallManagerDidReceiveCallInvite";


@interface MXCallManager ()
{
    /**
     Calls being handled.
     */
    NSMutableArray *calls;

    id callInviteListener;
}

@end


@implementation MXCallManager

- (instancetype)initWithMatrixSession:(MXSession *)mxSession
{
    self = [super init];
    if (self)
    {
        _mxSession = mxSession;
        calls = [NSMutableArray array];

        // Listen to incoming calls
        callInviteListener = [mxSession listenToEventsOfTypes:@[kMXEventTypeStringCallInvite] onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {

            if (MXEventDirectionForwards == direction)
            {
                [self handleCallInvite:event];
            }

        }];
    }
    return self;
}

- (void)close
{
    // @TODO: Hang up current call

    [_mxSession removeListener:callInviteListener];
    callInviteListener = nil;
}

- (MXCall *)placeCallInRoom:(NSString *)roomId withVideo:(BOOL)video
{
    MXCall *call;

    MXRoom *room = [_mxSession roomWithRoomId:roomId];

    if (room && 2 == room.state.members.count)
    {
        call = [[MXCall alloc] initWithRoomId:roomId andCallManager:self];
        [calls addObject:call];
    }
    else
    {
        NSLog(@"[MXCallManager] placeCallInRoom: Cannot place call in %@. Members count: %lu", roomId, room.state.members.count);
    }

    return call;
}


#pragma mark - Private methods
- (void)handleCallInvite:(MXEvent*)event
{
    MXCall *call = [[MXCall alloc] initWithCallInviteEvent:event andCallManager:self];
    [calls addObject:call];

    // Broadcast the information
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXCallManagerDidReceiveCallInvite object:call userInfo:nil];
}

@end