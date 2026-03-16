import 'package:flutter/widgets.dart';

extension MediaQuerySizeX on BuildContext {
  double get sizeOfHeight => MediaQuery.sizeOf(this).height;
  double get sizeOfWidth => MediaQuery.sizeOf(this).width;
}
