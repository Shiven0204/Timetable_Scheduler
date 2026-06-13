import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/basic_information.dart';
import 'package:timetable_scheduler/screens/admin/basic_information_entries.dart';
import 'package:timetable_scheduler/services/basic_information_service.dart';

class BasicInformationScreen extends StatefulWidget {
  const BasicInformationScreen({super.key});

  @override
  State<BasicInformationScreen> createState() => _BasicInformationScreenState();
}

class _BasicInformationScreenState extends State<BasicInformationScreen> {
  final _service = BasicInformationService();
  BasicInformation? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await _service.load();
    if (!mounted) return;
    setState(() {
      _info = loaded ?? BasicInformation();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = scheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Information'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configure Timetable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap a card to open a quick-entry form',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (_info != null) ...[
                      const SizedBox(height: 16),
                      _SummaryCard(info: _info!),
                    ],
                    const SizedBox(height: 18),
                    _tile(
                      context,
                      'Timetable Details',
                      Icons.article_outlined,
                      BasicInformationEntries.openTimetableDetails,
                    ),
                    const SizedBox(height: 14),
                    _tile(
                      context,
                      'Bell Schedule',
                      Icons.schedule_outlined,
                      BasicInformationEntries.openBellSchedule,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    Future<void> Function(BuildContext, {VoidCallback? onSaved}) onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTap(context, onSaved: _load),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.add_circle_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.info});

  final BasicInformation info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = info.timetableName.trim().isEmpty
        ? 'Not configured'
        : info.timetableName.trim();
    final days = info.workingDays.length;
    final periods = info.scheduleMode == ScheduleMode.uniform
        ? info.periods.length
        : info.daySchedules.values
            .map((d) => d.periods.length)
            .fold(0, (a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
          color: scheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '$days working day${days == 1 ? '' : 's'} · $periods period${periods == 1 ? '' : 's'}/day · ${info.scheduleType.label}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
