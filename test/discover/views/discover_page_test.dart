import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/discover/cubit/discover_cubit.dart';
import 'package:cabina/discover/views/discover_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoverCubit extends MockCubit<DiscoverState>
    implements DiscoverCubit {}

void main() {
  late _MockDiscoverCubit cubit;

  setUp(() {
    cubit = _MockDiscoverCubit();
    when(() => cubit.state).thenReturn(const DiscoverState());
    when(() => cubit.loadFeatured()).thenAnswer((_) async {});
    when(() => cubit.restoreFavourites()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    // TODO(marco): Find a way of having utils or a Robot that pumps for us.
    MaterialApp(
      theme: AppTheme(isDark: false).toThemeData(),
      home: BlocProvider<DiscoverCubit>.value(
        value: cubit,
        child: const DiscoverPage(),
      ),
    ),
  );

  group('DiscoverPage', () {
    testWidgets('WHEN pumped '
        'THEN loads featured and restores favourites', (tester) async {
      await pumpPage(tester);

      verify(() => cubit.loadFeatured()).called(1);
      verify(() => cubit.restoreFavourites()).called(1);
    });

    testWidgets('GIVEN ready '
        'WHEN an errorMessage is emitted '
        'THEN a SnackBar shows it', (tester) async {
      const ready = DiscoverState(status: DiscoverStatus.ready);
      whenListen(
        cubit,
        Stream.value(
          const DiscoverState(
            status: DiscoverStatus.ready,
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

    testWidgets('GIVEN the featured load fails '
        'THEN ErrorView shows and no SnackBar', (tester) async {
      whenListen(
        cubit,
        Stream.value(
          const DiscoverState(
            status: DiscoverStatus.error,
            errorMessage: 'offline',
          ),
        ),
        initialState: const DiscoverState(status: DiscoverStatus.loading),
      );

      await pumpPage(tester);
      await tester.pump();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
