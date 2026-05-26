import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/utils/room_type_utils.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  static const Map<String, String> _roomTypeLabels = {
    RoomTypeUtils.classroom: 'Classroom',
    RoomTypeUtils.lab: 'Lab',
  };

  final _nameController = TextEditingController();
  final _buildingController = TextEditingController();
  final _capacityController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  String? _roomType;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final building = _buildingController.text.trim();
    final capacityText = _capacityController.text.trim();

    if (name.isEmpty) {
      _showSnack('Room name is required');
      return;
    }
    if (_roomType == null) {
      _showSnack('Select a room type');
      return;
    }

    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      _showSnack('Enter a valid capacity (greater than 0)');
      return;
    }

    setState(() => _saving = true);
    try {
      await _dbService.saveRoom(
        name: name,
        roomType: _roomType!,
        capacity: capacity,
        buildingName: building.isEmpty ? null : building,
      );
      if (!mounted) return;
      _showSnack('Room saved successfully');
      _nameController.clear();
      _buildingController.clear();
      _capacityController.clear();
      setState(() => _roomType = null);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: InstituteFormCard(
          title: 'Room details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: instituteInputDecoration('Room Name *'),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: instituteInputDecoration('Room Type *'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _roomType,
                    hint: const Text('Select room type'),
                    items: _roomTypeLabels.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _roomType = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _buildingController,
                textCapitalization: TextCapitalization.words,
                decoration: instituteInputDecoration(
                  'Building name',
                  hint: 'e.g. Block A',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: instituteInputDecoration('Capacity *'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _onSave,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save room'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
