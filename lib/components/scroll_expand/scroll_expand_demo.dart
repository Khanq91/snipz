// Demo/usage example for ScrollExpand. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'scroll_expand.dart';

final ComponentDemo scrollExpandDemo = ComponentDemo(
  id: 'scroll_expand',
  builder: (context) => const _ScrollExpandShowcase(),
  // Thumbnail tĩnh: mock trạng thái collapsed (progress 0) — card sunset
  // bo góc inset giữa nền đen, title + scroll hint đè lên. Không scroll
  // surface, không ticker.
  thumbnailBuilder: (context) => const _ScrollExpandThumbnail(),
);

/// A procedural "poster" stands in for the hero image (no assets in the
/// vault). Scroll up: the inset card expands to fullscreen, the title lifts
/// away and the overlay content fades in.
class _ScrollExpandShowcase extends StatelessWidget {
  const _ScrollExpandShowcase();

  @override
  Widget build(BuildContext context) {
    return ScrollExpand(
      title: 'Beyond the Horizon',
      scrollHint: 'scroll to expand',
      media: const _SunsetPoster(),
      overlay: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'THE JOURNEY BEGINS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fullscreen reached.\nThis overlay fades in over the last third.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail cho gallery grid: dựng ở khổ cố định 360×460 rồi FittedBox thu
/// về ô tile — tái hiện frame đầu của ScrollExpand (media là card inset
/// 42%×58% bo góc 24, title lớn ở giữa, hint dưới đáy) bằng widget tĩnh.
class _ScrollExpandThumbnail extends StatelessWidget {
  const _ScrollExpandThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0D0B),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 460,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Card media collapsed: 42% × 58% của stage, bo góc startRadius.
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: const SizedBox(
                    width: 360 * 0.42,
                    height: 460 * 0.58,
                    child: _SunsetPoster(),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Beyond the\nHorizon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -1.2,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 24,
                        color: Color(0x73000000),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Text(
                  'scroll to expand',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.3,
                    color: Color(0x8CFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Procedural sunset: sky gradient, sun disc, water bands.
class _SunsetPoster extends StatelessWidget {
  const _SunsetPoster();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SunsetPainter(), size: Size.infinite);
  }
}

class _SunsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF1A0533),
            Color(0xFF5227FF),
            Color(0xFFFF6D3A),
            Color(0xFFFFC46B),
          ],
          stops: <double>[0, 0.45, 0.75, 1],
        ).createShader(rect),
    );
    final Offset sun = Offset(size.width * 0.5, size.height * 0.68);
    canvas.drawCircle(
      sun,
      size.shortestSide * 0.16,
      Paint()
        ..color = const Color(0xFFFFE9B8)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          size.shortestSide * 0.03,
        ),
    );
    final Paint band = Paint()..color = const Color(0x338A2BE2);
    for (int i = 0; i < 6; i++) {
      final double y = size.height * (0.78 + i * 0.04);
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, size.height * 0.012),
        band,
      );
    }
  }

  @override
  bool shouldRepaint(_SunsetPainter oldDelegate) => false;
}
