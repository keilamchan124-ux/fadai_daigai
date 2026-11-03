import 'package:fadai_daigai/engine/game_engine.dart';
import 'package:fadai_daigai/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

GameEngine board(List<String> ids, List<String> relics) {
  final e = GameEngine(seed: 42)..selectDraftChoice(0);
  e.slots = List<PlacedShop?>.filled(6, null, growable: true);
  for (var i = 0; i < ids.length; i++) {
    e.slots[i] = PlacedShop(definitionId: ids[i]);
  }
  e.equippedRelicIds = relics;
  e.bossDefeatedInCurrentTier = true;
  e.cash = 100000;
  e.recalculateSynergies();
  return e;
}

void run(GameEngine e) {
  e.startQuarterMarketRun();
  e.triggerTimeSkip();
}

void main() {
  test('food growth is capped per quarter and grants a real benefit', () {
    final ids = List.filled(6, 't1_fishball');
    final a = board(ids, ['rel_wok']);
    final b = board(ids, []);
    run(a);
    run(b);
    expect(a.cash, greaterThan(b.cash));
    for (final shop in a.slots.whereType<PlacedShop>()) {
      expect(shop.permanentBonusPayout, lessThanOrEqualTo(28.000001));
    }
  });
  test('charge build bursts more frequently without partial cash leakage', () {
    final a = board(['t1_fishball', 't1_night_hawker'], ['rel_dice']);
    final b = board(['t1_fishball', 't1_night_hawker'], []);
    run(a);
    run(b);
    expect(a.cash, greaterThan(b.cash));
    expect(a.slots[1]!.chargeCount, 0);
    expect(b.slots[1]!.chargeCount, 1);
  });
  test('long chain receives depth benefit with stable directions', () {
    final ids = ['t1_fishball', 't1_sweet_soup', 't1_street_lender'];
    final a = board(ids, ['rel_combo_battery']);
    final b = board(ids, []);
    run(a);
    run(b);
    expect(a.cash, greaterThan(b.cash));
    expect(a.quarterChainDrafts, lessThanOrEqualTo(1));
  });
  test('leverage core needs material debt rather than a one dollar loan', () {
    final ids = ['t1_fishball', 't1_sweet_soup'];
    final a = board(ids, ['rel_blackcard'])..bankLoan = 1;
    final b = board(ids, [])..bankLoan = 1;
    run(a);
    run(b);
    expect(a.cash - b.cash, lessThan(1));
    final c = board(ids, ['rel_blackcard'])..bankLoan = 300;
    final d = board(ids, [])..bankLoan = 300;
    run(c);
    run(d);
    expect(c.cash, greaterThan(d.cash));
  });
}
