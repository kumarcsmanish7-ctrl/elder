import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../elder/find_helpers_screen.dart';
import '../helper/helper_dashboard.dart';
import '../helper/helper_verification_screen.dart';
import '../../services/session_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionService(),
      builder: (context, _) {
        final manualUid = SessionService().currentUid?.toLowerCase();
        final manualRole = SessionService().currentRole;
        
        if (manualUid != null) {
          return _buildWithUid(manualUid, manualRole: manualRole);
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFE0F2F1),
                body: Center(child: CircularProgressIndicator(color: Color(0xFF00838F))),
              );
            }
            
            if (snapshot.hasData) {
              // Use email as the document ID for fetching the user profile
              return _buildWithUid(snapshot.data!.email ?? snapshot.data!.uid);
            }
            
            return const Scaffold(
              body: Center(
                child: Text("Authentication Screen (LoginScreen deleted)"),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithUid(String uid, {String? manualRole}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE0F2F1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00838F))),
          );
        }

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          // Priority: 1. Database role (Source of Truth) 2. Manual toggle role (Fallback/Demo hint)
          String role = data?['role'] ?? manualRole ?? 'elder';
          bool isVerified = data?['isVerified'] ?? false;

          if (role == 'helper') {
            if (!isVerified) return const HelperVerificationScreen();
            return const HelperDashboard();
          } else {
            return const FindHelpersScreen();
          }
        }

        // Fallback for demo/missing docs
        String effectiveRole = manualRole ?? 'elder';
        if (manualRole == null) {
          if (uid.contains('volunteer') || uid.contains('helper') || uid.contains('nurse')) {
            effectiveRole = 'helper';
          }
        }

        if (effectiveRole == 'helper') {
          // In fallback mode, we default to Verification to be safe
          return const HelperVerificationScreen();
        }
        return const FindHelpersScreen();
      },
    );
  }
}
