class MailServerConfig {
  static const baseUrl = String.fromEnvironment(
    'MAIL_SERVER_URL',
    defaultValue: 'http://127.0.0.1:8082',
  );
  static const apiKey = String.fromEnvironment(
    'MAIL_SERVER_API_KEY',
    defaultValue: 'local-dev-key',
  );
}
