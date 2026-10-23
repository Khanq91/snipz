// Demo/usage example for PullRevealRefresh. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).
//
// Ghép với PixelWalker để tái hiện đúng màn pull-to-refresh của app Claude
// Code mobile: kéo xuống → cảnh pixel hiện dần, nhả → mascot đi bộ trong lúc
// "tải", xong → thu gọn.

import 'package:flutter/material.dart';
import 'package:snipz/components/pixel_walker/pixel_walker.dart';
import 'package:snipz/core/component_demo.dart';

import 'pull_reveal_refresh.dart';

final ComponentDemo pullRevealRefreshDemo = ComponentDemo(
  id: 'pull_reveal_refresh',
  builder: (context) => const _PullRevealRefreshShowcase(),
  // Thumbnail tĩnh: header PixelWalker mở đủ (progress 1, walking false →
  // không ticker) đè trên hai row list giả — gợi đúng khoảnh khắc "kéo tới
  // ngưỡng" mà không cần scroll/refresh thật.
  thumbnailBuilder: (context) => const _PullRevealRefreshThumbnail(),
);

/// Thumbnail cho gallery grid: dựng ở khổ cố định 360×460 rồi FittedBox thu
/// về ô tile — dải cảnh PixelWalker tĩnh phía trên (header đang mở) + hai
/// row bo góc kiểu list của demo (icon + thanh chữ giả, không text thật).
class _PullRevealRefreshThumbnail extends StatelessWidget {
  const _PullRevealRefreshThumbnail();

  static const Color _bg = Color(0xFF0E0D0B);

  Widget _mockRow() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1917),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.code, color: Colors.white38, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Thanh giả thay cho title/subtitle — không lo chữ tràn ô.
                Container(
                  height: 11,
                  width: 190,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 9,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Cảnh pixel tĩnh: progress 1, walking mặc định false.
              const SizedBox(
                height: 170,
                child: PixelWalker(progress: 1, backgroundColor: _bg),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    _mockRow(),
                    const SizedBox(height: 12),
                    _mockRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PullRevealRefreshShowcase extends StatefulWidget {
  const _PullRevealRefreshShowcase();

  @override
  State<_PullRevealRefreshShowcase> createState() =>
      _PullRevealRefreshShowcaseState();
}

class _PullRevealRefreshShowcaseState extends State<_PullRevealRefreshShowcase>
    with SingleTickerProviderStateMixin {
  int _refreshCount = 0;
  PixelWalkerScene _scene = PixelWalkerScene.city;
  PixelSpriteVersion _version = PixelSpriteVersion.v2;
  int _mascot = 0;
  bool _finishing = false;
  late final AnimationController _finish;

  @override
  void initState() {
    super.initState();
    // Create while mounted, including previews that never refresh.
    _finish = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _finish.dispose();
    super.dispose();
  }

  static const _mascotNames = [
    'Clawd',
    'Miu (mèo)',
    'Capy (capybara)',
    'Quạc (vịt)',
    'Cáu (cua)',
    'Axo (axolotl)',
  ];
  static final _mascots = <PixelSpriteVersion, List<PixelSprite>>{
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

  Future<void> _fakeLoad() async {
    setState(() => _finishing = false);
    _finish.value = 0;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    // A host can await its real request here, then keep the header open for
    // one short finishing gesture before completing onRefresh.
    setState(() => _finishing = true);
    try {
      await _finish.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted) setState(() => _refreshCount++);
  }

  @override
  Widget build(BuildContext context) {
    final bool night = _scene == PixelWalkerScene.nightCity;
    final Color bg = night ? const Color(0xFF0A0D16) : const Color(0xFF0E0D0B);
    final Color tile = night
        ? const Color(0xFF151A28)
        : const Color(0xFF1A1917);
    return ColoredBox(
      color: bg,
      child: PullRevealRefresh(
        onRefresh: _fakeLoad,
        triggerExtent: 110,
        maxExtent: 190,
        headerBuilder: (BuildContext context, PullRevealStatus status) {
          return AnimatedBuilder(
            animation: _finish,
            builder: (context, child) {
              final completing = status.isRefreshing && _finishing;
              final settled =
                  status.mode == PullRevealMode.settling && _finishing;
              final completion = settled
                  ? 1.0
                  : (completing ? _finish.value : 0.0);
              final pulling =
                  status.mode == PullRevealMode.dragging ||
                  status.mode == PullRevealMode.armed;
              return PixelWalker(
                progress: status.progress,
                walking: status.isRefreshing && completion < 1,
                motion: completing || settled ? 1 - completion : 1,
                readiness: pulling
                    ? ((status.progress - .65) / .35).clamp(0.0, 1.0)
                    : 0,
                celebration: completion,
                backgroundColor: bg,
                scene: _scene,
                sprite: _mascots[_version]![_mascot],
                skylineColor: night
                    ? const Color(0xFF93A1BE)
                    : const Color(0xFFB9B4AE),
              );
            },
          );
        },
        child: ListView(
          // AlwaysScrollable để kéo được cả khi list ngắn; Clamping là
          // physics Android mặc định — nhánh chính của component.
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Kéo xuống để refresh — đã refresh $_refreshCount lần',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _VersionPicker(
              value: _version,
              onChanged: (value) => setState(() => _version = value),
            ),
            const SizedBox(height: 16),
            // Đổi cảnh/mascot của header ngay trong ngữ cảnh dùng thật —
            // chạm để xoay vòng giá trị.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _CycleChip(
                  label: night ? 'Cảnh: đêm' : 'Cảnh: thành phố',
                  onTap: () => setState(
                    () => _scene = night
                        ? PixelWalkerScene.city
                        : PixelWalkerScene.nightCity,
                  ),
                ),
                _CycleChip(
                  label: 'Mascot: ${_mascotNames[_mascot]}',
                  onTap: () => setState(
                    () => _mascot = (_mascot + 1) % _mascotNames.length,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final (String title, String subtitle)
                in const <(String, String)>[
                  ('Tính khả thi tính năng ứng dụng', 'Khanq91/noctis'),
                  ('UI/UX audit và redesign proposal', 'Khanq91/noctis'),
                  ('Kiểm tra hiện trạng dự án', 'Khanq91/Muzicz'),
                  ('Port pull-to-refresh sang Flutter', 'Khanq91/Snipz'),
                  ('Dựng pixel walker scene', 'Khanq91/Snipz'),
                ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tile,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.code, color: Colors.white38),
                    title: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ),
          ],
        ),
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

/// Nút pill nhỏ tự style (không phụ thuộc theme) — chạm để xoay vòng giá trị.
class _CycleChip extends StatelessWidget {
  const _CycleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.swap_horiz, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
