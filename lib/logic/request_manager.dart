import 'package:flutter/foundation.dart';
import 'dart:collection';
import '../models/request.dart';

class RequestManager {
  // HashMap to store all requests
  final Map<int, Request> requestMap = {};

  // Queue for normal requests (FIFO)
  final Queue<Request> normalQueue = Queue<Request>();

  // Priority Queue for emergency requests
  // Dart doesn't have a built-in PriorityQueue in core, 
  // but we can use a sorted list or import separate package.
  // For simplicity and since manual implementation is easy for this scale:
  final List<Request> emergencyQueue = [];

  bool isEmergency(Request request) {
    // Rule 1: Category-based emergency
    final emergencyCategories = ["Medical", "Safety", "Mobility"];
    if (emergencyCategories.contains(request.category)) {
      return true;
    }

    // Rule 2: Keyword-based urgency
    final urgentKeywords = [
      "urgent",
      "severe",
      "pain",
      "emergency",
      "fell",
      "can't move",
      "cannot move"
    ];

    final descriptionLower = request.description.toLowerCase();
    for (var word in urgentKeywords) {
      if (descriptionLower.contains(word)) {
        return true;
      }
    }

    return false;
  }

  void addRequest(Request request) {
    // Store request in HashMap
    requestMap[request.requestId] = request;

    // Insert into appropriate data structure
    if (isEmergency(request)) {
      emergencyQueue.add(request);
      // Sort in descending order of severity (higher severity first)
      emergencyQueue.sort((a, b) => b.severity.compareTo(a.severity));
      debugPrint("Request ${request.requestId} added to EMERGENCY priority queue");
    } else {
      normalQueue.add(request);
      debugPrint("Request ${request.requestId} added to NORMAL queue");
    }
  }

  Request? getNextRequest() {
    if (emergencyQueue.isNotEmpty) {
      return emergencyQueue.removeAt(0); // Pop highest priority
    } else if (normalQueue.isNotEmpty) {
      return normalQueue.removeFirst();
    } else {
      return null;
    }
  }
}
