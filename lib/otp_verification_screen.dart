import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';
// import 'pdf.dart';
import 'patient_list.dart';
import 'session_manger.dart';
import 'package:intl/intl.dart';
import 'package:glassmorphism/glassmorphism.dart';

class Otp extends StatefulWidget {
  final String? mobileNo;
  final String? otpHash;

  const Otp({super.key, this.mobileNo, this.otpHash});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  final int _otpLength = 4;
  List<String> _otpValues = ["", "", "", ""];
  bool _enableButton = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/anderson-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verification",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your OTP Code",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 32),
              GlassmorphicContainer(
                width: 400,
                height: 200,
                borderRadius: 12,
                blur: 15,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      _buildOtpFields(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _enableButton ? _verify_otp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Didn't receive code?",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Resend Code ",
                      mouseCursor: SystemMouseCursors.click,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _resend_code();
                        },
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                        decorationColor: Colors.yellowAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 60,
          child: TextField(
            onChanged: (value) {
              if (value.isNotEmpty) {
                _otpValues[index] = value;
                if (index < _otpLength - 1) {
                  FocusScope.of(context).nextFocus();
                }
              } else {
                _otpValues[index] = "";
                if (index > 0) {
                  FocusScope.of(context).previousFocus();
                }
              }

              setState(() {
                _enableButton = _otpValues.every((digit) => digit.isNotEmpty);
              });

              //  Auto-submit when 4 digits entered
              if (_otpValues.join().length == _otpLength) {
                //_verify_otp();
              }
            },
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _verify_otp() async {
    String enteredOtp = _otpValues.join();
    var response = await APIService.verifyOtp(
      widget.mobileNo!,
      widget.otpHash!,
      enteredOtp,
    );
    if (response['data'] == 'matched') {
      print(response);
      SessionManager.setLoggedIn(true);
      SessionManager.setRoleId(response['role_id']);
      SessionManager.setEmpData(response['emp_id']);
      SessionManager.setClientVar(response['emp_name'], "emp_name");
      SessionManager.setClientVar(response['mobile_number'], "mobile_number");
      var pageDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      SessionManager.setClientVar(pageDate, "pageDate");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PatientList()),
      );
    } else {
      // Invalid OTP
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid OTP'),
          content: const Text('Please enter a valid 4-digit OTP.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                Future.microtask(() {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Contact()),
                    (route) => false,
                  );
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _resend_code() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Contact()),
      (route) => false,
    );
  }
}
