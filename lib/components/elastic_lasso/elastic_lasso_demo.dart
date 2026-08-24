// Demo/usage example for ElasticLasso.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'elastic_lasso.dart';

final ComponentDemo elasticLassoDemo = ComponentDemo(
  id: 'elastic_lasso',
  builder: (context) => const _Stage(child: ElasticLasso()),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'none',
      label: 'Nothing selected',
      builder: (context) => const _Stage(child: ElasticLasso(animate: false)),
    ),
    DemoVariant(
      id: 'some',
      label: 'Two selected',
      builder: (context) => const _Stage(
        child: ElasticLasso(initialSelection: <int>{1, 4}, animate: false),
      ),
    ),
  ],
);

/// Dark stage matching the kinetics palette (graphite #0e0e10).
class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Center(child: child),
    );
  }
}
