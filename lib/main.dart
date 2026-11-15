import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_state.dart';
import 'core/finance.dart';
import 'ui/theme.dart';
import 'ui/quickcheck.dart';
import 'ui/history.dart';
import 'ui/settings.dart';
import 'ui/guide.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KitaBiyaheApp());
}

class KitaBiyaheApp extends StatefulWidget {
  const KitaBiyaheApp({super.key});
  @override
  State<KitaBiyaheApp> createState() => _KitaBiyaheAppState();
}

class _KitaBiyaheAppState extends State<KitaBiyaheApp> {
  late final Future<RiderAppState> _loading;
  @override
  void initState() {
    super.initState();
    _loading = RiderAppState.initialize();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KitaBiyahe — QuickCheck',
    debugShowCheckedModeBanner: false,
    theme: kitaTheme(),
    home: FutureBuilder<RiderAppState>(
      future: _loading,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: KitaColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your saved records need attention',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'The app did not overwrite unreadable data. Keep the app data files and restore a valid backup before continuing.',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        '${snap.error}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeShell(state: snap.data!);
      },
    ),
  );
}

class HomeShell extends StatefulWidget {
  final RiderAppState state;
  const HomeShell({super.key, required this.state});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;
  ShiftRecord? editRecord;
  GlobalKey<QuickCheckPageState> calculatorKey =
      GlobalKey<QuickCheckPageState>();
  bool draftDirty = false;

  Future<void> _edit(ShiftRecord record) async {
    if (!await _mayDiscard('edit a saved shift') || !mounted) return;
    _resetCalculator(record);
  }

  Future<bool> _mayDiscard(String action) async =>
      await calculatorKey.currentState?.confirmDiscard(action: action) ?? true;

  Future<void> _newShift() async {
    if (!await _mayDiscard('start a new shift') || !mounted) return;
    _resetCalculator();
  }

  void _resetCalculator([ShiftRecord? record]) => setState(() {
    editRecord = record;
    calculatorKey = GlobalKey<QuickCheckPageState>();
    draftDirty = false;
    selected = 0;
  });

  void _saveFinished() => setState(() {
    editRecord = null;
    calculatorKey = GlobalKey<QuickCheckPageState>();
    draftDirty = false;
  });

  void _select(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    final dirty = calculatorKey.currentState?.hasUnsavedChanges ?? draftDirty;
    if (value == 0 && selected != 0 && editRecord == null && !dirty) {
      _resetCalculator();
      return;
    }
    setState(() => selected = value);
  }

  Future<void> _back() async {
    if (selected != 0) {
      _select(0);
    } else if (await _mayDiscard('close KitaBiyahe') && mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final desktop = MediaQuery.sizeOf(context).width >= 880;
        final icons = [
          Icons.calculate_outlined,
          Icons.history_rounded,
          Icons.tune_rounded,
        ];
        final active = [
          Icons.calculate_rounded,
          Icons.history_rounded,
          Icons.tune_rounded,
        ];
        final labels = ['QuickCheck', 'History', 'Settings'];
        final content = IndexedStack(
          index: selected,
          children: [
            QuickCheckPage(
              key: calculatorKey,
              state: widget.state,
              editing: editRecord,
              onFinished: _saveFinished,
              onDirtyChanged: (dirty) {
                if (mounted && dirty != draftDirty) {
                  setState(() => draftDirty = dirty);
                }
              },
            ),
            selected == 1
                ? HistoryPage(
                    state: widget.state,
                    onEdit: _edit,
                    onNew: _newShift,
                  )
                : const SizedBox.shrink(),
            selected == 2
                ? SettingsPage(state: widget.state)
                : const SizedBox.shrink(),
          ],
        );
        return PopScope(
          canPop: selected == 0 && !draftDirty,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: desktop ? 84 : 70,
              titleSpacing: desktop ? 28 : 18,
              title: Row(
                children: [
                  Image.asset(
                    'assets/brand/mark.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KitaBiyahe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                            color: KitaColors.forest,
                          ),
                        ),
                        Text(
                          'QUICKCHECK',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                letterSpacing: 2.1,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (MediaQuery.sizeOf(context).width < 480)
                  IconButton(
                    tooltip: 'How it works',
                    icon: const Icon(Icons.auto_stories_outlined),
                    onPressed: () => showQuickGuide(
                      context,
                      reduceMotion: widget.state.settings.reduceMotion,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => showQuickGuide(
                      context,
                      reduceMotion: widget.state.settings.reduceMotion,
                    ),
                    icon: const Icon(Icons.auto_stories_outlined, size: 20),
                    label: Text(desktop ? 'How it works' : 'Guide'),
                  ),
                const SizedBox(width: 12),
              ],
            ),
            body: desktop
                ? Row(
                    children: [
                      Container(
                        width: 228,
                        color: KitaColors.cream,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            for (var i = 0; i < labels.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  selected: selected == i,
                                  selectedTileColor: KitaColors.mint,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  leading: Icon(
                                    selected == i ? active[i] : icons[i],
                                  ),
                                  title: Text(
                                    labels[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onTap: () => _select(i),
                                ),
                              ),
                            const Spacer(),
                            const Padding(
                              padding: EdgeInsets.all(18),
                              child: Text(
                                'Local-first · Private by default\nNo account required',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: KitaColors.muted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  )
                : content,
            bottomNavigationBar: desktop
                ? null
                : SafeArea(
                    top: false,
                    child: NavigationBar(
                      selectedIndex: selected,
                      onDestinationSelected: _select,
                      destinations: [
                        for (var i = 0; i < labels.length; i++)
                          NavigationDestination(
                            icon: Icon(icons[i]),
                            selectedIcon: Icon(active[i]),
                            label: labels[i],
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
