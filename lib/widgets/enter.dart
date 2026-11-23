import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/tokens.dart';

/// One entrance, used everywhere: a short rise + fade, staggered by [order].
/// Respects the system "remove animations" setting.
extension Enter on Widget {
  Widget enter(BuildContext context, int order) {
    if (MediaQuery.disableAnimationsOf(context)) return this;
    return animate()
        .fadeIn(duration: Motion.slow, delay: (70 * order).ms, curve: Motion.curve)
        .moveY(begin: 18, end: 0, duration: Motion.slow, delay: (70 * order).ms, curve: Motion.curve);
  }
}
