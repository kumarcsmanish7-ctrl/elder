import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';

class HelperProfileScreen extends StatefulWidget {
  const HelperProfileScreen({super.key});

  @override
  State<HelperProfileScreen> createState() => _HelperProfileScreenState();
}

class _HelperProfileScreenState extends State<HelperProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customAreaController = TextEditingController();
  
  String _selectedProfession = "Nurse";
  String _selectedArea = "Jayanagar";
  bool _isAvailable = true;
  bool _isLoading = false;
  List<String> _selectedServices = ["Elderly Care", "Medical Assistance", "Daily Support"];

  final List<String> _professions = ["Nurse", "Caretaker", "Medical Assistant", "Physiotherapist", "Cook", "Housekeeper", "General Helper"];
  final List<String> _areas = ["Jayanagar", "Kengeri", "Pattengere", "Mysore Road", "Rajajinagar", "Malleshwaram", "Koramangala", "Indiranagar", "Whitefield", "Electronic City", "BTM Layout"];
  final List<String> _availableServices = ["Elderly Care", "Medical Assistance", "Daily Support"];

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
          _selectedProfession = data['profession'] ?? 'Nurse';
          _selectedArea = data['area'] ?? 'Jayanagar';
          _customAreaController.text = data['customArea'] ?? '';
          _isAvailable = data['isAvailable'] ?? true;
          if (data['servicesOffered'] != null) {
            _selectedServices = List<String>.from(data['servicesOffered']);
          }
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
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number"), backgroundColor: Colors.red)
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 10-digit phone number"), backgroundColor: Colors.red)
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'profession': _selectedProfession,
        'area': _selectedArea,
        'customArea': _customAreaController.text.trim(),
        'servicesOffered': _selectedServices,
        'isAvailable': _isAvailable,
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
        title: const Text("Helper Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Name Header (Real-time for ratings and availability changes)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(Global.uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                
                // Consistency Logic: Match Elder View (Fake 4.0/3 if new)
                double rating = (data['rating'] ?? 0.0).toDouble();
                int ratingCount = (data['ratingCount'] ?? 0) as int;
                
                if (rating == 0.0 && ratingCount == 0) {
                  rating = 4.0;
                  ratingCount = 3; // Though not displayed here, logic should match
                }

                final name = data['name'] ?? _nameController.text;

                return Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFB2DFDB),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'H',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: tealGreen),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        name.isNotEmpty ? name : "Helper Name",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tealGreen),
                      ),
                      const SizedBox(height: 10),
                      // Rating Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating.floor() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 24,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            ),
            
            const SizedBox(height: 30),
            
            // Availability Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Availability Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Toggle to receive requests", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: _isAvailable,
                    onChanged: (val) => setState(() => _isAvailable = val),
                    activeColor: tealGreen,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Profile Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tealGreen)),
                  const SizedBox(height: 20),
                  
                  _buildLabel("Name"),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration("Enter your name"),
                  ),
                  const SizedBox(height: 15),
                  
                  _buildLabel("Phone Number"),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration("Enter your phone number"),
                  ),
                  const SizedBox(height: 15),
                  
                  _buildLabel("Profession"),
                  _buildDropdown(_selectedProfession, _professions, (val) => setState(() => _selectedProfession = val!)),
                  const SizedBox(height: 15),
                  
                  _buildLabel("Area"),
                  _buildDropdown(_selectedArea, _areas, (val) => setState(() => _selectedArea = val!)),
                  const SizedBox(height: 15),
                  
                  _buildLabel("Custom Area (Optional)"),
                  TextField(
                    controller: _customAreaController,
                    decoration: _inputDecoration("Specific locality..."),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text("Services Offered", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableServices.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service, style: TextStyle(color: isSelected ? Colors.white : tealGreen, fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              _selectedServices.remove(service);
                            }
                          });
                        },
                        selectedColor: tealGreen,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
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
