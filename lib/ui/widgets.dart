import 'package:flutter/material.dart';
import 'theme.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final bool outlined;
  const SoftCard({super.key, required this.child,
    this.color = KitaColors.cream,
    this.padding = const EdgeInsets.all(22), this.outlined = true});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: color,
      borderRadius: BorderRadius.circular(25),
      border: outlined ? Border.all(color: KitaColors.border) : null,
      boxShadow: [BoxShadow(color: KitaColors.forestDeep.withValues(alpha: 0.045),
        offset: const Offset(0, 8), blurRadius: 26)]),
    padding: padding, child: child);
}

class SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const SectionTitle({super.key, required this.eyebrow,
    required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(eyebrow.toUpperCase(), style: const TextStyle(fontSize: 11,
        letterSpacing: 1.5, color: KitaColors.muted, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: KitaColors.muted)),
      ],
    ]);
}

class TextEntry extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? help;
  final String? suffix;
  final bool allowNegative;
  final VoidCallback? onHelp;
  final ValueChanged<String>? onChanged;
  const TextEntry({super.key, required this.controller, required this.label,
    this.hint, this.help, this.suffix, this.onHelp, this.onChanged,
    this.allowNegative = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: ExcludeSemantics(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700,
          color: KitaColors.ink, fontSize: 14)))),
        if (onHelp != null) IconButton(
          tooltip: 'How to find $label',
          onPressed: onHelp, icon: const Icon(Icons.help_outline_rounded,
            size: 20, color: KitaColors.forest)),
      ]),
      const SizedBox(height: 5),
      Semantics(label: label, child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
        textInputAction: TextInputAction.next,
        inputFormatters: const [],
        decoration: InputDecoration(hintText: hint, suffixText: suffix),
        onChanged: onChanged,
      )),
      if (help != null) ...[
        const SizedBox(height: 6),
        Text(help!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ]);
}

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const InfoBanner({super.key, required this.text,
    this.icon = Icons.info_outline_rounded, this.color = KitaColors.mint});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: KitaColors.ink),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
    ]),
  );
}

Future<void> showPlainHelp(BuildContext context, String title, String message) async {
  await showModalBottomSheet<void>(context: context, showDragHandle: true,
    isScrollControlled: true, useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(ctx).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(message, style: Theme.of(ctx).textTheme.bodyLarge),
        const SizedBox(height: 22),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
      ]),
    ));

}
