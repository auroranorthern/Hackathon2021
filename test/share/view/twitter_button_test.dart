// ignore_for_file: prefer_const_constructors
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:io_photobooth/photobooth/photobooth.dart';
import 'package:io_photobooth/share/share.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockPhotoAsset extends Mock implements PhotoAsset {}

void main() {
  const width = 1;
  const height = 1;
  final data = Uint8List.fromList([]);
  final image = CameraImage(width: width, height: height, data: data);
  final characters = [MockPhotoAsset()];
  final stickers = [MockPhotoAsset()];
  final photoboothState = PhotoboothState(
    image: image,
    characters: characters,
    stickers: stickers,
  );

  late PhotoboothBloc photoboothBloc;
  late ShareBloc shareBloc;

  setUpAll(() {
    registerFallbackValue<PhotoboothEvent>(FakePhotoboothEvent());
    registerFallbackValue<PhotoboothState>(FakePhotoboothState());

    registerFallbackValue<ShareEvent>(FakeShareEvent());
    registerFallbackValue<ShareState>(FakeShareState());
  });

  setUp(() {
    photoboothBloc = MockPhotoboothBloc();
    when(() => photoboothBloc.state).thenReturn(
      PhotoboothState(
        image: image,
        characters: characters,
        stickers: stickers,
      ),
    );

    shareBloc = MockShareBloc();
    when(() => shareBloc.state).thenReturn(ShareState.initial());
  });

  group('TwitterButton', () {
    testWidgets('renders', (tester) async {
      await tester.pumpApp(
        TwitterButton(),
        photoboothBloc: photoboothBloc,
        shareBloc: shareBloc,
      );

      expect(find.byType(TwitterButton), findsOneWidget);
    });

    testWidgets('pops when tapped', (tester) async {
      await tester.pumpApp(
        TwitterButton(),
        photoboothBloc: photoboothBloc,
        shareBloc: shareBloc,
      );

      await tester.tap(find.byType(TwitterButton));
      await tester.pumpAndSettle();

      expect(find.byType(TwitterButton), findsNothing);
    });

    testWidgets(
        'adds ShareOnTwitter event with image and assets '
        'when tapped', (tester) async {
      await tester.pumpApp(
        TwitterButton(),
        photoboothBloc: photoboothBloc,
        shareBloc: shareBloc,
      );

      await tester.tap(find.byType(TwitterButton));
      await tester.pumpAndSettle();

      verify(
        () => shareBloc.add(
          ShareOnTwitter(
            image: image,
            assets: photoboothState.assets,
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'does not add ShareOnTwitter event '
        'when tapped but PhotoboothState image is null', (tester) async {
      when(() => photoboothBloc.state).thenReturn(
        PhotoboothState(
          image: null,
          characters: characters,
          stickers: stickers,
        ),
      );
      await tester.pumpApp(
        TwitterButton(),
        photoboothBloc: photoboothBloc,
        shareBloc: shareBloc,
      );

      await tester.tap(find.byType(TwitterButton));
      await tester.pumpAndSettle();

      verifyNever(() => shareBloc.add(any()));
    });
  });
}