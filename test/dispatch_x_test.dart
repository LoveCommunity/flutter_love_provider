
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_love_provider/flutter_love_provider.dart';

void main() {

  testWidgets('context.readDispatch', (tester) async {

    late Dispatch<String> dispatch1;
    late Dispatch<String> dispatch2;

    await tester.pumpWidget(Provider<Dispatch<String>>(
      create: (_) => Dispatch((_) {}),
      child: Builder(builder:  (context) {
        return GestureDetector(
          onTap: () {
            dispatch1 = context.read<Dispatch<String>>();
            dispatch2 = context.readDispatch<String>();
          },
          child: const ColoredBox(color: Color(0x00000000),),
        );
      }),
    ));

    await tester.tap(find.byType(ColoredBox));
    await tester.pump();

    expect(identical(dispatch1, dispatch2), true);

  });

  testWidgets('context.dispatch', (tester) async {

    final events = <String>[];

    final dispatch = Dispatch<String>((event) {
      events.add(event);
    });

    await tester.pumpWidget(Provider.value(
      value: dispatch,
      child: Builder(builder: (context) {
        return GestureDetector(
          onTap: () => context.dispatch<String>('a'),
          child: const ColoredBox(color: Color(0x00000000),),
        );
      }),
    ));

    expect(events, <String>[]);

    await tester.tap(find.byType(ColoredBox));
    await tester.pump();

    expect(events, ['a']);

  });
}
