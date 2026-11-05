import 'package:bloc/bloc.dart';
import 'package:cabina/common/observers/app_bloc_observer.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);
}

void main() {
  group('AppBlocObserver', () {
    test('instantiates as const', () {
      expect(const AppBlocObserver(), isNotNull);
    });

    test('handles onError without throwing', () async {
      const observer = AppBlocObserver();
      final cubit = _TestCubit();

      expect(
        () => observer.onError(
          cubit,
          Exception('test error'),
          StackTrace.current,
        ),
        returnsNormally,
      );

      await cubit.close();
    });
  });
}
