import 'package:flutter/cupertino.dart';
import 'package:playx_localization/playx_localization.dart';

class PlayxInheritedLocalization extends InheritedWidget {
  final XLocale locale;
  const PlayxInheritedLocalization({
    super.key,
    required this.locale,
    required super.child,
  });

  static PlayxInheritedLocalization? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PlayxInheritedLocalization>();
  }

  static PlayxInheritedLocalization of(BuildContext context) {
    final res = maybeOf(context);
    if (res == null) {
      throw Exception(
        'PlayxInheritedLocalization not found in context. Make sure PlayxLocalizationBuilder is above the widget tree.',
      );
    }
    return res;
  }

  @override
  bool updateShouldNotify(PlayxInheritedLocalization oldWidget) {
    return oldWidget.locale != locale;
  }
}
