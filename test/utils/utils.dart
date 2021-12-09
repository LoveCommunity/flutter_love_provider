import 'package:flutter_love_provider/flutter_love_provider.dart';

System<String, String> createSystem() {
  return System<String, String>
    .create(initialState: 'a')
    .add(reduce: reduce);
}

String reduce(String state, String event)
  => '$state|$event';