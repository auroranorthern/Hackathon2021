import 'dart:async';
import 'dart:html';

import 'package:camera_webrtc/camera_webrtc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:io_photobooth/photobooth/photobooth.dart';
import 'package:io_photobooth/photobooth/widgets/photobooth_guest.dart';
import 'package:io_photobooth/stickers/stickers.dart';
import 'package:photobooth_ui/photobooth_ui.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

// const _videoConstraints = VideoConstraints(
//   facingMode: FacingMode(
//     type: CameraType.user,
//     constrain: Constrain.ideal,
//   ),
//   width: VideoSize(ideal: 1920, maximum: 1920),
//   height: VideoSize(ideal: 1080, maximum: 1080),
// );

class PhotoboothPage extends StatelessWidget {
  const PhotoboothPage({Key? key, this.roomId}) : super(key: key);

  final String? roomId;

  static Route route([String? roomId]) {
    return AppPageRoute(
      builder: (_) => PhotoboothPage(roomId: roomId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhotoboothBloc(),
      child: Navigator(
        onGenerateRoute: (_) => AppPageRoute(
          builder: (_) => PhotoboothView(roomId: roomId),
        ),
      ),
    );
  }
}

class PhotoboothView extends StatefulWidget {
  const PhotoboothView({Key? key, this.roomId}) : super(key: key);

  final String? roomId;

  @override
  _PhotoboothViewState createState() => _PhotoboothViewState();
}

class _PhotoboothViewState extends State<PhotoboothView> {
//  final _controller = CameraController(
//    options: const CameraOptions(
//      audio: AudioConstraints(enabled: false),
//      video: _videoConstraints,
//    ),
//  );

  final _controller = CameraWebRTCController();

  Future<void> _play() async {
    await _controller.openMedia();
  }

  Future<void> _stop() async {
    await _controller.hangUp();

    /// return _controller.stop();
  }

  @override
  void initState() {
    super.initState();
    _initializeCameraController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCameraController() async {
    await _controller.initialize();
    await _play();
    if (widget.roomId != null) {
      await _controller.joinRoom(widget.roomId!);
    } else {
      final room = await _controller.createRoom();
      window.history.pushState(
        null,
        window.name ?? '',
        window.location.origin + '/#/r/$room',
      );
    }
  }

  TextEditingController _textEditingController = TextEditingController();

  void _onSnapPressed({required double aspectRatio}) async {
    final picture = await _controller.takePicture();
    context
        .read<PhotoboothBloc>()
        .add(PhotoCaptured(aspectRatio: aspectRatio, image: picture));
    final stickersPage = StickersPage.route();
    await _stop();
    unawaited(Navigator.of(context).pushReplacement(stickersPage));
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final aspectRatio = orientation == Orientation.portrait
        ? PhotoboothAspectRatio.portrait
        : PhotoboothAspectRatio.landscape;
    return Scaffold(
      body: _PhotoboothBackground(
        aspectRatio: aspectRatio,
        child: CameraWebRTC(
          controller: _controller,
          placeholder: (_) => const SizedBox(),
          guestPreview: (context, preview) => PhotoboothGuest(
            preview: preview,
          ),
          preview: (context, preview) => PhotoboothPreview(
            preview: preview,
            onSnapPressed: () => _onSnapPressed(aspectRatio: aspectRatio),
            onAddFriendPressed: () {
              final room = _controller.roomId;
              shareRoomDialog(context, room!);
            },
          ),
          error: (context, error) => PhotoboothError(error: error),
        ),
      ),
    );
  }
}

Future<void> shareRoomDialog(BuildContext context, String room) {
  final url = '${window.location.origin}/#/r/$room';
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Invite people to your PhotoBooth room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText('Room: $room'),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                primary: Colors.grey[100],
                onPrimary: Colors.grey[900],
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.of(context).pop();
              },
              child: Row(
                children: [
                  Text(url),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PhotoboothBackground extends StatelessWidget {
  const _PhotoboothBackground({
    Key? key,
    required this.aspectRatio,
    required this.child,
  }) : super(key: key);

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const PhotoboothBackground(),
        Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              color: PhotoboothColors.black,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
