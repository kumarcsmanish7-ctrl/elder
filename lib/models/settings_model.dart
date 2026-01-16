class Settings {
  final bool isCaregiver; // true = Caregiver sets dosage, false = Elder
  final bool isVoiceEnabled;

  Settings({
    this.isCaregiver = false,
    this.isVoiceEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'isCaregiver': isCaregiver,
      'isVoiceEnabled': isVoiceEnabled,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      isCaregiver: json['isCaregiver'] ?? false,
      isVoiceEnabled: json['isVoiceEnabled'] ?? true,
    );
  }

  Settings copyWith({
    bool? isCaregiver,
    bool? isVoiceEnabled,
  }) {
    return Settings(
      isCaregiver: isCaregiver ?? this.isCaregiver,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
    );
  }
}
