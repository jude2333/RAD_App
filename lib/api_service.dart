import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';

import 'package:http_parser/http_parser.dart';
import 'models/login_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:convert/convert.dart';
import 'config.dart';

class APIService {
  static var client = http.Client();

  static Future<void> updateData(Map<String, dynamic> upData) async {
    var url = Uri.parse(Config.apiURL + Config.updateData);
    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'yQ7PRH2vX8rSWkwHy8gtg2WR6WSJaWuw',
    };
    String jsonString = jsonEncode(upData);
    var response = await http.post(url, headers: headers, body: jsonString);
    return jsonDecode(response.body);
  }

  static Future<LoginResponseModel> otpLogin(String mobileNo) async {
    var url = Uri.parse(Config.apiURL + Config.otpLoginAPI);
    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'yQ7PRH2vX8rSWkwHy8gtg2WR6WSJaWuw',
    };
    var body = '{"mobile_number": "' + mobileNo + '"}';
    var response = await http.post(url, headers: headers, body: body);
    return loginResponseJson(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String mobileNo,
    String otpHash,
    String otpCode,
  ) async {
    var url = Uri.parse(Config.apiURL + Config.verifyOTPAPI);
    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'yQ7PRH2vX8rSWkwHy8gtg2WR6WSJaWuw',
    };
    var body = '{"mobile_number": "' +
        mobileNo +
        '", "otp":"' +
        otpCode +
        '", "hash": "' +
        otpHash +
        '"}';
    var response = await http.post(url, headers: headers, body: body);
    // SessionManager.setClientData(int.parse(clientRes['client_id']));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> checkLogin(String mobileNo) async {
    var url = Uri.parse(Config.apiURL + Config.checkLogin);
    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'yQ7PRH2vX8rSWkwHy8gtg2WR6WSJaWuw',
    };
    var body = '{"mobile_number": "' + mobileNo + '"}';
    var response = await http.post(url, headers: headers, body: body);
    return jsonDecode(response.body);
  }

  static String encryptData(String data) {
    final Key key = Key.fromUtf8(Config.enkey);
    final IV iv = IV.fromUtf8(Config.eniv);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);
    return hex.encode(encrypted.bytes);
  }
}
