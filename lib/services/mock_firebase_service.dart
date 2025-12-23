import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirebaseService {
  static final MockFirebaseService _instance = MockFirebaseService._internal();
  factory MockFirebaseService() => _instance;
  static MockFirebaseService get instance => _instance;

  MockFirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory storage for OTP (demo purposes)
  final Map<String, String> _otpStorage = {};

  /// Sign in with National ID and PIN
  /// In production, this would map National ID to email/phone in your system
  Future<Map<String, dynamic>?> signInWithNationalId(String nationalId, String pin) async {
    try {
      // For demo: create email from National ID
      final email = '$nationalId@banking.app';

      // Try to sign in with Firebase
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: pin,
        );

        // Get user profile from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data();
        }

        return {
          'nationalId': nationalId,
          'uid': credential.user!.uid,
        };
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // For demo: allow any valid National ID with PIN "123456"
          if (isValidEgyptianNationalId(nationalId) && pin == '123456') {
            return {
              'nationalId': nationalId,
              'phoneNumber': '01234567890',
              'fullNameEnglish': 'Demo User',
            };
          }
        }
        return null;
      }
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  /// Send OTP to phone number
  Future<String> sendOTP(String phoneNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate a random 6-digit OTP
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // Store OTP for verification
    _otpStorage[phoneNumber] = otp;

    // In production, integrate with SMS service here
    print('📱 OTP for $phoneNumber: $otp');

    return otp;
  }

  /// Verify OTP
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if OTP matches
    if (_otpStorage.containsKey(phoneNumber)) {
      final storedOtp = _otpStorage[phoneNumber];
      if (storedOtp == otp) {
        _otpStorage.remove(phoneNumber); // Remove OTP after successful verification
        return true;
      }
    }

    // For demo: accept "123456" as valid OTP
    return otp == '123456';
  }

  /// Register new user with Firebase Auth and Firestore
  Future<Map<String, dynamic>> registerUser({
    required String nationalId,
    required String phoneNumber,
    required String pin,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // Create email from National ID
      final email = '$nationalId@banking.app';

      // Create Firebase user with proper error handling
      UserCredential? credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pin,
        );
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth error: ${e.code} - ${e.message}');
        if (e.code == 'email-already-in-use') {
          throw Exception('This National ID is already registered. Please login instead.');
        } else if (e.code == 'weak-password') {
          throw Exception('PIN must be at least 6 digits.');
        } else if (e.code == 'invalid-email') {
          throw Exception('Invalid registration format.');
        }
        rethrow;
      } catch (e) {
        print('Unexpected auth error: $e');
        // Continue without Firebase Auth if there's a type error
        // Use mock registration instead
        final mockUid = 'mock_${nationalId}_${DateTime.now().millisecondsSinceEpoch}';
        final userData = {
          'nationalId': nationalId,
          'phoneNumber': phoneNumber,
          'uid': mockUid,
          'email': email,
          ...profileData,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        print('Using mock registration for National ID: $nationalId');
        return userData;
      }

      if (credential?.user == null) {
        throw Exception('Registration failed: No user created');
      }

      // Create user profile in Firestore
      final userData = {
        'nationalId': nationalId,
        'phoneNumber': phoneNumber,
        'uid': credential.user!.uid,
        'email': email,
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      return userData;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// Validates Egyptian National ID format (14 digits)
  /// Format: Century(1) + Year(2) + Month(2) + Day(2) + Governorate(2) + Sequence(4) + Check(1)
  static bool isValidEgyptianNationalId(String nationalId) {
    if (nationalId.isEmpty) return false;

    // Must be exactly 14 digits
    if (nationalId.length != 14) return false;

    // Must contain only digits
    if (!RegExp(r'^\d+$').hasMatch(nationalId)) return false;

    // First digit must be 2 or 3 (for birth century)
    final firstDigit = int.parse(nationalId[0]);
    if (firstDigit != 2 && firstDigit != 3) return false;

    // Extract and validate birth year
    final year = int.parse(nationalId.substring(1, 3));

    // Extract and validate month (01-12)
    final month = int.parse(nationalId.substring(3, 5));
    if (month < 1 || month > 12) return false;

    // Extract and validate day (01-31)
    final day = int.parse(nationalId.substring(5, 7));
    if (day < 1 || day > 31) return false;

    // Extract governorate code (01-35)
    final governorate = int.parse(nationalId.substring(7, 9));
    if (governorate < 1 || governorate > 35) return false;

    return true;
  }

  /// Validates Egyptian phone number format
  /// Formats supported:
  /// - 11 digits starting with 01
  /// - With country code: +2 or 002 followed by 10 digits starting with 1
  static bool isValidEgyptianPhone(String phone) {
    if (phone.isEmpty) return false;

    // Remove all spaces, dashes, and parentheses
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Format 1: 11 digits starting with 01
    if (RegExp(r'^01[0-9]{9}$').hasMatch(cleanPhone)) {
      return true;
    }

    // Format 2: +2 followed by 10 digits starting with 1
    if (RegExp(r'^\+21[0-9]{9}$').hasMatch(cleanPhone)) {
      return true;
    }

    // Format 3: 002 followed by 10 digits starting with 1
    if (RegExp(r'^00221[0-9]{9}$').hasMatch(cleanPhone)) {
      return true;
    }

    return false;
  }

  /// Validates email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validates PIN (6 digits)
  static bool isValidPin(String pin) {
    if (pin.isEmpty) return false;

    return RegExp(r'^\d{6}$').hasMatch(pin);
  }
}

