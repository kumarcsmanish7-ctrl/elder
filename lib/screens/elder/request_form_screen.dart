import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';

class RequestFormScreen extends StatefulWidget {
  final String category;
  const RequestFormScreen({super.key, required this.category});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    final uid = Global.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String userName = userDoc.data()?['name'] ?? Global.email ?? "Elder";

      await FirebaseFirestore.instance.collection('requests').add({
        'elderId': uid,
        'elderName': userName,
        'category': widget.category,
        'serviceType': widget.category,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'PENDING',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF673AB7);
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: Text("Request ${widget.category}", style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location (e.g. Jayanagar)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description of help needed",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Request", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
