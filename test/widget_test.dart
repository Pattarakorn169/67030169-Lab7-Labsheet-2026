import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/screens/home_page.dart';

/// Repository ปลอมสำหรับใช้ในการทดสอบนี้เท่านั้น ไม่เรียกเครือข่ายจริง
/// Future ที่คืนไปจะ "ค้าง" อยู่ตลอด (ไม่มีวัน complete) เพื่อให้ทดสอบจับสถานะ
/// "กำลังโหลด" (CircularProgressIndicator) ได้แน่นอนทุกครั้งที่รัน
class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() {
    return Completer<List<Item>>().future;
  }
}

void main() {
  testWidgets('แอปเปิดขึ้นมาแสดงชื่อแอปและสถานะกำลังโหลดสินค้า', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          title: 'Campus Marketplace',
          home: HomePage(repository: _FakeItemRepository()),
        ),
      ),
    );

    // ยังไม่ pumpAndSettle เพราะ _FakeItemRepository.getItems() ไม่มีวัน complete
    // (ตั้งใจให้ค้างสถานะ "กำลังโหลด" ไว้) ต้องการแค่ตรวจสอบสถานะเริ่มต้นเท่านั้น
    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}