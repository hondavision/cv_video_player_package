// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_avfoundation/src/messages.g.dart';
import 'package:video_player_avfoundation/video_player_avfoundation.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_api.g.dart';

class _ApiLogger implements TestHostVideoPlayerApi {
  final List<String> log = <String>[];
  TextureMessage? textureMessage;
  CreateMessage? createMessage;
  PositionMessage? positionMessage;
  LoopingMessage? loopingMessage;
  VolumeMessage? volumeMessage;
  PlaybackSpeedMessage? playbackSpeedMessage;
  MixWithOthersMessage? mixWithOthersMessage;
  SetPictureInPictureOverlaySettingsMessage?
      setPictureInPictureOverlaySettingMessage;
  AutomaticallyStartsPictureInPictureMessage?
      automaticallyStartsPictureInPictureMessage;
  StartPictureInPictureMessage? startPictureInPictureMessage;
  StopPictureInPictureMessage? stopPictureInPictureMessage;

  @override
  TextureMessage create(CreateMessage arg) {
    log.add('create');
    createMessage = arg;
    return TextureMessage(textureId: 3);
  }

  @override
  void dispose(TextureMessage arg) {
    log.add('dispose');
    textureMessage = arg;
  }

  @override
  void initialize() {
    log.add('init');
  }

  @override
  void pause(TextureMessage arg) {
    log.add('pause');
    textureMessage = arg;
  }

  @override
  void play(TextureMessage arg) {
    log.add('play');
    textureMessage = arg;
  }

  @override
  void setMixWithOthers(MixWithOthersMessage arg) {
    log.add('setMixWithOthers');
    mixWithOthersMessage = arg;
  }

  @override
  PositionMessage position(TextureMessage arg) {
    log.add('position');
    textureMessage = arg;
    return PositionMessage(textureId: arg.textureId, position: 234);
  }

  @override
  Future<void> seekTo(PositionMessage arg) async {
    log.add('seekTo');
    positionMessage = arg;
  }

  @override
  void setLooping(LoopingMessage arg) {
    log.add('setLooping');
    loopingMessage = arg;
  }

  @override
  void setVolume(VolumeMessage arg) {
    log.add('setVolume');
    volumeMessage = arg;
  }

  @override
  void setPlaybackSpeed(PlaybackSpeedMessage arg) {
    log.add('setPlaybackSpeed');
    playbackSpeedMessage = arg;
  }

  @override
  bool isPictureInPictureSupported() {
    log.add('isPictureInPictureSupported');
    return true;
  }

  @override
  void setAutomaticallyStartsPictureInPicture(
      AutomaticallyStartsPictureInPictureMessage msg) {
    log.add('setAutomaticallyStartsPictureInPicture');
    automaticallyStartsPictureInPictureMessage = msg;
  }

  @override
  void setPictureInPictureOverlaySettings(
      SetPictureInPictureOverlaySettingsMessage msg) {
    log.add('setPictureInPictureOverlaySettings');
    setPictureInPictureOverlaySettingMessage = msg;
  }

  @override
  void startPictureInPicture(StartPictureInPictureMessage msg) {
    log.add('startPictureInPicture');
    startPictureInPictureMessage = msg;
  }

