import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/app/utils/validators.dart';

void main() {
  group('Validators Utility Tests', () {
    
    test('Email validator catches invalid formats', () {
      expect(Validators.email('test@test.com'), null);
      expect(Validators.email('invalid-email'), 'Enter a valid email address');
      expect(Validators.email(''), 'Email is required');
    });

    test('Password validator enforces length and spaces', () {
      expect(Validators.password('validPassword123'), null);
      expect(Validators.password('short'), 'Password must be at least 8 characters');
      expect(Validators.password('password with spaces'), "Password can't contain spaces");
      expect(Validators.password('a' * 31), 'Password length should not exceed 30 characters');
    });

    test('Name validator rejects special characters', () {
      expect(Validators.name('John Doe'), null);
      expect(Validators.name('John123'), "Name can't include special characters");
      expect(Validators.name('John_Doe'), "Name can't include special characters");
    });

    test('Confirm Password matches original', () {
      expect(Validators.confirmPassword('password123', 'password123'), null);
      expect(Validators.confirmPassword('wrong', 'password123'), 'Passwords do not match');
    });
  });
}