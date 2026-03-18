import 'package:flutter/foundation.dart';

abstract class FallbackAwareRepository {
  ValueListenable<bool> get isUsingFallbackData;
}
