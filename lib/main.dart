import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:english_words/english_words.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  final title = 'Basic Desktop App';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  bool isMaximized = false;
  bool isMinimized = false;

  @override
  void initState() {
    windowManager.addListener(this);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    windowManager.isMaximized().then((value) {
      isMaximized = value;
      setState(() {});
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            windowManager.startDragging();
          },
          onDoubleTap: _maximizeUnmaximize,
          child: Text(widget.title),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.minimize),
            tooltip: 'Minimize',
            onPressed: _minimizeRestore,
          ),
          IconButton(
            icon: (!isMaximized
                ? const Icon(Icons.open_in_full)
                : const Icon(Icons.close_fullscreen)),
            tooltip: (!isMaximized ? 'Maximize' : 'Restore'),
            onPressed: _maximizeUnmaximize,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () {
              windowManager.close();
            },
          ),
        ],
      ),
      body: const DragToResizeArea(child: Center(child: RandomWords())),
    );
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
    // do something
  }

  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await windowManager.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _maximizeUnmaximize() async {
    isMaximized = await windowManager.isMaximized();
    setState(() {
      if (!isMaximized) {
        windowManager.maximize();
      } else {
        windowManager.unmaximize();
      }
    });
  }

  void _minimizeRestore() async {
    isMinimized = await windowManager.isMinimized();
    setState(() {
      if (!isMinimized) {
        windowManager.minimize();
      } else {
        windowManager.restore();
      }
    });
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    final wordPair = WordPair.random();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: /*1*/ (context, i) {
        if (i.isOdd) return const Divider(); /*2*/

        final index = i ~/ 2; /*3*/
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10)); /*4*/
        }
        return ListTile(
          title: Text(
            _suggestions[index].asPascalCase,
            style: _biggerFont,
          ),
        );
      },
    );
  }
}
