import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {

  final _roomNameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  String? _roomType;

  final List<String> _roomTypes = ['Classroom', 'Lab'];

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final name = _roomNameController.text.trim();

    if (name.isEmpty || _roomType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    try {
      await _dbService.saveRoom(
        roomName: name,
        roomType: _roomType!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room saved')),
      );

      _roomNameController.clear();

      setState(() {
        _roomType = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextField(
              controller: _roomNameController,
              decoration: _decoration('Room Name'),
            ),
            const SizedBox(height: 16),

            InputDecorator(
              decoration: _decoration('Room Type'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _roomType,
                  hint: const Text('Select type'),
                  items: _roomTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _roomType = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}