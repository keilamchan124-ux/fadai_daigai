import 'dart:math';

/// Portable deterministic RNG whose exact position can be saved.
class SavedRandom implements Random {
  int state;
  SavedRandom(int seed) : state = seed & 0xffffffff;
  int _next() {
    state = (1664525 * state + 1013904223) & 0xffffffff;
    return state;
  }

  @override
  double nextDouble() => _next() / 4294967296.0;
  @override
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max);
    final limit = 4294967296 - 4294967296 % max;
    var value = _next();
    while (value >= limit) {
      value = _next();
    }
    return value % max;
  }

  @override
  bool nextBool() => nextDouble() < 0.5;
}
