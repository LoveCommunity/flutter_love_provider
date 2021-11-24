import 'package:flutter/material.dart';
import 'package:flutter_love_provider/flutter_love_provider.dart';
import 'package:provider/provider.dart';

// typedef CounterState = int;

abstract class CounterEvent {}
class Increment implements CounterEvent {}
class Decrement implements CounterEvent {}

System<int, CounterEvent> createCounterSystem() {
  return System<int, CounterEvent>
    .create(initialState: 0)
    .on<Increment>(
      reduce: (state, event) => state + 1,
      effect: (state, event, dispatch) async {
        await Future.delayed(const Duration(seconds: 3));
        dispatch(Decrement());
      },
    )
    .on<Decrement>(
      reduce: (state, event) => state - 1,
    )
    .log()
    .reactState(
      effect: (state, dispatch) {
        // ignore: avoid_print
        print('Simulate persistence save call with state: $state');
      },
    );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: UseSystemProvidersPage(),
    );
  }
}

class UseSystemProvidersPage extends StatelessWidget {
  const UseSystemProvidersPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SystemProviders(
      create: (_) => createCounterSystem(),
      builder: (context, _) {
        final state = context.watch<int>(); // <- access state
        return CounterPage(
          title: 'Use System Providers Page',
          count: state,
          onIncreasePressed: () => context
            .dispatch<CounterEvent>(Increment()), // <- access dispatch
        );
      },
    );
  }
}

class CounterPage extends StatelessWidget {

  const CounterPage({
    Key? key,
    required this.title,
    required this.count,
    required this.onIncreasePressed,
  }) : super(key: key);

  final String title;
  final int count;
  final VoidCallback onIncreasePressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onIncreasePressed,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}