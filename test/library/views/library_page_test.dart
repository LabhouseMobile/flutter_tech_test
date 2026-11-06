import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/library/cubit/library_cubit.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:cabina/library/views/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryCubit extends MockCubit<LibraryState>
    implements LibraryCubit {}

void main() {
  const podcast = SubscribedPodcast(
    id: 1,
    title: 'Reply All',
    author: 'Gimlet',
  );

  late _MockLibraryCubit cubit;

  setUp(() {
    cubit = _MockLibraryCubit();
    when(() => cubit.state).thenReturn(const LibraryState());
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.unsubscribe(any())).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme(isDark: false).toThemeData(),
      home: BlocProvider<LibraryCubit>.value(
        value: cubit,
        child: const LibraryPage(),
      ),
    ),
  );

  group('LibraryPage', () {
    testWidgets('WHEN pumped '
        'THEN loads the library', (tester) async {
      await pumpPage(tester);

      verify(() => cubit.load()).called(1);
    });

    testWidgets('GIVEN loading '
        'THEN LoaderView shows', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const LibraryState(status: LibraryStatus.loading));

      await pumpPage(tester);

      expect(find.byType(LoaderView), findsOneWidget);
    });

    testWidgets('GIVEN an error '
        'WHEN Retry is tapped '
        'THEN loads again', (tester) async {
      when(() => cubit.state).thenReturn(
        const LibraryState(
          status: LibraryStatus.error,
          errorMessage: 'offline',
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.text('Retry'));

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      verify(() => cubit.load()).called(2);
    });

    testWidgets('GIVEN no podcasts '
        'THEN EmptyView shows', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const LibraryState(status: LibraryStatus.ready));

      await pumpPage(tester);

      expect(find.byType(EmptyView), findsOneWidget);
    });

    testWidgets('GIVEN podcasts '
        'THEN their title and author show', (tester) async {
      when(() => cubit.state).thenReturn(
        const LibraryState(status: LibraryStatus.ready, podcasts: [podcast]),
      );

      await pumpPage(tester);

      expect(find.text('Reply All'), findsOneWidget);
      expect(find.text('Gimlet'), findsOneWidget);
    });

    testWidgets('GIVEN podcasts '
        'WHEN Unsubscribe is tapped '
        'THEN unsubscribes that podcast', (tester) async {
      when(() => cubit.state).thenReturn(
        const LibraryState(status: LibraryStatus.ready, podcasts: [podcast]),
      );

      await pumpPage(tester);
      await tester.tap(find.byTooltip('Unsubscribe'));

      verify(() => cubit.unsubscribe(podcast.id)).called(1);
    });

    testWidgets('GIVEN ready '
        'WHEN an errorMessage is emitted '
        'THEN a SnackBar shows it', (tester) async {
      const ready = LibraryState(
        status: LibraryStatus.ready,
        podcasts: [podcast],
      );
      whenListen(
        cubit,
        Stream.value(
          const LibraryState(
            status: LibraryStatus.ready,
            podcasts: [podcast],
            errorMessage: 'Could not save your changes',
          ),
        ),
        initialState: ready,
      );

      await pumpPage(tester);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Could not save your changes'),
        ),
        findsOneWidget,
      );
    });
  });
}
