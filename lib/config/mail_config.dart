class MailConfig {
  static const String _rawEmail = String.fromEnvironment('SENDER_EMAIL', defaultValue: 'charanrajb282004@gmail.com');
  static const String _rawPassword = String.fromEnvironment('SENDER_APP_PASSWORD', defaultValue: 'dqjqimlyxvmrmjwe');
  
  static String get senderEmail => _rawEmail.trim();
  static String get senderAppPassword => _rawPassword
      .replaceAll('"', '')
      .replaceAll("'", '')
      .replaceAll(' ', '')
      .trim();
      
  static const senderName = 'ScholarBridge Security';
}
