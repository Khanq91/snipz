// Local-study copy of Coucou's 28 WAV effects.
// AudioPools are created on first use and disposed with the owning widget.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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
  // These keys start at the bundle root, not the conventional assets/ folder.
  static const assetPrefix = 'lib/components/coucou_mochi/audio/';
  final AudioCache _cache = AudioCache(prefix: '');
  @visibleForTesting
  AudioCache get assetCache => _cache;
  final Map<String, Future<AudioPool>> _pools = {};
  bool _disposed = false;

  Future<void> play(String name, {double volume = .12}) async {
    if (_disposed || !coucouMochiSoundNames.contains(name)) return;
    Future<AudioPool>? poolFuture;
    try {
      poolFuture = _pools.putIfAbsent(
        name,
        () => AudioPool.createFromAsset(
          path: '$assetPrefix$name.wav',
          audioCache: _cache,
          minPlayers: 1,
          maxPlayers: 3,
        ),
      );
      final AudioPool pool = await poolFuture;
      if (_disposed) return;
      await pool.start(volume: volume.clamp(0.0, 1.0).toDouble());
    } catch (error) {
      // Concurrent callers can fail on the same load. Only its owner removes
      // it, so a late failure cannot evict a newer retry or dispose it twice.
      if (poolFuture != null && identical(_pools[name], poolFuture)) {
        _pools.removeWhere((key, _) => key == name);
        try {
          await (await poolFuture).dispose();
        } catch (_) {
          // A failed load has no pool to dispose.
        }
      }
      debugPrint('Coucou Mochi could not play $name: $error');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final pending = _pools.values.toList();
    _pools.clear();
    final List<AudioPool> pools = [];
    for (final Future<AudioPool> pool in pending) {
      try {
        pools.add(await pool);
      } catch (_) {
        // Ignore a pool that did not finish loading.
      }
    }
    await Future.wait(pools.map((pool) => pool.dispose()));
  }
}
