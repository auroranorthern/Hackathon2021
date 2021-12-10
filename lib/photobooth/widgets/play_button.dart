import 'package:flutter/material.dart';
import 'package:io_photobooth/photobooth/photobooth.dart';
import 'package:photobooth_ui/photobooth_ui.dart';
import 'package:provider/src/provider.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Material(
        clipBehavior: Clip.hardEdge,
        shape: const CircleBorder(),
        color: PhotoboothColors.white,
        child: InkWell(
          onTap: () {
            context.read<PhotoboothBloc>().add(const PlayTapped());
          },
          child: Icon(
            Icons.play_arrow,
            color: PhotoboothColors.blue,
          ),
        ),
      ),
    );
  }
}
