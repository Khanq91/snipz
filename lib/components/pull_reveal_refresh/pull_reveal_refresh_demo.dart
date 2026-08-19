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
);

class _PullRevealRefreshShowcase extends StatefulWidget {
  const _PullRevealRefreshShowcase();

  @override
  State<_PullRevealRefreshShowcase> createState() =>
      _PullRevealRefreshShowcaseState();
}

class _PullRevealRefreshShowcaseState
    extends State<_PullRevealRefreshShowcase> {
  int _refreshCount = 0;

  Future<void> _fakeLoad() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _refreshCount++);
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF0E0D0B);
    return ColoredBox(
      color: bg,
      child: PullRevealRefresh(
        onRefresh: _fakeLoad,
        triggerExtent: 110,
        maxExtent: 190,
        headerBuilder: (BuildContext context, PullRevealStatus status) {
          return PixelWalker(
            progress: status.progress,
            walking: status.isRefreshing,
            backgroundColor: bg,
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
            const SizedBox(height: 16),
            for (final (String title, String subtitle) in const <(String, String)>[
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
                    color: const Color(0xFF1A1917),
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
