import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/foundation.dart';

void main() => runApp(const MinuteKeeperApp());

class MinuteKeeperApp extends StatelessWidget {
  const MinuteKeeperApp({super.key, this.platform});

  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const CupertinoApp(
          title: 'Minute Keeper',
          home: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Minute Keeper'),
            ),
            child: SafeArea(
              child: Center(child: Text('Your private meeting space')),
            ),
          ),
        );
      case TargetPlatform.windows:
        return fluent.FluentApp(
          title: 'Minute Keeper',
          home: fluent.NavigationView(
            titleBar: const fluent.TitleBar(title: Text('Minute Keeper')),
            content: const fluent.ScaffoldPage(
              content: Center(child: Text('Your private meeting space')),
            ),
          ),
        );
      default:
        return material.MaterialApp(
          title: 'Minute Keeper',
          theme: material.ThemeData(useMaterial3: true),
          home: material.Scaffold(
            appBar: material.AppBar(title: const Text('Minute Keeper')),
            body: const Center(child: Text('Your private meeting space')),
          ),
        );
    }
  }
}
