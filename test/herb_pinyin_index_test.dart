import 'package:flutter_test/flutter_test.dart';
import 'package:lpinyin/lpinyin.dart';

void main() {
  test('本草拼音索引可稳定生成首字母', () {
    expect(PinyinHelper.getFirstWordPinyin('熟地黄')[0].toUpperCase(), 'S');
    expect(PinyinHelper.getFirstWordPinyin('丹砂')[0].toUpperCase(), 'D');
    expect(PinyinHelper.getFirstWordPinyin('云母')[0].toUpperCase(), 'Y');
  });
}
