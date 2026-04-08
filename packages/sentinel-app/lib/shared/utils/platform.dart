import 'package:flutter/foundation.dart';

bool get isWeb => kIsWeb;
bool get isNative => !kIsWeb;
bool get supportsLan => !kIsWeb;
bool get supportsBiometric => !kIsWeb;
