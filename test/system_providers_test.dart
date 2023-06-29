// ignore_for_file: non_constant_identifier_names
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_love_provider/flutter_love_provider.dart';

void main() {

  group('SystemProviders.default', () {

    testWidgets('provide state, states and dispatch', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        provideState: true,
        provideStates: true,
        provideDispatch: true,
        child: Builder(builder: (context) {
          final _ = context.watch<String>();
          final __ = context.read<Stream<String>>();
          final ___ = context.read<Dispatch<String>>();
          return Container();
        }),
      ));

      // expect not throws
    });

    testWidgets('not provide state', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        provideState: false,
        provideStates: true,
        provideDispatch: true,
        child: Builder(builder: (context) {
          final _ = context.watch<String>();
          return Container();
        },),
      ));

      expect(
        tester.takeException(),
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<String>')
          )
      );
    });

    testWidgets('not provide states', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        provideState: true,
        provideStates: false,
        provideDispatch: true,
        child: Builder(builder: (context) {
          final _ = context.read<Stream<String>>();
          return Container();
        },),
      ));

      expect(
        tester.takeException(),
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<Stream<String>>')
          )
      );
    });

    testWidgets('not provide dispatch', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        provideState: true,
        provideStates: true,
        provideDispatch: false,
        child: Builder(builder: (context) {
          final _ = context.read<Dispatch<String>>();
          return Container();
        },),
      ));

      expect(
        tester.takeException(),
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<Dispatch<String>>')
          )
      );
    });

    testWidgets('provide nothing throws assertion error', (tester) async {

      expect(
        () {
          SystemProviders(
            create: (_) => createSystem(),
            provideState: false,
            provideStates: false,
            provideDispatch: false,
            child: Container(),
          );
        },
        throwsA(
          isA<AssertionError>()
            .having(
              (error) => error.toString(),
              'description',
              contains('SystemProviders should at least provide one of `state`, `states` or `dispatch`')
            )
        )
      );
    });
    
    testWidgets('default provides state and dispatch', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        child: Builder(builder: (context) {
          final _ = context.watch<String>();
          final __ = context.read<Dispatch<String>>();
          return Container();
        },),
      ));

      // expect not throw exception
    });
    
    testWidgets('default not provide states', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        child: Builder(builder: (context) {
          final _ = context.read<Stream<String>>();
          return Container();
        },),
      ));

      expect(
        tester.takeException(),
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<Stream<String>>')
          )
      );
    });
    
    testWidgets('state updates', (tester) async {

      final states = <String>[];

      late Dispatch<String> dispatch;

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem()
          .onRun(effect: (_, localDispatch) { 
            dispatch = localDispatch;
            return null; 
          }),
        child: Builder(builder: (context) {
          final state = context.watch<String>();
          states.add(state);
          return Text(state, textDirection: TextDirection.ltr,);
        },),
      ));

      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('b');
      await tester.pump();

      expect(states, [
        'a',
        'a|b',
      ]);
      expect(find.text('a|b'), findsOneWidget);

    });
    
    testWidgets('default state equals', (tester) async {

      final states = <String>[];

      late Dispatch<String> dispatch;

      System<String, String> create(BuildContext _) {
        return System<String, String>
          .create(initialState: 'a')
          .add(reduce: (_, event) => event)
          .onRun(effect: (_, localDispatch) { 
            dispatch = localDispatch;
            return null; 
          });
      }

      await tester.pumpWidget(SystemProviders(
        create: create,
        child: Builder(builder: (context) {
          final state = context.watch<String>();
          states.add(state);
          return Text(state, textDirection: TextDirection.ltr,);
        },),
      ));

      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('a');
      await tester.pump();

      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('b');
      await tester.pump();

      expect(states, [
        'a',
        'b',
      ]);
      expect(find.text('b'), findsOneWidget);

    });
    
    testWidgets('custom state equals', (tester) async {

      final states = <String>[];
      int equalsInvoked = 0;

      late Dispatch<String> dispatch;

      System<String, String> create(BuildContext _) {
        return System<String, String>
          .create(initialState: 'a')
          .add(reduce: (_, event) => event)
          .onRun(effect: (_, localDispatch) { 
            dispatch = localDispatch;
            return null; 
          });
      }

      await tester.pumpWidget(SystemProviders<String, String>(
        create: create,
        stateEquals: (it1, it2) {
          equalsInvoked += 1;
          return it1.length == it2.length;
        },
        child: Builder(builder: (context) {
          final state = context.watch<String>();
          states.add(state);
          return Text(state, textDirection: TextDirection.ltr);
        }),
      ));

      expect(equalsInvoked, 0);
      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('a');
      await tester.pump();

      expect(equalsInvoked, 1);
      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('b');
      await tester.pump();

      expect(equalsInvoked, 2);
      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);
      
      dispatch('ab');
      await tester.pump();

      expect(equalsInvoked, 3);
      expect(states, [
        'a',
        'ab',
      ]);
      expect(find.text('ab'), findsOneWidget);
    });

    testWidgets('builder', (tester) async {

      await tester.pumpWidget(SystemProviders(
        create: (_) => createSystem(),
        builder: (context, _) {
          final state = context.watch<String>();
          return Text(state, textDirection: TextDirection.ltr,);
        },
      ));

      expect(find.text('a'), findsOneWidget);
    });
  });
  
  group('SystemProviders.value', () {

    testWidgets('provides state, states and dispatch', (tester) async {

      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        provideState: true,
        provideStates: true,
        provideDispatch: true,
        child: Builder(builder: (context) {
          final _ = context.watch<String>();
          final __ = context.read<Stream<String>>();
          final ___ = context.read<Dispatch<String>>();
          return Container();
        },),
      ));

      // expect not throws
    });

    testWidgets('not provide state', (tester) async {

      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        provideState: false,
        provideStates: true,
        provideDispatch: true,
        child: Builder(builder: (context) {
          final _ = context.watch<String>();
          return Container();
        },),
      ));

      expect(
        tester.takeException(), 
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<String>')
          )
      );
    });
    
    testWidgets('not provide states', (tester) async {
      
      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        provideState: true,
        provideStates: false,
        provideDispatch: true,
        child: Builder(builder: (context) {
          final _ = context.read<Stream<String>>();
          return Container();
        }),
      ));

      expect(
        tester.takeException(), 
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<Stream<String>>')
          )
      );
    });

    testWidgets('not provide dispatch', (tester) async {

      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        provideState: true,
        provideStates: true,
        provideDispatch: false,
        child: Builder(builder: (context) {
          final _ = context.read<Dispatch<String>>();
          return Container();
        },),
      ));

      expect(
        tester.takeException(), 
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description',
            contains('Could not find the correct Provider<Dispatch<String>>')
          )
      );
    });
    
    testWidgets('provide nothing throws assertion error', (tester) async {

      expect(
        () {
          SystemProviders.value(
            value: createSystem(),
            provideState: false,
            provideStates: false,
            provideDispatch: false,
            child: Container(),
          );
        },
        throwsA(
          isA<AssertionError>()
            .having(
              (error) => error.toString(),
              'description',
              contains('SystemProviders should at least provide one of `state`, `states` or `dispatch`'),
            ),
        ));
    });

    testWidgets('default provides state and dispatch', (tester) async {

      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        child: Builder(builder: (context) {
          final _ = context.watch<String>();
          final __ = context.read<Dispatch<String>>(); 
          return Container();
        }),
      ));

      // expect not throw exception
    });

    testWidgets('default not provide states', (tester) async {

      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        child: Builder(builder: (context) {
          final _ = context.read<Stream<String>>();
          return Container();
        }),
      ));

      expect(
        tester.takeException(), 
        isInstanceOf<ProviderNotFoundException>()
          .having(
            (exception) => exception.toString(),
            'description', 
            contains('Could not find the correct Provider<Stream<String>>'),
          ),
      );
    });

    testWidgets('state updates', (tester) async {

      final states = <String>[];

      late Dispatch<String> dispatch;

      final system = createSystem()
        .onRun(effect: (_, localDispatch) { 
          dispatch = localDispatch;
          return null; 
        });
      
      await tester.pumpWidget(SystemProviders.value(
        value: system,
        child: Builder(builder: (context) {
          final state = context.watch<String>();
          states.add(state);
          return Text(state, textDirection: TextDirection.ltr,);
        },),
      ));

      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('b');
      await tester.pump();

      expect(states, [
        'a',
        'a|b',
      ]);
      expect(find.text('a|b'), findsOneWidget);
    });

    testWidgets('default state equals', (tester) async {

      final states = <String>[];

      late Dispatch<String> dispatch;

      final system = System<String, String>
        .create(initialState: 'a')
        .add(reduce: (_, event) => event)
        .onRun(effect: (_, localDispatch) { 
          dispatch = localDispatch;
          return null; 
        });

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        child: Builder(builder: (context) {
          final state = context.watch<String>();
          states.add(state);
          return Text(state, textDirection: TextDirection.ltr,);
        }),
      ));

      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('a');
      await tester.pump();

      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('b');
      await tester.pump();

      expect(states, [
        'a',
        'b'
      ]);
      expect(find.text('b'), findsOneWidget);

    });

    testWidgets('custom state equals', (tester) async {

      final states = <String>[];
      int equalsInvoked = 0;

      late Dispatch<String> dispatch;

      final system = System<String, String>
        .create(initialState: 'a')
        .add(reduce: (_, event) => event)
        .onRun(effect: (_, localDispatch) { 
          dispatch = localDispatch;
          return null; 
        });

      await tester.pumpWidget(SystemProviders<String, String>.value(
        value: system,
        stateEquals: (it1, it2) {
          equalsInvoked += 1;
          return it1.length == it2.length;
        },
        child: Builder(builder: (context) {
          final state = context.watch<String>();
          states.add(state);
          return Text(state, textDirection: TextDirection.ltr,);
        }),
      ));

      expect(equalsInvoked, 0);
      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('a');
      await tester.pump();

      expect(equalsInvoked, 1);
      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('b');
      await tester.pump();

      expect(equalsInvoked, 2);
      expect(states, ['a']);
      expect(find.text('a'), findsOneWidget);

      dispatch('ab');
      await tester.pump();

      expect(equalsInvoked, 3);
      expect(states, [
        'a',
        'ab',
      ]);
      expect(find.text('ab'), findsOneWidget);

    });

    testWidgets('builder', (tester) async {

      final system = createSystem();

      await tester.pumpWidget(SystemProviders.value(
        value: system,
        builder: (context, _) {
          final state = context.watch<String>();
          return Text(state, textDirection: TextDirection.ltr,);
        },
      ));

      expect(find.text('a'), findsOneWidget);
    });
    
  });

}

System<String, String> createSystem() {
  return System<String, String>
    .create(initialState: 'a')
    .add(reduce: reduce);
}

String reduce(String state, String event)
  => '$state|$event';