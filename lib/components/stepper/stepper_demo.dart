// Demo/usage example for StepFlow (react-bits "Stepper"). Exempt from
// portability rules (§3.1.9); also serves as the copy-paste usage reference.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'stepper.dart';

final ComponentDemo stepperDemo = ComponentDemo(
  id: 'stepper',
  builder: (context) => const _StepFlowShowcase(),
  // Static mock of the card at step 1 — no controllers, no implicit
  // animations running in the gallery grid.
  thumbnailBuilder: (context) => const _StepFlowThumbnail(),
);

/// 4-step onboarding flow like the react-bits docs example, plus a status
/// line fed by the callbacks.
class _StepFlowShowcase extends StatefulWidget {
  const _StepFlowShowcase();

  @override
  State<_StepFlowShowcase> createState() => _StepFlowShowcaseState();
}

class _StepFlowShowcaseState extends State<_StepFlowShowcase> {
  String _status = 'Step 1 of 4';
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static Widget _heading(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      );

  static Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 15),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              StepFlow(
                initialStep: 1,
                onStepChange: (step) =>
                    setState(() => _status = 'Step $step of 4'),
                onFinalStepCompleted: () =>
                    setState(() => _status = 'All steps completed!'),
                steps: <Widget>[
                  // Step 1
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _heading('Welcome to the StepFlow demo!'),
                      _body('Check out the next step!'),
                    ],
                  ),
                  // Step 2 — gradient block standing in for the docs image
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _heading('Step 2'),
                      Container(
                        height: 100,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF5227FF),
                              Color(0xFF060010),
                            ],
                          ),
                        ),
                      ),
                      _body('Custom step content!'),
                    ],
                  ),
                  // Step 3 — text input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _heading('How about an input?'),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextField(
                          controller: _name,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Your name?',
                            hintStyle:
                                const TextStyle(color: Color(0xFF6B6B6B)),
                            filled: true,
                            fillColor: const Color(0xFF16121E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Step 4
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _heading('Final Step'),
                      _body('You made it!'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static replica of the card at step 1 (active dot on indicator 1, empty
/// connectors, first step content, Continue pill) — plain containers only.
class _StepFlowThumbnail extends StatelessWidget {
  const _StepFlowThumbnail();

  Widget _indicator({required bool active, required String number}) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF5227FF) : const Color(0xFF222222),
      ),
      child: active
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF120F17),
              ),
            )
          : Text(
              number,
              style: const TextStyle(
                color: Color(0xFFA3A3A3),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: <Widget>[
                      _indicator(active: true, number: '1'),
                      for (int i = 2; i <= 4; i++) ...<Widget>[
                        Expanded(
                          child: Container(
                            height: 2,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF525252),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        _indicator(active: false, number: '$i'),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Welcome to the StepFlow demo!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Check out the next step!',
                          style: TextStyle(
                            color: Color(0xFFA3A3A3),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
