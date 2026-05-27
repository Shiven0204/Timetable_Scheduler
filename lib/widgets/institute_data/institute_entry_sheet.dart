import 'package:flutter/material.dart';

/// Opens a modern bottom sheet for quick institute data entry.
Future<bool> showInstituteEntrySheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget Function(ScrollController scrollController) builder,
  required Future<bool> Function() onSubmit,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return _InstituteSheetShell(
              title: title,
              subtitle: subtitle,
              scrollController: scrollController,
              onSubmit: onSubmit,
              onClose: () => Navigator.pop(sheetContext, false),
              child: builder(scrollController),
            );
          },
        ),
      );
    },
  );
  return result ?? false;
}

class _InstituteSheetShell extends StatefulWidget {
  const _InstituteSheetShell({
    required this.title,
    required this.subtitle,
    required this.scrollController,
    required this.onSubmit,
    required this.onClose,
    required this.child,
  });

  final String title;
  final String subtitle;
  final ScrollController scrollController;
  final Future<bool> Function() onSubmit;
  final VoidCallback onClose;
  final Widget child;

  @override
  State<_InstituteSheetShell> createState() => _InstituteSheetShellState();
}

class _InstituteSheetShellState extends State<_InstituteSheetShell> {
  bool _loading = false;

  Future<void> _handleNext() async {
    setState(() => _loading = true);
    try {
      final success = await widget.onSubmit();
      if (!mounted) return;
      if (success && context.mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: widget.child,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _handleNext,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('NEXT'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
