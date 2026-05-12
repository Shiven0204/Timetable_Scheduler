import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {

  static const _roomTypes = ['Classroom', 'Lab'];

  final _roomNameController = TextEditingController();
  final _capacityController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  String? _roomType;

  @override
  void dispose() {
    _roomNameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _onSave() async {

    final roomName = _roomNameController.text.trim();
    final capacityText = _capacityController.text.trim();

    if (roomName.isEmpty ||
        capacityText.isEmpty ||
        _roomType == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    int? capacity = int.tryParse(capacityText);

    if (capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid capacity')),
      );
      return;
    }

    try {

      await _dbService.saveRoom(
        roomName: roomName,
        roomType: _roomType!,
        capacity: capacity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room saved successfully')),
      );

      _roomNameController.clear();
      _capacityController.clear();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Text(
                  'Room Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

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
                      hint: const Text('Select room type'),
                      items: _roomTypes.map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
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

                const SizedBox(height: 16),

                TextField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Capacity'),
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
        ),
      ),
    );
  }
}