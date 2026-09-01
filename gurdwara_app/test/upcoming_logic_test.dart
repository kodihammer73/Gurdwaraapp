// Unit tests for the home "Upcoming Events" windowing, Akhand Path run
// expansion, per-day live indicator, and same-day live-ordering logic in
// lib/main.dart.
//
// These cover the agreed behaviour:
//  - Rolling 3-day-minimum window: Sat -> Sat/Sun/Mon, Sun -> Sun/Mon/Tue,
//    Mon-Fri -> today..Sunday.
//  - Started Akhand Path runs expand to all remaining days (Sat start -> Mon,
//    Sun start -> Tue).
//  - Each Akhand Path day is lit independently (day1 start..23:59, middle
//    00:00..23:59, last 00:00..start+4h).
//  - Two same-day events sort by time, but the live one floats to the top and
//    then falls back to time order once its window ends.

import 'package:flutter_test/flutter_test.dart';
import 'package:gurdwara_app/main.dart';

DateTime _d(int y, int m, int day, [int h = 0, int min = 0]) =>
    DateTime(y, m, day, h, min);

List<DateTime> _dates(List<HomepageEvent> events) =>
    events.map((e) => dateOnly(e.date)).toList();

HomepageEvent _single(String title, DateTime date, {String? time}) {
  final details = time == null ? title : '$title @$time';
  return HomepageEvent(
    title: title,
    date: date,
    details: details,
    imagePath: '',
    startAt: time == null ? null : parseStartAt(details, date),
  );
}

// Builds a 3-day Akhand Path run using the same parser the app uses, so runId
// and status metadata (start/cont/end) are assigned for real.
List<HomepageEvent> _akhandRun(DateTime day1) {
  final lines = <String>[];
  for (var i = 0; i < 3; i++) {
    final d = day1.add(Duration(days: i));
    final ds =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    lines.add('Akhand Path|$ds|by Test Host @9am|');
  }
  return parseHomepageEvents(lines.join('\n'));
}

