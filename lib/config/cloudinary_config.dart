class CloudinaryConfig {
  static const cloudName = 'dp4ubhr1q';
  static const uploadPreset = 'internship_profiles';

  static bool get isConfigured =>
      cloudName.isNotEmpty &&
      uploadPreset.isNotEmpty &&
      !cloudName.startsWith('YOUR_') &&
      !uploadPreset.startsWith('YOUR_');
}
