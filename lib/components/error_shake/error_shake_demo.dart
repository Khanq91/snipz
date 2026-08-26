import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'error_shake.dart';

final ComponentDemo errorShakeDemo = ComponentDemo(
  id: 'error_shake',
  builder: (context) => const ErrorShakeDemo(),
  thumbnailBuilder: (context) => const ErrorShakeThumbnail(),
);

class ErrorShakeDemo extends StatefulWidget {
  const ErrorShakeDemo({super.key});

  @override
  State<ErrorShakeDemo> createState() => _ErrorShakeDemoState();
}

class _ErrorShakeDemoState extends State<ErrorShakeDemo> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInvalid = false;
  int _shakeTrigger = 0;

  void _validate() {
    final isInvalid = _controller.text.trim().isEmpty;
    setState(() {
      _isInvalid = isInvalid;
      if (isInvalid) {
        _shakeTrigger += 1;
      }
    });
    if (isInvalid) {
      _focusNode.requestFocus();
    }
  }

  void _handleChanged(String value) {
    if (_isInvalid && value.trim().isNotEmpty) {
      setState(() => _isInvalid = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            child: ErrorShake(
              controller: _controller,
              focusNode: _focusNode,
              isInvalid: _isInvalid,
              shakeTrigger: _shakeTrigger,
              labelText: 'Email',
              hintText: 'you@example.com',
              semanticsLabel: 'Email address',
              errorMessage: 'Please enter your email.',
              onChanged: _handleChanged,
              onSubmitted: (_) => _validate(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: FilledButton(
              onPressed: _validate,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A settled invalid state for galleries that capture non-animated thumbnails.
class ErrorShakeThumbnail extends StatelessWidget {
  const ErrorShakeThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 220,
      child: ErrorShake(
        isInvalid: true,
        shakeTrigger: 0,
        errorMessage: 'Please enter your email.',
        labelText: 'Email',
        hintText: 'you@example.com',
        semanticsLabel: 'Email address',
        animate: false,
      ),
    );
  }
}
