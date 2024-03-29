
import 'dart:async' show Stream, StreamController;
import 'package:love/love.dart' show System, Equals, Dispatch, Disposer, ReactX;
import 'package:flutter/widgets.dart' show Key, Widget, TransitionBuilder, BuildContext, Builder;
import 'package:nested/nested.dart' show SingleChildStatefulWidget, SingleChildState;
import 'package:provider/provider.dart' show Provider, StreamProvider, Create;

/// `SystemProviders` can consume a `System` then provide `state` and `dispatch` to descendant widgets.
/// 
/// `SystemProviders` will break the `System` into smaller units (`state`, `dispatch` etc.),
/// and provide these units to descendant.
/// 
/// Configurations:
/// 
/// ```dart
/// SystemProviders(
///   create: (context) => createSystem(), // A factory to create system, required.
///   provideState: true,    // Whether to provide `State`, default `true`.
///   provideStates: false,  // Whether to provide `Stream<State>`, default `false`.
///   provideDispatch: true, // Whether to provide `Dispatch<E>`, default `true`.
///   stateEquals: (it1, it2) => it1 == it2, // Whether new `state` are equal to old `state`. 
///                                          // New state will be emitted only if it's not equal to old state.
///                                          // defaults to `==`.
///   builder: (context, child) => ..., // widget builder, nullable.
///   child: SomeWidget(),              // child widget, nullable.
/// );
/// ```
/// 
/// Descendant widget can access `state` and `dispatch` from `context`:
///
/// ```dart
///
/// System<int, CounterEvent> createCounterSystem() { ... }
///
/// class UseSystemProvidersPage extends StatelessWidget {
///
///   @override
///   Widget build(BuildContext context) {
///     return SystemProviders(
///       create: (_) => createCounterSystem(),
///       builder: (context, _) {
///         final state = context.watch<int>(); // <- access state
///         return CounterPage(
///           title: 'Use System Providers Page',
///           count: state,
///           onIncreasePressed: () => context.dispatch<CounterEvent>(Increment()), // <- access dispatch
///         );
///       },
///     );
///   }
/// }
/// ```
/// 
class SystemProviders<S, E> extends SingleChildStatefulWidget {

  SystemProviders.value({
    Key? key,
    required System<S, E> value,
    bool provideState = true,
    bool provideStates = false,
    bool provideDispatch = true,
    Equals<S>? stateEquals,
    TransitionBuilder? builder,
    Widget? child,
  }) : this(
    key: key,
    create: (_) => value,
    provideState: provideState,
    provideStates: provideStates,
    provideDispatch: provideDispatch,
    stateEquals: stateEquals,
    builder: builder,
    child: child,
  );

  const SystemProviders({
    super.key,
    required this.create,
    this.provideState = true,
    this.provideStates = false,
    this.provideDispatch = true,
    this.stateEquals,
    this.builder,
    super.child,
  }) : assert(
    provideState || provideStates || provideDispatch, 
    'SystemProviders should at least provide one of `state`, `states` or `dispatch`'
  );

  final Create<System<S, E>> create;
  final bool provideState;
  final bool provideStates;
  final bool provideDispatch;
  final Equals<S>? stateEquals;
  final TransitionBuilder? builder;

  @override
  createState() {
    return _SystemProvidersState<S, E>();
  }
}

class _SystemProvidersState<S, E> extends SingleChildState<SystemProviders<S, E>> {

  late System<S, E> _system;
  late S _state;
  late final StreamController<S> _controller = StreamController.broadcast(sync: true);
  late final Stream<S> _states = _controller.stream;
  late Dispatch<E> _dispatch;
  late Disposer _disposer;

  @override
  void initState() {
    super.initState();
    _checkDebugCheckInvalidValueType(widget.provideStates);
    _createSystem();
    _runSystem();
  }

  @override
  void dispose() {
    _closeStream();
    _disposeSystem();
    super.dispose();
  }

  void _createSystem() {
    _system = widget.create(context);
  }

  void _runSystem() {
    _disposer = _system
      .reactState(
        equals: widget.stateEquals,
        skipInitialState: false,
        effect: _effect,
      ).run();
  }

  void _disposeSystem() {
    _disposer();
  }

  void _effect(S state, Dispatch<E> dispatch) {
    _state = state;
    _controller.add(state);
    _dispatch = dispatch;
  }

  void _closeStream() {
    _controller.close();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    Widget? localChild = widget.builder != null 
        ? Builder(builder: (context) => widget.builder!(context, child))
        : child;
    if (widget.provideDispatch) {
      localChild = Provider.value(
        value: _dispatch,
        child: localChild,
      );
    }
    if (widget.provideStates) {
      localChild = Provider.value(
        value: _states,
        child: localChild,
      );
    }
    if (widget.provideState) {
      localChild = StreamProvider.value(
        value: _states,
        initialData: _state,
        lazy: false,
        child: localChild,
      );
    }
    return localChild!;
  }
}

void Function<T>(T value)? _debugCheckInvalidValueType;

void _checkDebugCheckInvalidValueType(bool provideStates) {
  final debugCheckInvalidValueType = Provider.debugCheckInvalidValueType;
  if (debugCheckInvalidValueType != null && _debugCheckInvalidValueType == null && provideStates) {
    _debugCheckInvalidValueType = <T>(T value) {
      if (value is Stream) return;
      debugCheckInvalidValueType(value);
    };
    Provider.debugCheckInvalidValueType = _debugCheckInvalidValueType;
  }
}