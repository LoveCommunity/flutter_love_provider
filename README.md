# flutter_love_provider

`flutter_love_provider` provide flutter widgets for supporting solution base on flutter, [love] and provider.

## SystemProviders

**`SystemProviders` can consume a `System` then provide `state` and `dispatch` to descendant widgets.**

Descendant widget can access `state` and `dispatch` from `context`:

```dart

System<int, CounterEvent> createCounterSystem() { ... }

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

```

## License

The MIT License (MIT)

[love]:https://pub.dev/packages/love