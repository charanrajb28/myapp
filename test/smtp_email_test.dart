import 'package:flutter_test/flutter_test.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:myapp/config/mail_config.dart';

void main() {
  test('Send test email via Gmail SMTP', () async {
    final senderEmail = MailConfig.senderEmail;
    final senderPassword = MailConfig.senderAppPassword;

    print('📧 Sender Email: $senderEmail');
    print('🔑 Sender Password length: ${senderPassword.length}');

    expect(senderEmail, isNotEmpty);
    expect(senderPassword, isNotEmpty);

    final smtpServer = gmail(senderEmail, senderPassword);

    final message = Message()
      ..from = Address(senderEmail, 'Aaroha Placement Portal')
      ..recipients.add('1mv22cs048@sirmvit.edu')
      ..subject = 'Aaroha Portal - Test Invitation Credentials'
      ..html = '''
        <div style="font-family: sans-serif; padding: 20px; color: #0F172A;">
          <h2 style="color: #2563EB;">Welcome to Aaroha Portal!</h2>
          <p>Your account has been successfully created by the administration.</p>
          <div style="background: #F1F5F9; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p><strong>Recipient:</strong> 1mv22cs048@sirmvit.edu</p>
            <p><strong>Status:</strong> Verification Successful</p>
          </div>
          <p style="font-size: 12px; color: #64748B;">This is an automated test email sent from the Aaroha Placement System.</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent successfully! Report: $sendReport');
    } catch (e) {
      print('❌ Failed to send email: $e');
      fail('Mailing failed: $e');
    }
  });
}
