import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';

class ElderProfileScreen extends StatefulWidget {
  const ElderProfileScreen({super.key});

  @override
  State<ElderProfileScreen> createState() => _ElderProfileScreenState();
}

class _ElderProfileScreenState extends State<ElderProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customAreaController = TextEditingController();
  
  String _selectedArea = "Jayanagar";
  bool _isLoading = false;

  final List<String> _areas = ["Jayanagar", "Kengeri", "Pattengere", "Mysore Road", "Rajajinagar", "Malleshwaram", "Koramangala", "Indiranagar", "Whitefield", "Electronic City", "BTM Layout"];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = Global.uid;
    if (uid == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          
          final savedArea = data['area'] ?? 'Jayanagar';
          // Safety: If the area in DB isn't in our list, fallback to Jayanagar to prevent crash
          _selectedArea = _areas.contains(savedArea) ? savedArea : 'Jayanagar';
          
          _customAreaController.text = data['customArea'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    final uid = Global.uid;
    if (uid == null) return;
    
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name"), backgroundColor: Colors.red)
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 10-digit phone number"), backgroundColor: Colors.red)
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phoneNumber': phone,
        'area': _selectedArea,
        'customArea': _customAreaController.text.trim(),
        'role': 'elder', // Ensure role remains elder
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Color(0xFF00897B))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);

    return Scaffold(
      backgroundColor: lightTeal,
      appBar: AppBar(
        backgroundColor: tealGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Name Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFB2DFDB),
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'E',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: tealGreen),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text : "Elder Name",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: tealGreen),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Profile Details
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Personal Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tealGreen)),
                  const SizedBox(height: 24),
                  
                  _buildLabel("Full Name"),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("Enter your name"),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Phone Number"),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("Enter 10-digit number"),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel("General Area"),
                  _buildDropdown(_selectedArea, _areas, (val) => setState(() => _selectedArea = val!)),
                  const SizedBox(height: 20),

                  _buildLabel("Custom Area / Specific Locality"),
                  TextField(
                    controller: _customAreaController,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("e.g., Near Metro Station"),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _customAreaController.dispose();
    super.dispose();
  }
}
