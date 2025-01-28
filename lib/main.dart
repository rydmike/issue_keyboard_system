import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const KeyboardListenerComparisonApp());

// Check if this is a Web-WASM build, Web-JS build or native VM build.
const bool isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const String buildType = isRunningWithWasm
    ? '(WASM build)'
    : kIsWeb
        ? '(JS build)'
        : '(VM build)';

class KeyboardListenerComparisonApp extends StatelessWidget {
  const KeyboardListenerComparisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const KeyboardListenerDemo(),
      ),
    );
  }
}

class KeyboardListenerDemo extends StatefulWidget {
  const KeyboardListenerDemo({super.key});

  @override
  State<KeyboardListenerDemo> createState() => _KeyboardListenerDemoState();
}

class _KeyboardListenerDemoState extends State<KeyboardListenerDemo> {
  final List<String> _rawEvents = [];
  final List<String> _newEvents = [];
  late final FocusNode _rawFocusNode;
  late final FocusNode _newFocusNode;
  bool _useNewListener = false;

  @override
  void initState() {
    super.initState();
    _rawFocusNode = FocusNode(debugLabel: 'RawKeyboardListener');
    _newFocusNode = FocusNode(debugLabel: 'KeyboardListener');
    _rawFocusNode.addListener(_handleFocusChange);
    _newFocusNode.addListener(_handleFocusChange);
    _rawFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _rawFocusNode.removeListener(_handleFocusChange);
    _newFocusNode.removeListener(_handleFocusChange);
    _rawFocusNode.dispose();
    _newFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  void _clearEvents() {
    setState(() {
      _rawEvents.clear();
      _newEvents.clear();
    });
  }

  void _switchListener(bool useNew) {
    setState(() => _useNewListener = useNew);
    if (useNew) {
      _newFocusNode.requestFocus();
      _rawFocusNode.unfocus();
    } else {
      _rawFocusNode.requestFocus();
      _newFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Keyboard Listeners Comparison $buildType'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearEvents,
              tooltip: 'Clear all events',
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              _buildListenerColumn(
                context: context,
                title: 'RawKeyboardListener',
                events: _rawEvents,
                isActive: _rawFocusNode.hasFocus,
                onTap: () => _switchListener(false),
              ),
              _buildListenerColumn(
                context: context,
                title: 'KeyboardListener',
                events: _newEvents,
                isActive: _newFocusNode.hasFocus,
                onTap: () => _switchListener(true),
              ),
            ],
          ),
        ),
        // Raw Keyboard Events (Legacy)
        if (!_useNewListener)
          Focus(
            focusNode: _rawFocusNode,
            onKey: (FocusNode node, RawKeyEvent event) {
              if (event is RawKeyDownEvent || event is RawKeyUpEvent) {
                _handleKeyEvent(event, isNew: false);
              }
              return KeyEventResult.handled; // Suppress system sounds
            },
            child: const SizedBox.shrink(),
          ),
        // New Keyboard Events
        if (_useNewListener)
          Focus(
            focusNode: _newFocusNode,
            onKeyEvent: (FocusNode node, KeyEvent event) {
              _handleKeyEvent(event, isNew: true);
              return KeyEventResult.handled; // Suppress system sounds
            },
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }

  void _handleKeyEvent(dynamic event, {required bool isNew}) {
    final timeStamp = DateTime.now().toIso8601String().substring(11, 23);
    final entry = '[${event.runtimeType}] ${event.logicalKey} ($timeStamp)';

    setState(() {
      if (isNew) {
        _newEvents.add(entry);
      } else {
        _rawEvents.add(entry);
      }
    });
  }

  Widget _buildListenerColumn({
    required BuildContext context,
    required String title,
    required List<String> events,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: events.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          events.reversed.elementAt(index),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
