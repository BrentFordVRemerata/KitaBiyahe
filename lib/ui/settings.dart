import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/android_backup_files.dart';
import '../core/finance.dart';
import '../core/repository.dart';
import 'widgets.dart';
import 'guide.dart';

class SettingsPage extends StatefulWidget {
  final RiderAppState state;
  const SettingsPage({super.key, required this.state});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late FuelUnit unit;
  late EfficiencySource source;
  late final TextEditingController efficiency;
  late final TextEditingController price;
  late final TextEditingController reserve;
  late bool reduceMotion;
  late bool useTaglish;

  @override
  void initState() {
    super.initState();
    final s = widget.state.settings;
    unit = s.fuelUnit;
    source = s.efficiencySource;
    efficiency = TextEditingController(
      text: s.efficiencyKmL == null
          ? ''
          : FuelMath.fromKmPerLiter(s.efficiencyKmL!, unit).toStringAsFixed(2),
    );
    price = TextEditingController(text: Peso.editable(s.fuelPriceCents));
    reserve = TextEditingController(text: Peso.editable(s.reservePerKmCents));
    reduceMotion = s.reduceMotion;
    useTaglish = s.useTaglish;
  }

  @override
  void dispose() {
    efficiency.dispose();
    price.dispose();
    reserve.dispose();
    super.dispose();
  }

