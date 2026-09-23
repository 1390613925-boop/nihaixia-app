import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/models/herb.dart';

void main() {
  test('药材空白可选字段按缺失处理，详情页不生成空卡片', () {
    final herb = Herb.fromJson({
      'name': '熟地黄',
      'original': '原文',
      'rongchuan': '',
      'clinical_notes': '   ',
    });

    expect(herb.original, '原文');
    expect(herb.rongchuan, isNull);
    expect(herb.clinicalNotes, isNull);
  });
}
