import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart' show Gender, Location;

import 'package:nihaisha_app/services/bazi_service.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';

/// 早晚子时 × 真太阳时 交叉组合回归（P0 修复验证）。
///
/// 修复前两处缺陷：
/// 1. 早子时（校正后 00:00–01:00）八字农历未 +1 天，与紫微 / 日柱不同步；
/// 2. 早晚子时判定用未校正的原始小时，真太阳时开启时日柱差一天、时柱落到亥时。
void main() {
  /// 同时返回八字与紫微的四柱（日、时）与农历。
  ({String day, String time, String lunar}) baziOf(
    DateTime solar, {
    required double lon,
    required bool rat,
    required bool tst,
  }) {
    final p = computeBaZiPaipan(
      solar,
      isMale: true,
      useTrueSolarTime: tst,
      ratHourMode: rat,
      location: Location(lon, 30),
    );
    return (day: p.bazi.day, time: p.bazi.time, lunar: p.lunarText);
  }

  ({String day, String time, String lunar}) ziweiOf(
    DateTime solar, {
    required double lon,
    required bool rat,
    required bool tst,
  }) {
    final c = calculateZiweiChart(
      solar: solar,
      gender: Gender.male,
      location: Location(lon, 30),
      useTrueSolarTime: tst,
      ratHourMode: rat,
    );
    return (day: c.baziDay, time: c.baziTime, lunar: c.lunarText);
  }

  group('任务1：早子时农历与紫微 / 日柱同步', () {
    for (final c in [
      (
        label: '① 2024-02-10 00:30',
        solar: DateTime(2024, 2, 10, 0, 30),
        expectLunar: '甲辰（2024）年正月初二',
        expectDay: '乙巳',
      ),
      (
        label: '⑨ 2023-01-22 00:30',
        solar: DateTime(2023, 1, 22, 0, 30),
        expectLunar: '癸卯（2023）年正月初二',
        expectDay: '辛巳',
      ),
    ]) {
      test('${c.label} 子时开 → 八字农历 = 紫微农历 = ${c.expectLunar}', () {
        final bz = baziOf(c.solar, lon: 120, rat: true, tst: false);
        final zw = ziweiOf(c.solar, lon: 120, rat: true, tst: false);
        expect(bz.day, c.expectDay, reason: '早子时日柱应取次日');
        expect(bz.lunar, c.expectLunar);
        expect(zw.lunar, c.expectLunar);
        expect(bz.lunar, zw.lunar, reason: '八字与紫微农历必须一致');
      });

      test('${c.label} 子时开 + 真太阳开 → 两屏仍一致', () {
        final bz = baziOf(c.solar, lon: 120, rat: true, tst: true);
        final zw = ziweiOf(c.solar, lon: 120, rat: true, tst: true);
        expect(bz.lunar, zw.lunar);
        expect(bz.day, c.expectDay);
      });

      test('${c.label} 子时关 → 农历保持原始日（正月初一）', () {
        final bz = baziOf(c.solar, lon: 120, rat: false, tst: false);
        final zw = ziweiOf(c.solar, lon: 120, rat: false, tst: false);
        expect(bz.lunar, c.expectLunar.replaceAll('初二', '初一'));
        expect(zw.lunar, bz.lunar);
      });
    }
  });

  group('任务2：先校正真太阳时、再判早晚子时', () {
    test('③ 2024-02-10 00:30 @E100 子时开+真太阳 → 癸卯日 癸亥时（校正后 22:55 属亥时）', () {
      final s = DateTime(2024, 2, 10, 0, 30);
      final bz = baziOf(s, lon: 100, rat: true, tst: true);
      final zw = ziweiOf(s, lon: 100, rat: true, tst: true);
      // E100 校正量 ≈ −95min → 2/9 22:55，落在亥时而非子时，不触发子时逻辑
      expect(bz.day, '癸卯');
      expect(bz.time, '癸亥');
      expect(zw.day, '癸卯');
      expect(zw.time, '癸亥');
      expect(bz.lunar, zw.lunar);
    });

    test('③′ 2024-02-10 00:30 @E105 子时开+真太阳 → 癸卯日 甲子时（校正后 23:15 晚子时）', () {
      final s = DateTime(2024, 2, 10, 0, 30);
      final bz = baziOf(s, lon: 105, rat: true, tst: true);
      final zw = ziweiOf(s, lon: 105, rat: true, tst: true);
      // E105 校正量 ≈ −75min → 2/9 23:15 → 晚子时：日柱当天(2/9 癸卯)、
      // 时柱次日子时（次日 2/10 甲辰日 → 甲日遁子 = 甲子）
      expect(bz.day, '癸卯');
      expect(bz.time, '甲子');
      expect(zw.day, '癸卯');
      expect(zw.time, '甲子');
      expect(bz.lunar, zw.lunar);
    });

    test('④ 2024-02-09 23:30 @E140 子时开+真太阳 → 乙巳日 丙子时', () {
      final s = DateTime(2024, 2, 9, 23, 30);
      final bz = baziOf(s, lon: 140, rat: true, tst: true);
      final zw = ziweiOf(s, lon: 140, rat: true, tst: true);
      // 校正后 ≈ 2/10 00:5x → 早子时：日柱次日(2/11 乙巳)、时柱子时(丙子)
      expect(bz.day, '乙巳');
      expect(bz.time, '丙子');
      expect(zw.day, '乙巳');
      expect(zw.time, '丙子');

      // 同一时刻 @E120：校正后 2/9 23:15 仍属晚子时 → 日柱当天、时柱次日子时
      final bz120 = baziOf(s, lon: 120, rat: true, tst: true);
      expect(bz120.day, '癸卯');
      expect(bz120.time, '甲子');
      expect(bz120.lunar, '癸卯（2024）年十二月三十');
    });

    test('⑪ 2023-01-22 00:30 @E100 子时开+真太阳 → 己卯日 乙亥时（校正后 22:58 属亥时）', () {
      final s = DateTime(2023, 1, 22, 0, 30);
      final bz = baziOf(s, lon: 100, rat: true, tst: true);
      final zw = ziweiOf(s, lon: 100, rat: true, tst: true);
      expect(bz.day, '己卯');
      expect(bz.time, '乙亥');
      expect(zw.day, '己卯');
      expect(zw.time, '乙亥');
      expect(bz.lunar, zw.lunar);
    });

    test('⑪′ 2023-01-22 00:30 @E105 子时开+真太阳 → 己卯日 丙子时（校正后 23:18 晚子时）', () {
      final s = DateTime(2023, 1, 22, 0, 30);
      final bz = baziOf(s, lon: 105, rat: true, tst: true);
      final zw = ziweiOf(s, lon: 105, rat: true, tst: true);
      // 晚子时时柱取「次日子时」：次日 1/22 为庚辰日 → 庚日遁子 = 丙子
      // （若按当日己卯日遁子则为甲子，属另一流派口径，本引擎取次日子时）
      expect(bz.day, '己卯');
      expect(bz.time, '丙子');
      expect(zw.day, '己卯');
      expect(zw.time, '丙子');
      expect(bz.lunar, zw.lunar);
    });
  });

  group('回归：晚子时 / 非子时 / 单开关场景不受影响', () {
    test('② 2024-02-09 23:30 @E120 子时开 → 癸卯日 甲子时 / 十二月三十', () {
      final s = DateTime(2024, 2, 9, 23, 30);
      final bz = baziOf(s, lon: 120, rat: true, tst: false);
      final zw = ziweiOf(s, lon: 120, rat: true, tst: false);
      expect(bz.day, '癸卯');
      expect(bz.time, '甲子');
      expect(bz.lunar, '癸卯（2024）年十二月三十');
      expect(zw.lunar, bz.lunar);
    });

    test('⑤ 2024-02-10 12:00 四种组合 → 甲辰日 庚午时 / 正月初一', () {
      final s = DateTime(2024, 2, 10, 12, 0);
      for (final rat in [false, true]) {
        for (final tst in [false, true]) {
          final bz = baziOf(s, lon: 120, rat: rat, tst: tst);
          expect(bz.day, '甲辰');
          expect(bz.time, '庚午');
          expect(bz.lunar, '甲辰（2024）年正月初一');
        }
      }
    });

    test('③b 2024-02-10 00:30 @E100 仅真太阳开 → 癸卯日 癸亥时（跨日回前一日）', () {
      final bz = baziOf(DateTime(2024, 2, 10, 0, 30),
          lon: 100, rat: false, tst: true);
      expect(bz.day, '癸卯');
      expect(bz.time, '癸亥');
    });

    test('⑧ 闰月 2023-03-22 10:00 → 闰二月初一', () {
      final bz = baziOf(DateTime(2023, 3, 22, 10, 0),
          lon: 120, rat: false, tst: false);
      final zw = ziweiOf(DateTime(2023, 3, 22, 10, 0),
          lon: 120, rat: false, tst: false);
      expect(bz.lunar, '癸卯（2023）年闰二月初一');
      expect(zw.lunar, bz.lunar);
    });
  });
}
