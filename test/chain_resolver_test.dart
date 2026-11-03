import 'package:fadai_daigai/engine/chain_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diamond merges amounts and cycles cannot repeat a shop', () {
    final visits = <int, double>{};
    ChainResolver.resolve(0, 100, 1, (index, amount, depth, seen) {
      visits[index] = amount;
      return switch (index) {
        0 => {1: 50.0, 2: 50.0},
        1 => {3: 25.0},
        2 => {3: 40.0},
        3 => {0: 65.0},
        _ => <int, double>{},
      };
    });
    expect(visits, {0: 100.0, 1: 50.0, 2: 50.0, 3: 65.0});
  });
}
