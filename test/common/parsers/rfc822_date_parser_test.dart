import 'package:cabina/common/parsers/rfc822_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rfc822DateParser.tryParse', () {
    group('RFC 822', () {
      test('GIVEN a GMT date THEN that instant in UTC', () {
        final date = Rfc822DateParser.tryParse(
          'Wed, 02 Oct 2024 08:00:00 GMT',
        );

        expect(date, DateTime.utc(2024, 10, 2, 8));
        expect(date?.isUtc, isTrue);
      });

      for (final zone in ['UT', 'UTC', 'Z', '+0000', '-0000']) {
        test('GIVEN zone $zone THEN it is treated as UTC', () {
          expect(
            Rfc822DateParser.tryParse('Wed, 02 Oct 2024 08:00:00 $zone'),
            DateTime.utc(2024, 10, 2, 8),
          );
        });
      }

      test('GIVEN a zone ahead of UTC (+0200) THEN UTC is earlier', () {
        expect(
          Rfc822DateParser.tryParse('Wed, 02 Oct 2024 08:00:00 +0200'),
          DateTime.utc(2024, 10, 2, 6),
        );
      });

      test('GIVEN a zone behind UTC (-0500) THEN UTC is later', () {
        expect(
          Rfc822DateParser.tryParse('Wed, 02 Oct 2024 08:00:00 -0500'),
          DateTime.utc(2024, 10, 2, 13),
        );
      });

      test('GIVEN an offset with minutes THEN they are applied', () {
        expect(
          Rfc822DateParser.tryParse('Wed, 02 Oct 2024 08:00:00 +0530'),
          DateTime.utc(2024, 10, 2, 2, 30),
        );
      });

      test('GIVEN no weekday and a single-digit day THEN that instant', () {
        expect(
          Rfc822DateParser.tryParse('1 Oct 2024 08:00:00 -0500'),
          DateTime.utc(2024, 10, 1, 13),
        );
      });

      test('GIVEN an offset that crosses midnight THEN the day changes', () {
        expect(
          Rfc822DateParser.tryParse('Tue, 31 Dec 2024 23:30:00 -0100'),
          DateTime.utc(2025, 1, 1, 0, 30),
        );
      });
    });

    group('ISO 8601 fallback', () {
      test('GIVEN an ISO 8601 date THEN DateTime.tryParse handles it', () {
        expect(
          Rfc822DateParser.tryParse('2024-10-02T08:00:00Z'),
          DateTime.utc(2024, 10, 2, 8),
        );
      });
    });

    group('rejected', () {
      for (final raw in <String?>[
        null,
        '',
        'sometime last week',
        // Named zones are tech debt: rejected until explicitly accepted.
        'Wed, 02 Oct 2024 08:00:00 EST',
        'Wed, 02 Oct 2024 08:00:00 PDT',
        // Invalid day.
        'Thu, 32 Oct 2024 08:00:00 GMT',
        // Missing zone.
        'Wed, 02 Oct 2024 08:00:00',
      ]) {
        test('GIVEN ${raw == null ? 'null' : '"$raw"'} THEN null', () {
          expect(Rfc822DateParser.tryParse(raw), isNull);
        });
      }
    });
  });
}
