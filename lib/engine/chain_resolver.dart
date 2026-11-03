/// Deterministic breadth-first pulse traversal. The visitor settles each shop
/// once and returns outgoing amounts; converging branches are summed.
class ChainResolver {
  static void resolve(
    int origin,
    double amount,
    int startingDepth,
    Map<int, double> Function(int, double, int, Set<int>) visit,
  ) {
    final visited = <int>{};
    var wave = <int, double>{origin: amount};
    var depth = startingDepth;
    while (wave.isNotEmpty) {
      final next = <int, double>{};
      final targets = wave.keys.toList()..sort();
      for (final index in targets) {
        if (!visited.add(index)) continue;
        final outgoing = visit(index, wave[index]!, depth, visited);
        for (final entry in outgoing.entries) {
          next[entry.key] = (next[entry.key] ?? 0) + entry.value;
        }
      }
      wave = next..removeWhere((index, _) => visited.contains(index));
      depth++;
    }
  }
}
