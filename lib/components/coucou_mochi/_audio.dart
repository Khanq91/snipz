// Local-study copy of Coucou's 28 WAV effects.
// AudioPools are created on first use and disposed with the owning widget.

import 'package:audioplayers/audioplayers.dart';

const List<String> coucouMochiSoundNames = [
  'peek',
  'open',
  'close',
  'hover',
  'blip',
  'slap',
  'annoyed',
  'dizzy',
  'greet',
  'work',
  'finish',
  'error',
  'approval',
  'question',
  'approve',
  'gulp',
  'tick',
  'send',
  'love',
  'pop',
  'proud',
  'wink',
  'yawn',
  'attach',
  'think',
  'search',
  'rate',
  'sleep',
];

class CoucouMochiAudio {
  final Map<String, Future<AudioPool>> _pools = {};
  bool _disposed = false;

  Future<void> play(String name, {double volume = .12}) async {
    if (_disposed || !coucouMochiSoundNames.contains(name)) return;
    try {
      final Future<AudioPool> poolFuture = _pools.putIfAbsent(
        name,
        () => AudioPool.createFromAsset(
          path: 'lib/components/coucou_mochi/audio/$name.wav',
          minPlayers: 1,
          maxPlayers: 3,
        ),
      );
      final AudioPool pool = await poolFuture;
      if (_disposed) return;
      await pool.start(volume: volume.clamp(0.0, 1.0).toDouble());
    } catch (_) {
      // A missing or unsupported sound is decorative and must not break paint.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final List<AudioPool> pools = [];
    for (final Future<AudioPool> pool in _pools.values) {
      try {
        pools.add(await pool);
      } catch (_) {
        // Ignore a pool that did not finish loading.
      }
    }
    await Future.wait(pools.map((pool) => pool.dispose()));
    _pools.clear();
  }
}
