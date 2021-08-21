# assistive_touch

<p align="center">
<a href="https://pub.dev/packages/assistive_touch"><img src="https://img.shields.io/pub/v/assistive_touch.svg" alt="Pub"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/iendeavor/assistive_touch/main/example/screenshot.png" alt="Example Screenshot" height="500">
</p>

## Getting Started

Install the package

```sh
flutter pub add assistive_touch
```

Import the package

```dart
import 'package:assistive_touch/assistive_touch.dart';
```

Create a basic counter page:

```dart
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
```

Move the Floating Action Button to AssistiveTouch:

```dart
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Wrap with a [Stack] widget first
    return Stack(
      children: [
        Scaffold(
          // ...
        ),
        AssistiveTouch(
          // move floatingActionButton here
          child: FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        )
      ],
    );
  }
}
```

Now you have a draggable Floating Action Button!
