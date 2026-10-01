import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String fmtMoney(int v) => '${NumberFormat('#,##0', 'en_US').format(v)} ₫';

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

const incomeCats = ['Lương', 'Trợ cấp', 'Kinh doanh', 'Thu nhập khác'];
const expenseCats = [
  'Ăn uống', 'Di chuyển', 'Giáo dục', 'Mua sắm',
  'Giải trí', 'Hóa đơn', 'Sức khỏe', 'Chi tiêu khác',
];
