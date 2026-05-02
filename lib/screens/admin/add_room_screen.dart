import 'package:flutter/material.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  static const _roomTypes = ['Classroom', 'Lab'];

  final _roomNameController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _roomType;

  @override
  void dispose() {
    _roomNameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _onSave() {
    final roomName = _roomNameController.text.trim();
    final roomType = _roomType ?? '(none selected)';
    final capacity = _capacityController.text.trim();

    debugPrint('Room: $roomName | Type: $roomType | Capacity: $capacity');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      items: _roomTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
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

