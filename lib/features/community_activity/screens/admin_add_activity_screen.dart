import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/nominatim_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AdminAddActivityScreen extends StatefulWidget {
  const AdminAddActivityScreen({super.key});

  @override
  State<AdminAddActivityScreen> createState() => _AdminAddActivityScreenState();
}

class _AdminAddActivityScreenState extends State<AdminAddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final NominatimService _nominatimService = NominatimService();
  final LocationService _locationService = LocationService();

  final List<String> _categories = ['yoga', 'temple', 'cultural', 'health camps', 'others'];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _organizerNameController = TextEditingController();
  final TextEditingController _organizerContactController = TextEditingController();

  String _selectedCategory = 'yoga';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;
  Map<String, dynamic>? _tempCoordinates;
  String _verificationStatus = '';

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _organizerNameController.dispose();
    _organizerContactController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Removed _verifyAddress logic

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Use default coordinates (Bangalore center) to avoid intrusive address fetching
      final coordinates = {'lat': 12.9716, 'lon': 77.5946};

      // 2. Create Activity Object
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newActivity = Activity(
        id: '', // Firestore will generate ID
        activityName: _nameController.text,
        category: _selectedCategory,
        latitude: coordinates['lat']!,
        longitude: coordinates['lon']!,
        address: _addressController.text,
        date: combinedDateTime,
        shortDescription: _descriptionController.text,
        organizerName: _organizerNameController.text,
        organizerContact: _organizerContactController.text,
      );

      // 3. Save to Firestore
      await _firestoreService.addActivity(newActivity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding activity: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin: Add Activity'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Activity Name'),
                      validator: (value) => value!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'e.g. Lalbagh Botanical Garden, Bangalore',
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text("Date: ${DateFormat.yMd().format(_selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    ListTile(
                      title: Text("Time: ${_selectedTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerNameController,
                      decoration: const InputDecoration(labelText: 'Organizer Name'),
                      validator: (value) => value!.isEmpty ? 'Enter organizer' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerContactController,
                      decoration: const InputDecoration(labelText: 'Organizer Contact'),
                      validator: (value) => value!.isEmpty ? 'Enter contact' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveActivity,
                        child: const Text('Save Activity', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D9689),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