void main() {
  group('upcomingWindowEnd', () {
    test('Saturday ends on Monday (3-day minimum)', () {
      expect(upcomingWindowEnd(_d(2026, 11, 14)), _d(2026, 11, 16));
    });

    test('Sunday ends on Tuesday (3-day minimum)', () {
      expect(upcomingWindowEnd(_d(2026, 11, 15)), _d(2026, 11, 17));
    });

    test('Monday ends on Sunday', () {
      expect(upcomingWindowEnd(_d(2026, 11, 16)), _d(2026, 11, 22));
    });

    test('Tuesday ends on Sunday', () {
      expect(upcomingWindowEnd(_d(2026, 11, 10)), _d(2026, 11, 15));
    });

    test('Friday ends on Sunday (window not longer than to Sunday)', () {
      expect(upcomingWindowEnd(_d(2026, 11, 13)), _d(2026, 11, 15));
    });
  });

  group('filterUpcomingWindow', () {
    final evSat = _single('EventSat', _d(2026, 11, 14));
    final evSun = _single('EventSun', _d(2026, 11, 15));
    final evMon = _single('EventMon', _d(2026, 11, 16));
    final evTue = _single('EventTue', _d(2026, 11, 17));
    final all = [evSat, evSun, evMon, evTue];

    test('Saturday shows Sat + Sun + Mon only', () {
      final res = filterUpcomingWindow(all, _d(2026, 11, 14));
      expect(_dates(res), orderedEquals([
        _d(2026, 11, 14),
        _d(2026, 11, 15),
        _d(2026, 11, 16),
      ]));
    });

    test('Sunday shows Sun + Mon + Tue only', () {
      final res = filterUpcomingWindow(all, _d(2026, 11, 15));
      expect(_dates(res), orderedEquals([
        _d(2026, 11, 15),
        _d(2026, 11, 16),
        _d(2026, 11, 17),
      ]));
    });

    test('Monday shows Monday onwards through Sunday', () {
      final res = filterUpcomingWindow(all, _d(2026, 11, 16));
      // Mon (16) and Tue (17) are both inside Mon..Sun (22).
      expect(_dates(res), orderedEquals([
        _d(2026, 11, 16),
        _d(2026, 11, 17),
      ]));
    });
  });

  group('Akhand Path run expansion', () {
    test('first day Friday: no problem, Fri-Sun all in window', () {
      final run = _akhandRun(_d(2026, 11, 13)); // Fri 13 -> 13,14,15
      final res = filterUpcomingWindow(run, _d(2026, 11, 13));
      expect(_dates(res), orderedEquals([
        _d(2026, 11, 13),
        _d(2026, 11, 14),
        _d(2026, 11, 15),
      ]));
    });

    test('first day Saturday: expands through Monday', () {
      final run = _akhandRun(_d(2026, 11, 14)); // Sat 14 -> 14,15,16
      // Today Friday 13: window ends Sun 15; run's first day (Sat 14) is in
      // window so the remaining days (Sun, Mon) are appended through Monday.
      final res = filterUpcomingWindow(run, _d(2026, 11, 13));
      expect(_dates(res), orderedEquals([
        _d(2026, 11, 14),
        _d(2026, 11, 15),
        _d(2026, 11, 16),
      ]));
    });

    test('first day Sunday: expands through Tuesday', () {
      final run = _akhandRun(_d(2026, 11, 15)); // Sun 15 -> 15,16,17
      // Today Saturday 14: window ends Mon 16; run's first day (Sun 15) is in
      // window so the remaining days (Mon, Tue) are appended through Tuesday.
      final res = filterUpcomingWindow(run, _d(2026, 11, 14));
      expect(_dates(res), orderedEquals([
        _d(2026, 11, 15),
        _d(2026, 11, 16),
        _d(2026, 11, 17),
      ]));
    });
  });

  group('isAkhandDayLive (per-day light)', () {
    final run = _akhandRun(_d(2026, 11, 15)); // start 15, cont 16, end 17

    test('day 1 (start) lit from startAt to 23:59', () {
      final day1 = run[0];
      expect(day1.status, 'start');
      expect(isAkhandDayLive(day1, _d(2026, 11, 15, 8, 59)), isFalse);
      expect(isAkhandDayLive(day1, _d(2026, 11, 15, 9, 0)), isTrue);
      expect(isAkhandDayLive(day1, _d(2026, 11, 15, 23, 59)), isTrue);
      expect(isAkhandDayLive(day1, _d(2026, 11, 16, 0, 1)), isFalse);
    });

    test('middle day (cont) lit from 00:00 to 23:59', () {
      final day2 = run[1];
      expect(day2.status, 'cont');
      expect(isAkhandDayLive(day2, _d(2026, 11, 16, 0, 0)), isTrue);
      expect(isAkhandDayLive(day2, _d(2026, 11, 16, 12, 0)), isTrue);
      expect(isAkhandDayLive(day2, _d(2026, 11, 16, 23, 59)), isTrue);
      expect(isAkhandDayLive(day2, _d(2026, 11, 17, 0, 1)), isFalse);
    });

    test('last day (end) lit from 00:00 to startAt+4h (13:00)', () {
      final day3 = run[2];
      expect(day3.status, 'end');
      expect(isAkhandDayLive(day3, _d(2026, 11, 17, 0, 0)), isTrue);
      expect(isAkhandDayLive(day3, _d(2026, 11, 17, 10, 0)), isTrue);
      expect(isAkhandDayLive(day3, _d(2026, 11, 17, 12, 59)), isTrue);
      expect(isAkhandDayLive(day3, _d(2026, 11, 17, 13, 0)), isFalse);
    });
  });

  group('isNowLive (single event)', () {
    final e = _single('Sukhmani Sahib', _d(2026, 11, 15), time: '9am');
    test('lit from start to start+4h for a non-Asa Di Vaar event', () {
      expect(isNowLive(e, _d(2026, 11, 15, 8, 59)), isFalse);
      expect(isNowLive(e, _d(2026, 11, 15, 9, 0)), isTrue);
      expect(isNowLive(e, _d(2026, 11, 15, 12, 59)), isTrue);
      expect(isNowLive(e, _d(2026, 11, 15, 13, 0)), isFalse);
    });
  });

  group('compareEntriesLiveNow (same-day ordering)', () {
    final e9 = _single('Morning Kirtan', _d(2026, 11, 15), time: '9am');
    final e4 = _single('Evening Kirtan', _d(2026, 11, 15), time: '4pm');
    final a = [e9];
    final b = [e4];

    List<String> sorted(DateTime now) {
      final list = [a, b];
      list.sort((x, y) => compareEntriesLiveNow(x, y, now));
      return list.map((run) => run.first.title).toList();
    }

    test('before either starts: time order (9am first)', () {
      expect(sorted(_d(2026, 11, 15, 8, 0)),
          orderedEquals(['Morning Kirtan', 'Evening Kirtan']));
    });

    test('while 9am is live (9am-1pm): 9am stays on top', () {
      expect(sorted(_d(2026, 11, 15, 10, 0)),
          orderedEquals(['Morning Kirtan', 'Evening Kirtan']));
    });

    test('gap after 9am over (1pm-4pm): back to time order (9am first)', () {
      expect(sorted(_d(2026, 11, 15, 14, 0)),
          orderedEquals(['Morning Kirtan', 'Evening Kirtan']));
    });

    test('while 4pm is live (4pm-8pm): 4pm moves to top', () {
      expect(sorted(_d(2026, 11, 15, 17, 0)),
          orderedEquals(['Evening Kirtan', 'Morning Kirtan']));
    });

    test('after 4pm over (+4h): sorts back to time order (9am first)', () {
      expect(sorted(_d(2026, 11, 15, 21, 0)),
          orderedEquals(['Morning Kirtan', 'Evening Kirtan']));
    });
  });
}