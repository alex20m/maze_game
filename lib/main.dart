import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';

import 'maze_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MazeGameApp(prefs: prefs));
}

class MazeGameApp extends StatelessWidget {
  const MazeGameApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  static const maxContentWidth = 800.0;
  static const completedLevelsKey = 'completed_levels';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maze Game',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: StartScreen.routeName,
      routes: {
        StartScreen.routeName: (context) => const _MaxWidthLayout(child: StartScreen()),
        LevelSelectionScreen.routeName: (context) =>
            _MaxWidthLayout(child: LevelSelectionScreen(prefs: prefs)),
        GameScreen.routeName: (context) => _MaxWidthLayout(child: const GameScreen()),
        ResultScreen.routeName: (context) =>
            _MaxWidthLayout(child: ResultScreen(prefs: prefs)),
      },
    );
  }
}

class _MaxWidthLayout extends StatelessWidget {
  const _MaxWidthLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > MazeGameApp.maxContentWidth;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MazeGameApp.maxContentWidth),
            child: child,
          ),
        );

        if (!isWide) {
          return content;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          body: content,
        );
      },
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Maze Game',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              Text(
                'Roll the ball through the maze and reach the exit!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(LevelSelectionScreen.routeName);
                },
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key, required this.prefs});

  static const routeName = '/levels';

  final SharedPreferences prefs;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  static const totalLevels = 3;
  late final List<bool> _completedLevels;

  @override
  void initState() {
    super.initState();
    final saved = widget.prefs.getStringList(MazeGameApp.completedLevelsKey);
    if (saved != null && saved.length == totalLevels) {
      _completedLevels = saved.map((e) => e == '1').toList();
    } else {
      _completedLevels = List<bool>.filled(totalLevels, false);
    }
  }

  void _refreshProgress() {
    final saved = widget.prefs.getStringList(MazeGameApp.completedLevelsKey);
    if (saved != null && saved.length == _completedLevels.length) {
      setState(() {
        for (var i = 0; i < _completedLevels.length; i++) {
          _completedLevels[i] = saved[i] == '1';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select level'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose a level. Completed levels are marked with a check.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isNarrow ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _completedLevels.length,
                itemBuilder: (context, index) {
                  final completed = _completedLevels[index];
                  final levelNumber = index + 1;
                  return Card(
                    color: completed
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          GameScreen.routeName,
                          arguments: GameScreenArgs(levelNumber: levelNumber),
                        );
                        _refreshProgress();
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Level $levelNumber',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (completed)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Completed'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreenArgs {
  GameScreenArgs({required this.levelNumber});

  final int levelNumber;
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static const routeName = '/game';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final levelNumber =
        args is GameScreenArgs ? args.levelNumber : 1; // default to level 1

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $levelNumber'),
      ),
      body: SafeArea(
        child: GameWidget<MazeGame>(
          game: MazeGame(
            levelNumber: levelNumber,
            onLevelFinished: (success) {
              Navigator.of(context).pushReplacementNamed(
                ResultScreen.routeName,
                arguments: ResultScreenArgs(
                  levelNumber: levelNumber,
                  success: success,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ResultScreenArgs {
  ResultScreenArgs({required this.levelNumber, required this.success});

  final int levelNumber;
  final bool success;
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.prefs});

  static const routeName = '/result';

  final SharedPreferences prefs;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late int _levelNumber;
  late bool _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ResultScreenArgs) {
      _levelNumber = args.levelNumber;
      _success = args.success;
      if (_success) {
        _saveProgress(_levelNumber);
      }
    } else {
      _levelNumber = 1;
      _success = false;
    }
  }

  Future<void> _saveProgress(int levelNumber) async {
    const totalLevels = _LevelSelectionScreenState.totalLevels;
    final existing =
        widget.prefs.getStringList(MazeGameApp.completedLevelsKey) ??
            List<String>.filled(totalLevels, '0');
    if (levelNumber - 1 >= 0 && levelNumber - 1 < existing.length) {
      existing[levelNumber - 1] = '1';
      await widget.prefs.setStringList(MazeGameApp.completedLevelsKey, existing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _success ? 'Level completed!' : 'Level failed';
    final message = _success
        ? 'You guided the ball to the exit.'
        : 'You did not reach the exit this time.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Level $_levelNumber',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(LevelSelectionScreen.routeName);
                },
                child: const Text('Back to levels'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