  @override
  void stopPictureInPicture(StopPictureInPictureMessage msg) {
    log.add('stopPictureInPicture');
    stopPictureInPictureMessage = msg;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration', () async {
    AVFoundationVideoPlayer.registerWith();
    expect(VideoPlayerPlatform.instance, isA<AVFoundationVideoPlayer>());
  });

  group('$AVFoundationVideoPlayer', () {
    final AVFoundationVideoPlayer player = AVFoundationVideoPlayer();
    late _ApiLogger log;

    setUp(() {
      log = _ApiLogger();
      TestHostVideoPlayerApi.setup(log);
    });

    test('init', () async {
      await player.init();
      expect(
        log.log.last,
        'init',
      );
    });

    test('dispose', () async {
      await player.dispose(1);
      expect(log.log.last, 'dispose');
      expect(log.textureMessage?.textureId, 1);
    });

    test('create with asset', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.asset,
        asset: 'someAsset',
        package: 'somePackage',
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.asset, 'someAsset');
      expect(log.createMessage?.packageName, 'somePackage');
      expect(textureId, 3);
    });

    test('create with incorrect asset throws exception', () async {
      try {
        await player.create(DataSource(
          sourceType: DataSourceType.asset,
          asset: '/path/to/incorrect_asset',
        ));
        fail('should throw PlatformException');
      } catch (e) {
        expect(e, isException);
      }
    });

    test('create with network', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.network,
        uri: 'someUri',
        formatHint: VideoFormat.dash,
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.asset, null);
      expect(log.createMessage?.uri, 'someUri');
      expect(log.createMessage?.packageName, null);
      expect(log.createMessage?.formatHint, 'dash');
      expect(log.createMessage?.httpHeaders, <String, String>{});
      expect(textureId, 3);
    });

    test('create with network (some headers)', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.network,
        uri: 'someUri',
        httpHeaders: <String, String>{'Authorization': 'Bearer token'},
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.asset, null);
      expect(log.createMessage?.uri, 'someUri');
      expect(log.createMessage?.packageName, null);
      expect(log.createMessage?.formatHint, null);
      expect(log.createMessage?.httpHeaders,
          <String, String>{'Authorization': 'Bearer token'});
      expect(textureId, 3);
    });

    test('create with file', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.file,
        uri: 'someUri',
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.uri, 'someUri');
      expect(textureId, 3);
    });

    test('setLooping', () async {
      await player.setLooping(1, true);
      expect(log.log.last, 'setLooping');
      expect(log.loopingMessage?.textureId, 1);
      expect(log.loopingMessage?.isLooping, true);
    });

    test('play', () async {
      await player.play(1);
      expect(log.log.last, 'play');
      expect(log.textureMessage?.textureId, 1);
    });

    test('pause', () async {
      await player.pause(1);
      expect(log.log.last, 'pause');
      expect(log.textureMessage?.textureId, 1);
    });

    test('setMixWithOthers', () async {
      await player.setMixWithOthers(true);
      expect(log.log.last, 'setMixWithOthers');
      expect(log.mixWithOthersMessage?.mixWithOthers, true);

      await player.setMixWithOthers(false);
      expect(log.log.last, 'setMixWithOthers');
      expect(log.mixWithOthersMessage?.mixWithOthers, false);
    });

    test('setVolume', () async {
      await player.setVolume(1, 0.7);
      expect(log.log.last, 'setVolume');
      expect(log.volumeMessage?.textureId, 1);
      expect(log.volumeMessage?.volume, 0.7);
    });

    test('setPlaybackSpeed', () async {
      await player.setPlaybackSpeed(1, 1.5);
      expect(log.log.last, 'setPlaybackSpeed');
      expect(log.playbackSpeedMessage?.textureId, 1);
      expect(log.playbackSpeedMessage?.speed, 1.5);
    });

    test('seekTo', () async {
      await player.seekTo(1, const Duration(milliseconds: 12345));
      expect(log.log.last, 'seekTo');
      expect(log.positionMessage?.textureId, 1);
      expect(log.positionMessage?.position, 12345);
    });

    test('getPosition', () async {
      final Duration position = await player.getPosition(1);
      expect(log.log.last, 'position');
      expect(log.textureMessage?.textureId, 1);
      expect(position, const Duration(milliseconds: 234));
    });

    test('isPictureInPictureSupported', () async {
      final bool isSupported = await player.isPictureInPictureSupported();
      expect(log.log.last, 'isPictureInPictureSupported');
      expect(isSupported, true);
    });

    test('setAutomaticallyStartsPictureInPicture true', () async {
      await player.setAutomaticallyStartsPictureInPicture(
          textureId: 1,
          enableStartPictureInPictureAutomaticallyFromInline: true);
      expect(log.log.last, 'setAutomaticallyStartsPictureInPicture');
      expect(log.automaticallyStartsPictureInPictureMessage?.textureId, 1);
      expect(
          log.automaticallyStartsPictureInPictureMessage
              ?.enableStartPictureInPictureAutomaticallyFromInline,
          true);
    });

    test('setAutomaticallyStartsPictureInPicture false', () async {
      await player.setAutomaticallyStartsPictureInPicture(
          textureId: 1,
          enableStartPictureInPictureAutomaticallyFromInline: false);
      expect(log.log.last, 'setAutomaticallyStartsPictureInPicture');
      expect(log.automaticallyStartsPictureInPictureMessage?.textureId, 1);
      expect(
          log.automaticallyStartsPictureInPictureMessage
              ?.enableStartPictureInPictureAutomaticallyFromInline,
          false);
    });

    test('setPictureInPictureOverlaySettings', () async {
      await player.setPictureInPictureOverlaySettings(
        textureId: 1,
        settings: const PictureInPictureOverlaySettings(
          rect: Rect.fromLTWH(0, 1, 2, 3),
        ),
      );
      expect(log.log.last, 'setPictureInPictureOverlaySettings');
      expect(log.setPictureInPictureOverlaySettingMessage?.textureId, 1);
      expect(log.setPictureInPictureOverlaySettingMessage?.settings?.left, 0);
      expect(log.setPictureInPictureOverlaySettingMessage?.settings?.top, 1);
      expect(log.setPictureInPictureOverlaySettingMessage?.settings?.width, 2);
      expect(log.setPictureInPictureOverlaySettingMessage?.settings?.height, 3);
    });

    test('startPictureInPicture', () async {
      await player.startPictureInPicture(1);
      expect(log.log.last, 'startPictureInPicture');
      expect(log.startPictureInPictureMessage?.textureId, 1);
    });

    test('stopPictureInPicture', () async {
      await player.stopPictureInPicture(1);
      expect(log.log.last, 'stopPictureInPicture');
      expect(log.stopPictureInPictureMessage?.textureId, 1);
    });

    test('videoEventsFor', () async {
      const String mockChannel = 'flutter.io/videoPlayer/videoEvents123';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        mockChannel,
        (ByteData? message) async {
          final MethodCall methodCall =
              const StandardMethodCodec().decodeMethodCall(message);
          if (methodCall.method == 'listen') {
            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 98765,
                      'width': 1920,
                      'height': 1080,
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'completed',
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingUpdate',
                      'values': <List<dynamic>>[
                        <int>[0, 1234],
                        <int>[1235, 4000],
                      ],
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingStart',
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingEnd',
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'isPlayingStateUpdate',
                      'isPlaying': true,
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'isPlayingStateUpdate',
                      'isPlaying': false,
                    }),
                    (ByteData? data) {});

            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else if (methodCall.method == 'cancel') {
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      expect(
          player.videoEventsFor(123),
          emitsInOrder(<dynamic>[
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
            ),
            VideoEvent(eventType: VideoEventType.completed),
            VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                buffered: <DurationRange>[
                  DurationRange(
                    Duration.zero,
                    const Duration(milliseconds: 1234),
                  ),
                  DurationRange(
                    const Duration(milliseconds: 1235),
                    const Duration(milliseconds: 4000),
                  ),
                ]),
            VideoEvent(eventType: VideoEventType.bufferingStart),
            VideoEvent(eventType: VideoEventType.bufferingEnd),
            VideoEvent(
              eventType: VideoEventType.isPlayingStateUpdate,
              isPlaying: true,
            ),
            VideoEvent(
              eventType: VideoEventType.isPlayingStateUpdate,
              isPlaying: false,
            ),
          ]));
    });
  });
}
