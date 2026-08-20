// Demo/usage example for PixelLoader. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_loader.dart';

final ComponentDemo pixelLoaderDemo = ComponentDemo(
  id: 'pixel_loader',
  builder: (context) => const _PixelLoaderShowcase(),
  // Tĩnh hoàn toàn: animated false → không ticker nào chạy trong grid.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF141414),
    child: Center(
      child: PixelLoaderIndicator(animated: false, label: 'Loading session...'),
    ),
  ),
);

/// Giả lập đúng flow thật: mở màn → load ~2.2s → mascot squash, hard cut,
/// content fade-in. Nút "Load lại" chạy lại từ đầu; slider chỉnh cỡ
/// macro-pixel để xem scale hoạt động.
class _PixelLoaderShowcase extends StatefulWidget {
  const _PixelLoaderShowcase();

  @override
  State<_PixelLoaderShowcase> createState() => _PixelLoaderShowcaseState();
}

class _PixelLoaderShowcaseState extends State<_PixelLoaderShowcase> {
  bool _loading = true;
  bool _revealed = false;
  double _scale = 1.0;
  Timer? _fakeLoad;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  @override
  void dispose() {
    _fakeLoad?.cancel();
    super.dispose();
  }

  void _startLoad() {
    _fakeLoad?.cancel();
    setState(() {
      _loading = true;
      _revealed = false;
    });
    _fakeLoad = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      child: Column(
        children: <Widget>[
          Expanded(
            child: PixelLoader(
              loading: _loading,
              scale: _scale,
              onRevealComplete: () => setState(() => _revealed = true),
              child: const _FakeSession(),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _ActionChip(label: 'Load lại', onTap: _startLoad),
                    const SizedBox(width: 12),
                    Text(
                      _loading
                          ? 'loading...'
                          : _revealed
                          ? 'onRevealComplete ✓'
                          : 'revealing...',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'scale ${_scale.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54),
                ),
                Slider(
                  value: _scale,
                  min: 0.5,
                  max: 2,
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

/// Nội dung giả sau loader — vài "message" để thấy rõ content fade-in.
class _FakeSession extends StatelessWidget {
  const _FakeSession();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF141414),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'Session',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _bubble('Xin chào! Session đã load xong.', accent: true),
          _bubble('Loader squash → hard cut → màn này fade-in ~300ms.'),
          _bubble('Nhấn "Load lại" bên dưới để xem lại từ đầu.'),
        ],
      ),
    );
  }

  static Widget _bubble(String text, {bool accent = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFD77655) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent ? const Color(0xFF1A120C) : Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Nút hành động tự style để không phụ thuộc theme app.
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD77655),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A120C),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
