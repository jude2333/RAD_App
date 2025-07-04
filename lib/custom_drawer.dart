import 'package:flutter/material.dart';
import 'config.dart';
import 'patient_list.dart';
import 'session_manger.dart';
import 'welcome_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String emp_name;
  final String mobile_number;
  final int role_id;

  CustomDrawer({
    required this.emp_name,
    required this.mobile_number,
    required this.role_id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset('assets/fav.png'),
                ),
                const SizedBox(height: 4),
                Text(
                  '$emp_name ($mobile_number)',
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
                Text(
                  'v ' + Config.rad_version,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          Card(
            elevation: 3,
            child: ListTile(
              title: Text('Patient List'),
              leading: Visibility(
                child: Icon(
                  Icons.assignment_turned_in,
                  color: Color.fromRGBO(33, 150, 223, 1.000),
                ),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => PatientList()),
                  (route) => false,
                );
              },
            ),
          ),
          Card(
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () {
                SessionManager.setLoggedIn(false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Welcome()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
