import 'dart:html' as html;
import 'dart:js_util' as js;
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_webrtc/src/signaling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'camera.dart';

enum CameraStatus { uninitialized, available, unavailable }

class CameraState {
  const CameraState._({
    this.status = CameraStatus.uninitialized,
    this.error,
  });

  const CameraState.uninitialized() : this._();
  const CameraState.available() : this._(status: CameraStatus.available);
  const CameraState.unavailable(Exception error)
      : this._(status: CameraStatus.unavailable, error: error);

  final CameraStatus status;
  final Exception? error;
}

class CameraWebRTCController extends ValueNotifier<CameraState> {
  CameraWebRTCController() : super(const CameraState.uninitialized());

  late Signaling signaling = Signaling(
    onAddRemoteStream: _onAddRemoteStream,
    onRemoveStream: _onRemoveStream,
  );

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  Map<String, RTCVideoRenderer> _remoteRendered = {};
  String? roomId;

  List<RTCVideoView> get views => [
        RTCVideoView(
          _localRenderer,
          key: Key(_localRenderer.srcObject?.id ?? '_localRenderer'),
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
        for (final renderer in _remoteRendered.values)
          RTCVideoView(
            renderer,
            key: Key(renderer.srcObject?.id ?? 'renderer'),
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
      ];

  int get connections => views.length;

  List<Rect> get rects => [
        if (views.length == 1)
          Rect.fromLTRB(0, 0, 1, 1)
        else ...[
          Rect.fromLTRB(0, 0, 0.5, 1),
          Rect.fromLTRB(0.5, 0, 1, 1),
        ]
      ];

  /// Attempts to use the given [options] to initialize a camera.
  Future<void> initialize() async {
    await _localRenderer.initialize();
  }

  Future<void> _onAddRemoteStream(stream) async {
    _remoteRendered[stream.id] = RTCVideoRenderer();
    await _remoteRendered[stream.id]!.initialize();
    _remoteRendered[stream.id]!.srcObject = stream;

    notifyListeners();
  }

  Future<void> _onRemoveStream(stream) async {
    _remoteRendered[stream.id]!.dispose();
    _remoteRendered.remove(stream.id);
    notifyListeners();
  }

  bool get isHost => signaling.isHost;

  Size? size;

  @override
  Future<void> dispose() async {
    value = const CameraState.uninitialized();
    signaling.hangUp(_localRenderer);
    await _localRenderer.dispose();
    for (final renderer in _remoteRendered.values) {
      await renderer.dispose();
    }
    super.dispose();
  }

  Future<void> openMedia() async {
    await signaling.openUserMedia(_localRenderer);
  }

  Future<String> createRoom() async {
    if (roomId != null) return roomId!;
    roomId = await signaling.createRoom();
    notifyListeners();
    return roomId!;
  }

  Future<void> joinRoom(String newRoomId) async {
    if (roomId != null) return;
    roomId = newRoomId;
    await signaling.joinRoom(
      roomId!,
    );
    notifyListeners();
  }

  Future<void> hangUp() async {
    return signaling.hangUp(
      _localRenderer,
    );
  }

  Future<CameraImage> takePicture() async {
    final size = this.size!;
    final canvas = html.CanvasElement();
    canvas.width = size.width.toInt();
    canvas.height = size.height.toInt();
    final renderer = canvas.getContext('2d') as html.CanvasRenderingContext2D;

    await paintPicture(_localRenderer, rects.first.scale(size), renderer, true);
    try {
      final list = _remoteRendered.values.toList();
      for (final index in Iterable.generate(list.length)) {
        final remoteRenderer = list[index];
        await paintPicture(
            remoteRenderer, rects[index + 1].scale(size), renderer, false);
      }
    } catch (e) {}
    final blod = await canvas.toBlob();
    final url = html.Url.createObjectUrl(blod);
    return CameraImage(
      data: url,
      width: size.width.toInt(),
      height: size.height.toInt(),
    );
  }

  static Future<void> paintPicture(
      RTCVideoRenderer videoRenderer,
      Rect targetRect,
      html.CanvasRenderingContext2D renderer,
      bool fliped) async {
    final videoSize = videoRenderer.size;

    // Capture frame
    final videoTrack = videoRenderer.srcObject!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    final frame = await videoTrack.captureFrame();

    // Transform it to a blob
    final data = frame.asUint8List();
    final blob = html.Blob(<dynamic>[data], 'image/png');

    // Recalculate the size of the image to be contained in the widget rect
    final targetAspectRatio = targetRect.size.aspectRatio;
    final currentAspectRatio = videoSize.aspectRatio;
    Rect bitmapRect;
    if (currentAspectRatio < targetAspectRatio) {
      final newHeight = videoSize.width / targetAspectRatio;
      bitmapRect = Rect.fromLTWH(
        0,
        (videoSize.height - newHeight) / 2,
        videoSize.width,
        newHeight,
      );
    } else {
      final newWidth = videoSize.height * targetAspectRatio;
      bitmapRect = Rect.fromLTWH(
        (videoSize.width - newWidth) / 2,
        0,
        newWidth,
        videoSize.height,
      );
    }

    // Creates an ImageBitmap cropped for the targetSize
    final imageBitmapPromise = await js.promiseToFuture(
      js.callMethod(
        html.window,
        'createImageBitmap',
        [
          blob,
          bitmapRect.left.toInt(),
          bitmapRect.top.toInt(),
          bitmapRect.width.toInt(),
          bitmapRect.height.toInt(),
        ],
      ),
    );
    // Save canvas state to restore after upcoming modifications
    renderer.save();

    // Tranlsate canvas to be able to scale view in the center of the image
    renderer.translate(
      targetRect.left + targetRect.width / 2,
      targetRect.top + targetRect.height / 2,
    );
    renderer.scale(fliped ? -1 : 1, 1);

    // Draw image
    js.callMethod(renderer, 'drawImage', [
      imageBitmapPromise,
      -targetRect.width ~/ 2,
      -targetRect.height ~/ 2,
      targetRect.width.toInt(),
      targetRect.height.toInt(),
    ]);

    // Restore canvas settings to ignore scale and translate modifications
    renderer.restore();
    js.callMethod(imageBitmapPromise, 'close', []);
  }
}

extension on RTCVideoRenderer {
  Size get size => Size(
        videoWidth.toDouble(),
        videoHeight.toDouble(),
      );
}
