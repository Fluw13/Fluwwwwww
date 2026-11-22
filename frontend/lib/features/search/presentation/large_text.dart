import 'package:flutter/widgets.dart';

/// Above Material's 130% cap for fixed-height bars, side-by-side columns stop fitting on a 320 dp phone; layouts stack
/// them instead.
bool usesLargeText(BuildContext context) => MediaQuery.textScalerOf(context).scale(1) > 1.3;
