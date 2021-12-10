import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:io_photobooth/l10n/l10n.dart';
import 'package:io_photobooth/share/share.dart';
import 'package:photobooth_ui/photobooth_ui.dart';

class GetShareURLButton extends StatelessWidget {
  const GetShareURLButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final state = context.read<ShareBloc>().state;
        if (state.uploadStatus.isSuccess) {
          Navigator.of(context).pop();
          return;
        }
        context.read<ShareBloc>().add(const GetShareURLTapped());
      },
      // child: Text(l10n.shareDialogFacebookButtonText),
      child: Text('Get share URL'),
    );
  }
}
