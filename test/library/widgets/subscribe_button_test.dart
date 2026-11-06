import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/storage/local_storage.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/library/cubit/library_cubit.dart';
import 'package:cabina/library/data/library_repository.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:cabina/library/views/library_page.dart';
import 'package:cabina/library/widgets/subscribe_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLibraryCubit extends MockCubit<LibraryState>
    implements LibraryCubit {}

void main() {
  const podcast = SubscribedPodcast(
    id: 1,
    title: 'Reply All',
    author: 'Gimlet',
  );

  Widget app(LibraryCubit cubit, Widget child) => MaterialApp(
    theme: AppTheme(isDark: false).toThemeData(),
    home: BlocProvider<LibraryCubit>.value(value: cubit, child: child),
  );

  group('SubscribeButton', () {
    late _MockLibraryCubit cubit;

    setUp(() {
      cubit = _MockLibraryCubit();
      when(() => cubit.subscribe(podcast)).thenAnswer((_) async {});
      when(() => cubit.unsubscribe(podcast.id)).thenAnswer((_) async {});
    });

    Future<void> pumpButton(WidgetTester tester, LibraryState state) {
      when(() => cubit.state).thenReturn(state);
      return tester.pumpWidget(
        app(cubit, const Scaffold(body: SubscribeButton(podcast: podcast))),
      );
    }

    testWidgets('GIVEN not subscribed '
        'WHEN tapped '
        'THEN subscribes the podcast', (tester) async {
      await pumpButton(
        tester,
        const LibraryState(status: LibraryStatus.ready),
      );
      await tester.tap(find.text('Subscribe'));

      verify(() => cubit.subscribe(podcast)).called(1);
    });

    testWidgets('GIVEN subscribed '
        'WHEN tapped '
        'THEN unsubscribes it', (tester) async {
      await pumpButton(
        tester,
        const LibraryState(status: LibraryStatus.ready, podcasts: [podcast]),
      );
      await tester.tap(find.text('Subscribed'));

      verify(() => cubit.unsubscribe(podcast.id)).called(1);
    });

    testWidgets('GIVEN the library is still loading '
        'THEN the button is disabled', (tester) async {
      await pumpButton(
        tester,
        const LibraryState(status: LibraryStatus.loading),
      );

      final button = tester.widget<ButtonStyleButton>(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('GIVEN LibraryPage and SubscribeButton on one LibraryCubit '
      'WHEN Subscribe is tapped '
      'THEN the library lists the podcast', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStorage = LocalStorage(
      prefs: await SharedPreferences.getInstance(),
    );
    final cubit = LibraryCubit(
      libraryRepository: LibraryRepository(localStorage: localStorage),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      app(
        cubit,
        const Column(
          children: [
            SubscribeButton(podcast: podcast),
            Expanded(child: LibraryPage()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reply All'), findsNothing);

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(find.text('Reply All'), findsOneWidget);
    expect(find.text('Subscribed'), findsOneWidget);
  });
}
