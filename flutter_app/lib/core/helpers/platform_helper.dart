import 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart'
    if (dart.library.html) 'platform_helper_web.dart';

bool get isAndroid => platformIsAndroid;
bool get isIOS => platformIsIOS;
bool get isMobilePlatform => isAndroid || isIOS;
