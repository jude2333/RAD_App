import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> setLoggedIn(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
  }

  static Future<void> setClientVar(String emp_var, String emp_index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(emp_index, emp_var);
  }

  static Future<void> setEmpData(int emp_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('emp_id', emp_id);
  }

  static Future<void> setRoleId(int roleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('role_id', roleId);
  }

  static Future<String?> getClientVar(String emp_index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(emp_index);
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<int?> getRoleId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('role_id');
  }

  static Future<int?> getClientData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('client_id');
  }

  static Future<int?> getEmpData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('emp_id');
  }
}
