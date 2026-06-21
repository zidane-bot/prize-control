import 'package:flutter_test/flutter_test.dart';
import 'package:precision/services/precision_service.dart';

void main() {
  test('PrecisionRealtimeData parsing test', () {
    // Test parsing the 7-parameter format sent by Arduino
    const raw7 = "52,167,160,30.8,45.0,6.4,OVER DOSIS!";
    final data7 = PrecisionRealtimeData.fromString(raw7);
    expect(data7.n, 52);
    expect(data7.p, 167);
    expect(data7.k, 160);
    expect(data7.suhu, 30.8);
    expect(data7.kelembaban, 45.0);
    expect(data7.ph, 6.4);
    expect(data7.ec, 0); // Defaults to 0 when EC is absent
    expect(data7.statusPupuk, "OVER DOSIS!");

    // Test parsing the legacy 8-parameter format
    const raw8 = "52,167,160,30.8,45.0,6.4,120,TANAH IDEAL";
    final data8 = PrecisionRealtimeData.fromString(raw8);
    expect(data8.n, 52);
    expect(data8.p, 167);
    expect(data8.k, 160);
    expect(data8.suhu, 30.8);
    expect(data8.kelembaban, 45.0);
    expect(data8.ph, 6.4);
    expect(data8.ec, 120);
    expect(data8.statusPupuk, "TANAH IDEAL");
  });
}
