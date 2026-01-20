import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';
import '../../services/session_service.dart';

class HelperVerificationScreen extends StatefulWidget {
  const HelperVerificationScreen({super.key});

  @override
  State<HelperVerificationScreen> createState() => _HelperVerificationScreenState();
}

class _HelperVerificationScreenState extends State<HelperVerificationScreen> {
  String? _fileName;
  bool _isLoading = false;
  bool _hasValidFile = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      
      if (result != null) {
        final file = result.files.single;
        final fileName = file.name.toLowerCase();
        final fileSize = file.size;
        
        // Validate file size (max 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File too large. Maximum 5MB allowed."), backgroundColor: Colors.red)
            );
          }
          return;
        }
        
        // Basic Aadhaar validation (check if filename contains "aadhaar" or "aadhar")
        final hasAadhaarKeyword = fileName.contains('aadhaar') || 
                                   fileName.contains('aadhar') || 
                                   fileName.contains('adhar');
        
        setState(() {
          _fileName = file.name;
          _hasValidFile = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(hasAadhaarKeyword 
                ? "✓ File uploaded successfully!" 
                : "File uploaded. Please ensure it's your Aadhaar card."),
              backgroundColor: hasAadhaarKeyword ? Colors.green : Colors.orange,
            )
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error selecting file"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _verifyAndContinue() async {
    if (!_hasValidFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your Aadhaar card first"), backgroundColor: Colors.red)
      );
      return;
    }

    final uid = Global.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'isVerified': true,
        'verificationFile': _fileName ?? "uploaded_document",
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      SessionService().notify();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);

    return Scaffold(
      backgroundColor: lightTeal,
      appBar: AppBar(
        title: const Text("Elderly Ease", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: tealGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Helper Verification",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: tealGreen),
                ),
                const SizedBox(height: 10),
                const Text("Upload your Aadhaar ID to get started", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 40),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _hasValidFile ? Colors.green : tealGreen.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _hasValidFile ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: _hasValidFile ? Colors.green : tealGreen,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _hasValidFile ? "File Uploaded ✓" : "Upload Document",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _hasValidFile ? Colors.green : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open, size: 20),
                        label: const Text("Choose File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tealGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, color: tealGreen, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _fileName!,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                const Text(
                  "Help elders trust verified helpers by verifying your identity.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_hasValidFile && !_isLoading) ? _verifyAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Verify & Continue"),
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
