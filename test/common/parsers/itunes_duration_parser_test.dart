import 'package:cabina/common/parsers/itunes_duration_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItunesDurationParser.tryParse', () {
    group('accepted formats', () {
      test('GIVEN plain seconds THEN that many seconds', () {
        expect(
          ItunesDurationParser.tryParse('3725'),
          const Duration(hours: 1, minutes: 2, seconds: 5),
        );
      });

      test('GIVEN M:SS THEN minutes and seconds', () {
        expect(
          ItunesDurationParser.tryParse('5:07'),
          const Duration(minutes: 5, seconds: 7),
        );
      });

      test('GIVEN MM:SS THEN minutes and seconds', () {
        expect(
          ItunesDurationParser.tryParse('45:30'),
          const Duration(minutes: 45, seconds: 30),
        );
      });

      test('GIVEN H:MM:SS THEN hours, minutes and seconds', () {
        expect(
          ItunesDurationParser.tryParse('1:02:03'),
          const Duration(hours: 1, minutes: 2, seconds: 3),
        );
      });

      test('GIVEN surrounding whitespace THEN it is trimmed', () {
        expect(
          ItunesDurationParser.tryParse('  45:30\n'),
          const Duration(minutes: 45, seconds: 30),
        );
      });
    });

    group('decimals', () {
      test('GIVEN 1834.5 THEN it rounds to 30:35', () {
        expect(
          ItunesDurationParser.tryParse('1834.5'),
          const Duration(minutes: 30, seconds: 35),
        );
      });

      test('GIVEN 1:02:03.5 THEN it rounds to 1:02:04', () {
        expect(
          ItunesDurationParser.tryParse('1:02:03.5'),
          const Duration(hours: 1, minutes: 2, seconds: 4),
        );
      });
    });

    group('zero', () {
      for (final raw in ['0', '00:00:00', '0.4']) {
        test('GIVEN "$raw" THEN null', () {
          expect(ItunesDurationParser.tryParse(raw), isNull);
        });
      }
    });

    group('out-of-range parts', () {
      test('GIVEN 90:00 THEN 1h30m', () {
        expect(
          ItunesDurationParser.tryParse('90:00'),
          const Duration(hours: 1, minutes: 30),
        );
      });

      test('GIVEN 1:75 THEN 2m15s', () {
        expect(
          ItunesDurationParser.tryParse('1:75'),
          const Duration(minutes: 2, seconds: 15),
        );
      });
    });

    group('malformed', () {
      for (final raw in <String?>[
        null,
        '',
        '   ',
        'abc',
        '-5',
        '45 min',
        '1:2:3:4',
        '1.5:00',
        ':30',
        '30:',
        '1e3',
        '9' * 400,
      ]) {
        test('GIVEN ${raw == null ? 'null' : '"$raw"'} THEN null', () {
          expect(ItunesDurationParser.tryParse(raw), isNull);
        });
      }
    });
  });
}
