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

const _mascotNames = ['Clawd', 'Miu', 'Capy', 'Quạc', 'Cáu', 'Axo'];

// Reuse each art set when switching versions or scrubbing animation time.
final _mascots = <PixelSpriteVersion, List<PixelSprite>>{
  for (final version in PixelSpriteVersion.values)
    version: [
      PixelSprite.clawd(version: version),
      PixelSprite.miu(version: version),
      PixelSprite.capy(version: version),
      PixelSprite.duck(version: version),
      PixelSprite.crab(version: version),
      PixelSprite.axolotl(version: version),
    ],
};

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
  PixelSpriteVersion _version = PixelSpriteVersion.v2;
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
              sprite: _mascots[_version]![_mascot],
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
                _VersionPicker(
                  value: _version,
                  onChanged: (value) => setState(() => _version = value),
                ),
                const SizedBox(height: 16),
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
                    for (int i = 0; i < _mascotNames.length; i++)
                      _PickChip(
                        label: _mascotNames[i],
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

class _VersionPicker extends StatelessWidget {
  const _VersionPicker({required this.value, required this.onChanged});

  final PixelSpriteVersion value;
  final ValueChanged<PixelSpriteVersion> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Phiên bản mascot',
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PixelSpriteVersion>(
          key: const ValueKey('pixel-version'),
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: const Color(0xFF252321),
          borderRadius: BorderRadius.circular(12),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: [
            for (final (version, label) in const [
              (PixelSpriteVersion.v1, 'V1 · Original'),
              (PixelSpriteVersion.v2, 'V2 · Mochi buddies'),
              (PixelSpriteVersion.v3, 'V3 · Pocket pals'),
            ])
              DropdownMenuItem(
                value: version,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (version) {
            if (version != null) onChanged(version);
          },
        ),
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
