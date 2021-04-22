// ignore_for_file: prefer_const_constructors
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:io_photobooth/photobooth/photobooth.dart';
import 'package:io_photobooth/share/share.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class FakePhotoboothEvent extends Fake implements PhotoboothEvent {}

class FakePhotoboothState extends Fake implements PhotoboothState {}

void main() {
  const width = 1;
  const height = 1;
  final data = Uint8List.fromList([]);
  final image = CameraImage(width: width, height: height, data: data);

  late PhotoboothBloc photoboothBloc;

  setUpAll(() {
    registerFallbackValue<PhotoboothEvent>(FakePhotoboothEvent());
    registerFallbackValue<PhotoboothState>(FakePhotoboothState());
  });

  setUp(() {
    photoboothBloc = MockPhotoboothBloc();
    when(() => photoboothBloc.state).thenReturn(PhotoboothState(image: image));
  });

  group('ShareBottomSheet', () {
    const width = 1;
    const height = 1;
    final data = Uint8List.fromList([]);
    final image = CameraImage(width: width, height: height, data: data);

    testWidgets('displays heading', (tester) async {
      await tester.pumpApp(
        Scaffold(body: ShareBottomSheet(image: image)),
        photoboothBloc: photoboothBloc,
      );
      expect(find.byKey(Key('shareBottomSheet_heading')), findsOneWidget);
    });

    testWidgets('displays subheading', (tester) async {
      await tester.pumpApp(
        Scaffold(body: ShareBottomSheet(image: image)),
        photoboothBloc: photoboothBloc,
      );
      expect(find.byKey(Key('shareBottomSheet_subheading')), findsOneWidget);
    });

    testWidgets('displays a TwitterButton', (tester) async {
      await tester.pumpApp(
        Scaffold(body: ShareBottomSheet(image: image)),
        photoboothBloc: photoboothBloc,
      );
      expect(find.byType(TwitterButton), findsOneWidget);
    });

    testWidgets('tapping on TwitterButton does nothing', (tester) async {
      await tester.pumpApp(TwitterButton());
      await tester.tap(find.byType(TwitterButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays a FacebookButton', (tester) async {
      await tester.pumpApp(
        Scaffold(body: ShareBottomSheet(image: image)),
        photoboothBloc: photoboothBloc,
      );
      expect(find.byType(FacebookButton), findsOneWidget);
    });

    testWidgets('tapping on FacebookButton does nothing', (tester) async {
      await tester.pumpApp(FacebookButton());
      await tester.tap(find.byType(FacebookButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('taps on close will dismiss the popup', (tester) async {
      await tester.pumpApp(
        Scaffold(body: ShareBottomSheet(image: image)),
        photoboothBloc: photoboothBloc,
      );
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.byType(ShareBottomSheet), findsNothing);
    });
  });
}