  void notify(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> saveSettings() async {
    try {
      double? efficiencyKmL;
      if (efficiency.text.trim().isNotEmpty) {
        final number = double.parse(efficiency.text.trim());
        efficiencyKmL = FuelMath.kmPerLiter(number, unit);
        if (efficiencyKmL > 1000) {
          throw const FormatException('Fuel efficiency is unusually high.');
        }
      }
      final updated = RiderSettings(
        fuelUnit: unit,
        efficiencyKmL: efficiencyKmL,
        efficiencySource: source,
        fuelPriceCents: Peso.parse(price.text),
        reservePerKmCents: Peso.parse(reserve.text),
        reduceMotion: reduceMotion,
        useTaglish: useTaglish,
      );
      await widget.state.saveSettings(updated);
      if (mounted) {
        notify(
          'Motorcycle settings saved. Past shifts keep their recorded assumptions.',
        );
      }
    } catch (e) {
      if (mounted) notify('Please check your settings: $e');
    }
  }

  Future<void> importBackup() async {
    try {
      const filter = XTypeGroup(label: 'JSON backup', extensions: ['json']);
      final file = await openFile(acceptedTypeGroups: [filter]);
      if (file == null) return;
      if (await file.length() > BackupCodec.maxBackupBytes) {
        throw const FormatException('Choose a JSON backup of 1 MB or less.');
      }
      final content = await file.readAsString();
      if (!mounted) return;
      await _confirmImport(content);
    } catch (e) {
      if (mounted) notify('Could not open backup: $e');
    }
  }

  Future<void> pasteBackup() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) {
      if (mounted) notify('Clipboard contains no text.');
      return;
    }
    if (mounted) await _confirmImport(data!.text!);
  }

  Future<void> _confirmImport(String json) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import KitaBiyahe backup'),
        content: const Text(
          'Merge adds new shift IDs and keeps current settings. Replace overwrites all current shifts AND motorcycle settings. Make a backup first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('Merge shifts'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('Replace all'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    try {
      await widget.state.importJson(json, replace: choice == 'replace');
      if (!mounted) return;
      if (choice == 'replace') {
        final s = widget.state.settings;
        unit = s.fuelUnit;
        source = s.efficiencySource;
        efficiency.text = s.efficiencyKmL == null
            ? ''
            : FuelMath.fromKmPerLiter(
                s.efficiencyKmL!,
                unit,
              ).toStringAsFixed(2);
        price.text = Peso.editable(s.fuelPriceCents);
        reserve.text = Peso.editable(s.reservePerKmCents);
        reduceMotion = s.reduceMotion;
        useTaglish = s.useTaglish;
        setState(() {});
      }
      notify(
        choice == 'replace'
            ? 'Full backup restored.'
            : 'New shift records merged.',
      );
    } catch (e) {
      if (mounted) notify('Import rejected: $e');
    }
  }

  Future<void> exportBackup() async {
    try {
      final text = widget.state.exportJson();
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final name = 'kitabiyahe-backup-$stamp.json';
      if (Platform.isWindows) {
        final location = await getSaveLocation(
          suggestedName: name,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'JSON backup', extensions: ['json']),
          ],
        );
        if (location == null) return;
        await XFile.fromData(
          Uint8List.fromList(utf8.encode(text)),
          name: name,
          mimeType: 'application/json',
        ).saveTo(location.path);
        if (mounted) notify('JSON backup saved.');
        return;
      }
      if (Platform.isAndroid) {
        final saved = await AndroidBackupFiles.save(text, name);
        if (mounted) {
          notify(saved ? 'JSON backup saved.' : 'Backup save cancelled.');
        }
        return;
      }
      await shareBackup();
    } catch (e) {
      if (mounted) notify('Could not save backup: $e. Use Copy JSON instead.');
    }
  }

  Future<void> shareBackup() async {
    try {
      final text = widget.state.exportJson();
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final name = 'kitabiyahe-backup-$stamp.json';
      await SharePlus.instance.share(
        ShareParams(
          text:
              'KitaBiyahe local backup. Keep private: contains entered shift amounts.',
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(text)),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: [name],
        ),
      );
    } catch (e) {
      if (mounted) notify('Could not share backup: $e. Use Copy JSON instead.');
    }
  }

  Future<void> measureFuel() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final liters = TextEditingController();
    try {
      final calculated = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Measure my motorcycle km/L'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const InfoBanner(
                    text:
                        'Use two consecutive, consistent COMPLETE refills. Do not top up beyond the proper fill level. Record odometer readings and the liters at the SECOND refill.',
                  ),
                  const SizedBox(height: 15),
                  TextEntry(
                    controller: first,
                    label: 'Odometer at first full refill',
                    hint: '12500',
                    suffix: 'km',
                  ),
                  const SizedBox(height: 12),
                  TextEntry(
                    controller: second,
                    label: 'Odometer at next full refill',
                    hint: '12760',
                    suffix: 'km',
                  ),
                  const SizedBox(height: 12),
                  TextEntry(
                    controller: liters,
                    label: 'Liters added at second refill',
                    hint: '6.5',
                    suffix: 'L',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final answer = FuelMath.fromTwoFullRefills(
                    firstOdometer: double.parse(first.text),
                    secondOdometer: double.parse(second.text),
                    secondRefillLiters: double.parse(liters.text),
                  );
                  Navigator.pop(ctx, answer);
                } catch (_) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter valid readings and second refill liters. The second odometer must be higher.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Calculate'),
            ),
          ],
        ),
      );
      if (calculated != null && mounted) {
        setState(() {
          efficiency.text = FuelMath.fromKmPerLiter(
            calculated,
            unit,
          ).toStringAsFixed(2);
          source = EfficiencySource.measured;
        });
        notify(
          'Estimated ${calculated.toStringAsFixed(2)} km/L from one interval. Tap Save settings. Repeat readings for a more representative average.',
        );
      }
    } finally {
      // Form controllers belong to this dialog, not the persistent settings form.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      first.dispose();
      second.dispose();
      liters.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 38),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                eyebrow: 'Make it yours',
                title: 'Motorcycle & settings',
                subtitle:
                    'Saved values are suggestions for NEW shifts; old records never change.',
              ),
              const SizedBox(height: 22),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel efficiency units',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For Philippine riders, km/L is the simplest default. MPG (US), MPG (UK) and L/100 km are optional.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FuelUnit>(
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      initialValue: unit,
                      decoration: const InputDecoration(
                        labelText: 'Display fuel efficiency in',
                      ),
                      items: [
                        for (final u in FuelUnit.values)
                          DropdownMenuItem(value: u, child: Text(u.label)),
                      ],
                      onChanged: (newUnit) {
                        if (newUnit == null || newUnit == unit) return;
                        try {
                          if (efficiency.text.trim().isNotEmpty) {
                            final kml = FuelMath.kmPerLiter(
                              double.parse(efficiency.text),
                              unit,
                            );
                            efficiency.text = FuelMath.fromKmPerLiter(
                              kml,
                              newUnit,
                            ).toStringAsFixed(2);
                          }
                          setState(() => unit = newUnit);
                        } catch (_) {
                          setState(() {
                            unit = newUnit;
                            efficiency.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextEntry(
                      controller: efficiency,
                      label: 'My motorcycle fuel efficiency',
                      suffix: unit.label,
                      hint: unit == FuelUnit.kmPerLiter ? 'e.g. 40' : null,
                      help:
                          'Leave blank when unknown. Never assume a universal value.',
                      onHelp: () => showPlainHelp(
                        context,
                        'What is fuel efficiency?',
                        'km/L means kilometers your motorcycle goes per liter. Your manual may have a figure, but real traffic and loads can change it. Use Measure my km/L below for a practical estimate.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EfficiencySource>(
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      initialValue: source,
                      decoration: const InputDecoration(
                        labelText: 'How did you get this value?',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: EfficiencySource.unknown,
                          child: Text('Not sure'),
                        ),
                        DropdownMenuItem(
                          value: EfficiencySource.measured,
                          child: Text('From my own fuel readings'),
                        ),
                        DropdownMenuItem(
                          value: EfficiencySource.manufacturer,
                          child: Text('From the motorcycle manual'),
                        ),
                        DropdownMenuItem(
                          value: EfficiencySource.estimate,
                          child: Text('My rough estimate'),
                        ),
                      ],
                      onChanged: (v) => setState(() => source = v ?? source),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: measureFuel,
                      icon: const Icon(Icons.speed_rounded),
                      label: const Text('Measure my km/L step by step'),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (ctx, c) {
                        final wide = c.maxWidth > 550;
                        final widgets = [
                          TextEntry(
                            controller: price,
                            label: 'Fuel price per liter',
                            suffix: '₱/L',
                            hint: 'e.g. 65.00',
                            help: 'Use the current price at your gas station.',
                          ),
                          TextEntry(
                            controller: reserve,
                            label: 'Optional maintenance allowance',
                            suffix: '₱/km',
                            hint: 'Blank = not set',
                            help:
                                'A planning reserve, NOT actual spending today. Enter 0 to exclude.',
                          ),
                        ];
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: widgets[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: widgets[1]),
                                ],
                              )
                            : Column(
                                children: [
                                  widgets[0],
                                  const SizedBox(height: 14),
                                  widgets[1],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saveSettings,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save motorcycle settings'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rider-friendly help',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reduce animations'),
                      subtitle: const Text(
                        'Shorter transitions for motion sensitivity.',
                      ),
                      value: reduceMotion,
                      onChanged: (v) => setState(() => reduceMotion = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Taglish guides'),
                      subtitle: const Text(
                        'Keep friendly Filipino explanations (core financial terms remain defined).',
                      ),
                      value: useTaglish,
                      onChanged: (v) => setState(() => useTaglish = v),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          showQuickGuide(context, reduceMotion: reduceMotion),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: const Text('Replay the animated walkthrough'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap Save motorcycle settings above to keep these preferences.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Private records & backups',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 7),
                    const InfoBanner(
                      text:
                          'Data lives on this device. It is not synced to other phones or PCs. Export a private JSON backup before resetting, reinstalling, or changing phones.',
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        FilledButton.icon(
                          onPressed: exportBackup,
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Export JSON backup'),
                        ),
                        if (Platform.isAndroid)
                          OutlinedButton.icon(
                            onPressed: shareBackup,
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share JSON backup'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: widget.state.exportJson()),
                            );
                            if (mounted) {
                              notify(
                                'JSON copied. Paste it into a private, secure file; keep it confidential.',
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy JSON'),
                        ),
                        OutlinedButton.icon(
                          onPressed: importBackup,
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('Import backup file'),
                        ),
                        TextButton.icon(
                          onPressed: pasteBackup,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Import pasted JSON'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Import accepts native KitaBiyahe JSON and supported V2.3 web JSON exports. It does not read another browser’s storage automatically.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),
              Text(
                'KitaBiyahe QuickCheck · Local shift records',
                textAlign: narrow ? TextAlign.left : TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
