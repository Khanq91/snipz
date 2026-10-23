// Demo/usage example for PixelWalker. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_walker.dart';

final ComponentDemo pixelWalkerDemo = ComponentDemo(
  id: 'pixel_walker',
  builder: (context) => const _PixelWalkerShowcase(),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0D0B),
    child: PixelWalker(), // tĩnh: progress 1, không ticker
  ),
);

final _mascots = <(String, String, PixelSprite)>[
  ('clawd', 'Clawd', PixelSprite.clawd()),
  ('miu', 'Miu', PixelSprite.miu()),
  ('capy', 'Capy', PixelSprite.capy()),
  ('duck', 'Quạc', PixelSprite.duck()),
  ('crab', 'Cáu', PixelSprite.crab()),
  ('axolotl', 'Axo', PixelSprite.axolotl()),
];

/// Cảnh trong khung header 160px + điều khiển trực tiếp các param chính:
/// nút đổi `scene` (thành phố / thành phố đêm) và `sprite` (6 mascot: Clawd,
/// Miu, Capy, Quạc, Cáu, Axo), kéo slider `progress` để thấy hiệu ứng hiện
/// dần, bật `walking` để mascot bước và các layer trôi parallax.
class _PixelWalkerShowcase extends StatefulWidget {
  const _PixelWalkerShowcase();

  @override
  State<_PixelWalkerShowcase> createState() => _PixelWalkerShowcaseState();
}

class _PixelWalkerShowcaseState extends State<_PixelWalkerShowcase> {
  double _progress = 1.0;
  double _scale = 1.0;
  bool _walking = true;
  bool _ready = false;
  bool _scrubbing = false;
  double _sampleTime = .38;
  double _speed = 1;
  PixelWalkerScene _scene = PixelWalkerScene.city;
  int _mascot = 0;

  @override
  Widget build(BuildContext context) {
    final bool night = _scene == PixelWalkerScene.nightCity;
    // Mỗi scene một tông nền/skyline — component chỉ nhận màu, không tự đoán.
    final Color bg = night ? const Color(0xFF0A0D16) : const Color(0xFF0E0D0B);
    // Material thay vì ColoredBox: SwitchListTile vẽ ink lên Material gần
    // nhất — ColoredBox chen giữa sẽ che nó (assertion ở debug mode).
    return Material(
      color: bg,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 160,
            width: double.infinity,
            child: PixelWalker(
              progress: _progress,
              walking: _walking,
              readiness: _ready ? 1 : 0,
              frozenAt: _scrubbing ? _sampleTime : null,
              speed: _speed,
              scale: _scale,
              scene: _scene,
              sprite: _mascots[_mascot].$3,
              skylineColor: night
                  ? const Color(0xFF93A1BE)
                  : const Color(0xFFB9B4AE),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                const Text(
                  'Khung cảnh',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _PickChip(
                      label: 'Thành phố',
                      selected: !night,
                      onTap: () =>
                          setState(() => _scene = PixelWalkerScene.city),
                    ),
                    _PickChip(
                      label: 'Đêm — cao tầng, núi, mây',
                      selected: night,
                      onTap: () =>
                          setState(() => _scene = PixelWalkerScene.nightCity),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn đồng hành',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (int i = 0; i < _mascots.length; i++)
                      _PickChip(
                        label: _mascots[i].$2,
                        selected: _mascot == i,
                        onTap: () => setState(() => _mascot = i),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text(
                    'Đi bộ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _walking,
                  onChanged: (bool v) => setState(() {
                    _walking = v;
                    if (v) _ready = false;
                  }),
                ),
                SwitchListTile(
                  title: const Text(
                    'Sẵn sàng',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _ready,
                  onChanged: (value) => setState(() {
                    _ready = value;
                    if (value) _walking = false;
                  }),
                ),
                Text(
                  'Nhịp bước ${_speed.toStringAsFixed(2)}×',
                  style: const TextStyle(color: Colors.white54),
                ),
                Slider(
                  key: const ValueKey('pixel-speed'),
                  value: _speed,
                  min: .4,
                  max: 1.8,
                  onChanged: (value) => setState(() => _speed = value),
                ),
                SwitchListTile(
                  title: const Text(
                    'Xem từng nhịp',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _scrubbing,
                  onChanged: (value) => setState(() => _scrubbing = value),
                ),
                if (_scrubbing)
                  Slider(
                    key: const ValueKey('pixel-scrub'),
                    value: _sampleTime,
                    max: 4,
                    label: '${_sampleTime.toStringAsFixed(2)} s',
                    onChanged: (value) => setState(() => _sampleTime = value),
                  ),
                Text(
                  'Độ mở ${(_progress * 100).round()}%',
                  style: const TextStyle(color: Colors.white54),
                ),
                Slider(
                  value: _progress,
                  onChanged: (double v) => setState(() => _progress = v),
                ),
                Text(
                  'Cỡ pixel ${_scale.toStringAsFixed(2)}×',
                  style: const TextStyle(color: Colors.white54),
                ),
                Slider(
                  value: _scale,
                  min: 0.5,
                  max: 3,
                  onChanged: (double v) => setState(() => _scale = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip chọn 1-trong-n, tự style để không phụ thuộc theme app.
class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8875C) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1A120C) : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
