import 'package:camera_webrtc/src/controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signaling.dart';

typedef PlaceholderBuilder = Widget Function(BuildContext);
typedef PreviewBuilder = Widget Function(BuildContext, Widget);
typedef ErrorBuilder = Widget Function(BuildContext, Exception);

class CameraWebRTC extends StatefulWidget {
  CameraWebRTC({
    Key? key,
    required this.placeholder,
    required this.preview,
    required this.guestPreview,
    required this.error,
    required this.controller,
  }) : super(key: key);

  final CameraWebRTCController controller;
  final PlaceholderBuilder placeholder;
  final PreviewBuilder preview;
  final PreviewBuilder guestPreview;
  final ErrorBuilder error;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CameraWebRTC> {
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    widget.controller.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(update);
    super.dispose();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final itemCount = widget.controller.views.length;
      widget.controller.size = size;

      final child = Stack(
        children: [
          for (final index in Iterable.generate(itemCount))
            Positioned.fromRect(
              rect: widget.controller.rects[index].scale(size),
              child: widget.controller.views[index],
            ),
          if (widget.controller.connections > 1)
            Positioned(
              left: 20,
              bottom: 60,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.controller.isHost
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).errorColor,
                ),
                padding: EdgeInsets.all(8),
                child: Text(
                  'Friends: ${widget.controller.connections}',
                  style: Theme.of(context).primaryTextTheme.caption,
                ),
              ),
            ),
        ],
      );

      if (!widget.controller.isHost) return widget.guestPreview(context, child);
      return widget.preview(context, child);
    });
  }
}

extension ScaleRect on Rect {
  Rect scale(Size size) {
    return Rect.fromLTWH(left * size.width, top * size.height,
        width * size.width, height * size.height);
  }
}
