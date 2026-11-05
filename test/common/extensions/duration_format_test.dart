import 'package:cabina/common/extensions/duration_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DurationFormat', () {
    group('clock', () {
      test('GIVEN zero THEN 0:00', () {
        expect(Duration.zero.clock, '0:00');
      });

      test('GIVEN under an hour THEN M:SS with padded seconds', () {
        expect(const Duration(minutes: 2, seconds: 3).clock, '2:03');
      });

      test('GIVEN an hour or more THEN H:MM:SS with padded minutes', () {
        expect(
          const Duration(hours: 1, minutes: 2, seconds: 3).clock,
          '1:02:03',
        );
      });
    });

    group('human', () {
      test('GIVEN under a minute THEN <1m', () {
        expect(const Duration(seconds: 30).human, '<1m');
      });

      test('GIVEN under an hour THEN only minutes', () {
        expect(const Duration(minutes: 43).human, '43m');
      });

      test('GIVEN an hour or more THEN hours and minutes', () {
        expect(const Duration(hours: 1, minutes: 2).human, '1h 2m');
      });

      test('GIVEN an exact hour THEN keeps 0m', () {
        expect(const Duration(hours: 1).human, '1h 0m');
      });
    });
  });
}
