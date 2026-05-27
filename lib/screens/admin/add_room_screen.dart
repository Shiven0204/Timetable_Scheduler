import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/utils/room_type_utils.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({
    this.embeddedInDialog = false,
    super.key,
  });

  final bool embeddedInDialog;

  @override
  State<AddRoomScreen> createState() => AddRoomScreenState();
}

class AddRoomScreenState extends State<AddRoomScreen> {
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

  Future<bool> submit() async {
    final name = _nameController.text.trim();
    final building = _buildingController.text.trim();
    final capacityText = _capacityController.text.trim();

    if (name.isEmpty) {
      _showSnack('Room name is required');
      return false;
    }
    if (_roomType == null) {
      _showSnack('Select a room type');
      return false;
    }

    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      _showSnack('Enter a valid capacity (greater than 0)');
      return false;
    }

    setState(() => _saving = true);
    try {
      await _dbService.saveRoom(
        name: name,
        roomType: _roomType!,
        capacity: capacity,
        buildingName: building.isEmpty ? null : building,
      );
      if (!mounted) return false;
      if (!widget.embeddedInDialog) {
        _showSnack('Room saved successfully');
      }
      _nameController.clear();
      _buildingController.clear();
      _capacityController.clear();
      setState(() => _roomType = null);
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnack('Error: $e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildForm() {
    return InstituteFormCard(
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
              'Building Name',
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDialog) {
      return _buildForm();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : submit,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('NEXT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
