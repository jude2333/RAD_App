import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'pdf_viewer_screen.dart';
import 'session_manger.dart';
import 'welcome_screen.dart';
import 'config.dart';
import 'api_service.dart';
import 'custom_drawer.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

void main() {
  runApp(MaterialApp(home: PatientList()));
}

class PatientList extends StatefulWidget {
  @override
  _PatientlistState createState() => _PatientlistState();
}

class RequestPatientDetails {
  final String id;
  final String date;
  final String name;
  final String test;
  final String accession_no;
  final String radiology_id;
  final String radiologist_name;
  final String approve_status;
  final String client_name;
  final String assign_time;
  final String center_name;
  final String file_path;
  final String file_path_wos;

  RequestPatientDetails({
    required this.id,
    required this.date,
    required this.name,
    required this.test,
    required this.accession_no,
    required this.radiology_id,
    required this.radiologist_name,
    required this.approve_status,
    required this.client_name,
    required this.assign_time,
    required this.center_name,
    required this.file_path,
    required this.file_path_wos,
  });
}

class Items {
  String label;
  Color color;
  bool isSelected;
  Items(this.label, this.color, this.isSelected);
  @override
  String toString() {
    return 'Items(label: $label, color: $color, isSelected: $isSelected)';
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: LoadingAnimationWidget.flickr(
          leftDotColor: Colors.blueAccent,
          rightDotColor: Colors.orange,
          size: 50,
        ),
      ),
    );
  }
}

class Radiologist {
  final String emp_id;
  final String emp_name;

  Radiologist({required this.emp_id, required this.emp_name});

  factory Radiologist.fromJson(Map<String, dynamic> json) {
    return Radiologist(
      emp_id: json['emp_id'].toString(),
      emp_name: json['first_name'] ?? '',
    );
  }
}

class _PatientlistState extends State<PatientList> {
  List<PopupMenuItem<String>> _menuItems = [];
  // List<RequestPatientDetails> sk_patients = [];
  bool isLoading = true;
  DateTime selectedDatef = DateTime.now();
  int skCount = 0;
  String emp_name = "";
  int emp_id = 0;
  String mobile_number = "";
  int role_id = 0;
  List<RequestPatientDetails> pending = [];
  int pending_count = 0;
  List<RequestPatientDetails> rad_pending = [];
  int rad_pending_count = 0;
  List<RequestPatientDetails> rad_reviewed = [];
  int rad_reviewed_count = 0;
  List<RequestPatientDetails> holded = [];
  int holded_count = 0;
  List<RequestPatientDetails> rad_total_const = [];
  List<RequestPatientDetails> rad_patients = [];
  int rad_patients_count = 0;
  String? file_path;
  String? file_path_wos;
  String? worklist_approve;
  List<Radiologist> radiologistList = [];
  String? select_rad_id;
  TextEditingController PatientController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    check_login();
    DateTime today = DateTime.now();
    DateTime previous_days = today.subtract(Duration(days: 2));

    String formatted_today = DateFormat('yyyy-MM-dd').format(today);
    String formatted_previous_days = DateFormat(
      'yyyy-MM-dd',
    ).format(previous_days);

    fromDateController.text = formatted_previous_days;
    toDateController.text = formatted_today;
    print(fromDateController.text);
    print(toDateController.text);
    fetchRadiologists();
    fetchData(select_rad_id);
  }

  String setLevel(String level) {
    switch (level) {
      case "L1":
        return "LH";
      case "L2":
        return "LM";
      case "L3":
        return "LL";
      default:
        return "LL(NC)";
    }
  }

  Future<void> fetchDataUpdate() async {
    isLoading = false;
    List<RequestPatientDetails> rad_patients_temp = [];

    List<RequestPatientDetails> rad_pending_temp = [];
    List<RequestPatientDetails> pending_temp = [];
    List<RequestPatientDetails> holded_temp = [];
    List<RequestPatientDetails> rad_reviewed_temp = [];

    String patient_term = PatientController.text.toLowerCase();
    for (var patient in rad_total_const) {
      String patient_name = patient.name.toLowerCase();
      String client_name = patient.client_name.toLowerCase();

      bool matches_search =
          patient_term.isEmpty ||
          patient_name.contains(patient_term) ||
          client_name.contains(patient_term);

      if (matches_search) {
        String? file_path = patient.file_path;
        String? file_path_wos = patient.file_path_wos;
        String? approve_status = patient.approve_status;

        bool both_empty =
            (file_path.isEmpty ?? true) && (file_path_wos.isEmpty ?? true);
        bool both_missing = file_path == null && file_path_wos == null;
        bool add = both_missing || both_empty;

        bool has_any_file_path =
            (file_path.isNotEmpty ?? false) ||
            (file_path_wos.isNotEmpty ?? false);
        bool is_file_path_wos_present = file_path_wos.isNotEmpty ?? false;
        bool is_approve_empty = approve_status.isEmpty;

        // if (add) {
        //   pending_temp.add(patient);
        // } else if (has_any_file_path && approve_status == "1") {
        //   rad_reviewed_temp.add(patient);
        // } else if (has_any_file_path && approve_status == "2") {
        //   holded_temp.add(patient);
        // } else if ((is_file_path_wos_present || has_any_file_path) &&
        //     is_approve_empty) {
        //   rad_pending_temp.add(patient);
        // }

        if (approve_status == "1") {
          rad_reviewed_temp.add(patient);
        } else if (has_any_file_path && approve_status == "2") {
          holded_temp.add(patient);
        } else if ((is_file_path_wos_present || has_any_file_path)) {
          rad_pending_temp.add(patient);
        } else {
          pending_temp.add(patient);
        }

        rad_patients_temp.add(patient);
      }
    }
    setState(() {
      rad_pending = rad_pending_temp;
      rad_patients_count = rad_patients_temp.length;
      rad_pending_count = rad_pending_temp.length;
      rad_reviewed = rad_reviewed_temp;
      rad_reviewed_count = rad_reviewed_temp.length;
      rad_patients = rad_patients_temp;
      pending = pending_temp;
      pending_count = pending_temp.length;
      holded = holded_temp;
      holded_count = holded_temp.length;
    });
  }

  Future<void> fetchRadiologists() async {
    var url = Uri.parse(Config.apiURL + Config.getRadiologist);
    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'yQ7PRH2vX8rSWkwHy8gtg2WR6WSJaWuw',
    };

    var response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      List<dynamic> dataList = jsonData as List;

      setState(() {
        radiologistList = dataList.map((e) => Radiologist.fromJson(e)).toList();

        if (radiologistList.isNotEmpty) {
          // select_rad_id = radiologistList[0].emp_id;
        }
      });
    } else {
      print("Failed to load radiologists");
    }
  }

  Future<void> fetchData(String? select_rad_id) async {
    List<RequestPatientDetails> rad_patients_temp = [];
    List<RequestPatientDetails> rad_pending_temp = [];
    List<RequestPatientDetails> pending_temp = [];
    List<RequestPatientDetails> holded_temp = [];
    List<RequestPatientDetails> rad_reviewed_temp = [];

    String patient_term = PatientController.text.toLowerCase();
    emp_id = (await SessionManager.getEmpData())!;
    role_id = (await SessionManager.getRoleId())!;
    emp_name = (await SessionManager.getClientVar('emp_name'))!;
    mobile_number = (await SessionManager.getClientVar('mobile_number'))!;
    print(
      "emp_id: $emp_id, role_id: $role_id, emp_name: $emp_name, mobile_number: $mobile_number",
    );

    final fromText = fromDateController.text.trim();
    final toText = toDateController.text.trim();
    DateTime startDate = DateTime.parse(fromText);
    DateTime endDate = DateTime.parse(toText);

    for (var g = 0; g <= endDate.difference(startDate).inDays; g++) {
      var pageDate = DateFormat(
        'yyyy-MM-dd',
      ).format(startDate.add(Duration(days: g)));
      var url = Uri.parse(Config.apiURL + Config.getPatientList);
      var headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'yQ7PRH2vX8rSWkwHy8gtg2WR6WSJaWuw',
      };
      var body = '{"id": "$pageDate"}';
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        var dartMap = jsonDecode(response.body);
        for (var m = 0; m < dartMap.length; m++) {
          if (dartMap[m]['value']['patients'][0] != null) {
            var patients = dartMap[m]['value']['patients'];
            for (var i = 0; i < patients.length; i++) {
              var investigations = patients[i]['investigations'];
              for (var j = 0; j < investigations.length; j++) {
                var investigation = investigations[j];
                if (investigation.containsKey('assigned_radiologist_id')) {
                  if (role_id == 510 &&
                      investigation['assigned_radiologist_id']?.toString() !=
                          emp_id.toString()) {
                    continue;
                  }
                  if ((role_id == 501 || role_id == 502) &&
                      select_rad_id != null &&
                      select_rad_id.isNotEmpty &&
                      investigation['assigned_radiologist_id']?.toString() !=
                          select_rad_id) {
                    continue;
                  }
                  String? file_path = investigation['file_path']?.toString();
                  String? file_path_wos = investigation['file_path_wos']
                      ?.toString();
                  String? worklist_approve = investigation['worklist_approve']
                      ?.toString();

                  var patient_details = RequestPatientDetails(
                    id: patients[i]['patient_no'] ?? '',
                    date: patients[i]['visit_date'] ?? '',
                    name: patients[i]['patient_name'] ?? '',
                    test: investigation['Investigation_Name'] ?? '',
                    accession_no: investigation['AccessionNo'] ?? '',
                    radiology_id: dartMap[m]['value']['_id'] ?? '',
                    radiologist_name:
                        investigation['assigned_radiologist_name'] ??
                        'Dr. Unknown',
                    client_name: patients[i]['client_name'] ?? '',
                    assign_time: investigation['assigned_time'] ?? '',
                    center_name: investigation['study_processing_center'] ?? '',
                    file_path: file_path ?? '',
                    file_path_wos: file_path_wos ?? '',
                    approve_status: worklist_approve ?? '',
                  );

                  bool both_empty =
                      (file_path?.isEmpty ?? true) &&
                      (file_path_wos?.isEmpty ?? true);
                  bool both_missing =
                      file_path == null && file_path_wos == null;
                  bool add = both_missing || both_empty;

                  bool has_any_file_path =
                      (file_path?.isNotEmpty ?? false) ||
                      (file_path_wos?.isNotEmpty ?? false);
                  bool is_file_path_wos_present =
                      file_path_wos?.isNotEmpty ?? false;
                  bool is_approve_empty =
                      worklist_approve == null || worklist_approve.isEmpty;

                  if (worklist_approve == "1") {
                    rad_reviewed_temp.add(patient_details);
                  } else if (has_any_file_path && worklist_approve == "2") {
                    holded_temp.add(patient_details);
                  } else if ((is_file_path_wos_present || has_any_file_path)) {
                    rad_pending_temp.add(patient_details);
                  } else {
                    pending_temp.add(patient_details);
                  }
                  // if (add) {
                  //   pending_temp.add(patient_details);
                  // } else if (has_any_file_path && worklist_approve == "1") {
                  //   rad_reviewed_temp.add(patient_details);
                  // } else if (has_any_file_path && worklist_approve == "2") {
                  //   holded_temp.add(patient_details);
                  // } else if ((is_file_path_wos_present || has_any_file_path) &&
                  //     is_approve_empty) {
                  //   rad_pending_temp.add(patient_details);
                  // }

                  rad_patients_temp.add(patient_details);
                }
              }
            }
          }
        }
      }
    }

    setState(() {
      rad_patients = rad_patients_temp;
      rad_patients_count = rad_patients_temp.length;
      rad_pending = rad_pending_temp;
      rad_pending_count = rad_pending_temp.length;
      rad_reviewed = rad_reviewed_temp;
      rad_reviewed_count = rad_reviewed_temp.length;
      pending = pending_temp;
      pending_count = pending_temp.length;
      holded = holded_temp;
      holded_count = holded_temp.length;
      rad_total_const = rad_patients_temp;
      isLoading = false;
      emp_name = emp_name;
      mobile_number = mobile_number;
      role_id = role_id;
      emp_id = emp_id;
    });
  }

  Future<void> check_login() async {
    var mobile_number = (await SessionManager.getClientVar('mobile_number'))!;
    APIService.checkLogin(mobile_number).then((response) async {
      if (response['emp_id'] == null) {
        _logout();
      } else {
        // List<String> stringArray = response['modality_id'].split(',');
        // if (stringArray.length > 1) {
        //   _menuItems.add(
        //     PopupMenuItem<String>(
        //       value: response['modality_id'],
        //       child: Text("All"),
        //     ),
        //   );
        // }
        // var modality_name = "";
        // String? modality_id = await SessionManager.getClientVar('modality_id');
        // var res = 0;
        // for (String item in stringArray) {
        //   if (modality_id == item) {
        //     res = 1;
        //   }
        //   modality_name = (await SessionManager.getClientVar('mod_' + item))!;
        //   _menuItems.add(
        //     PopupMenuItem<String>(value: item, child: Text(modality_name)),
        //   );
        // }
        // if (res == 0) {
        //   SessionManager.setClientVar(response['modality_id'], "modality_id");
        // }

        // SessionManager.setClientVar(
        //   response['study_processing_center'],
        //   "study_processing_center",
        // );

        // print(fcmToken);
        // for (int i = 1; i <= 5; i++) {
        //   _menuItems.add(
        //     PopupMenuItem<String>(
        //       value: 'Item $i',
        //       child: Text('Item $i'),
        //     ),
        //   );
        // }
      }
    });
  }

  void _logout() {
    SessionManager.setLoggedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Welcome()),
      (route) => false,
    );
  }

  Future<void> _refreshData() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PatientList()),
      (route) => false,
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<DropdownMenuItem<String?>> dropdownItems = [
              DropdownMenuItem<String?>(
                value: null,
                child: SizedBox(
                  height: 30,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Radiologist',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              for (var radiologist in radiologistList)
                DropdownMenuItem<String?>(
                  value: radiologist.emp_id,
                  child: SizedBox(
                    height: 30,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        radiologist.emp_name,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
            ];

            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.75,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16.0),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date pickers row (your existing code)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: fromDateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'From Date',
                                      hintText: 'Select From Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: toDateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'To Date',
                                      hintText: 'Select To Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),
                            Visibility(
                              visible: (role_id == 501 || role_id == 502),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Select',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 16,
                                  ), // spacing between label and dropdown
                                  Expanded(
                                    child: DropdownButtonFormField<String?>(
                                      value: select_rad_id,
                                      items: dropdownItems,
                                      onChanged: (value) {
                                        setState(() {
                                          select_rad_id = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.blueAccent.shade700,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade900,
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  child: Text(
                                    'Apply',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    fetchData(
                                      select_rad_id,
                                    ); // Your fetchData function
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
        );
      },
    );
  }

  void _handleTap() {
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? DateTime.now() : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          if (toDateController.text.isNotEmpty &&
              DateTime.parse(toDateController.text).isBefore(picked)) {
            toDateController.clear();
          }
        } else {
          if (picked.isAfter(DateTime.parse(fromDateController.text))) {
            toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text('Rad Review'),
          backgroundColor: Colors.blue,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.filter_alt_rounded,
                size: 24,
                color: Colors.white,
              ),
              onPressed: () async {
                _showFilterDialog(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 20, color: Colors.white),
              onPressed: () async {
                _refreshData();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 35,
                    child: TextFormField(
                      controller: PatientController,
                      focusNode: _focusNode,
                      onTapOutside: (event) {
                        _focusNode.unfocus();
                      },
                      onTap: _handleTap,
                      onChanged: (text) {
                        fetchDataUpdate();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Patient or Client',
                        hintStyle: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 1,
                          horizontal: 8,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.orange,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.orange,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        suffixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
        drawer: CustomDrawer(
          emp_name: emp_name,
          mobile_number: mobile_number,
          role_id: role_id,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Column(
                    children: [
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange[400],
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(color: Colors.blue[300]),
                            indicatorWeight: 8.0,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white,
                            // isScrollable: true,
                            tabs: [
                              _buildTabWithBadge('Total', rad_patients_count),
                              _buildTabWithBadge('Progress', pending_count),
                              _buildTabWithBadge('Pending', rad_pending_count),
                              _buildTabWithBadge('Holded', holded_count),
                              _buildTabWithBadge(
                                'Reviewed',
                                rad_reviewed_count,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView.builder(
                              itemCount: rad_patients.length,
                              itemBuilder: (context, index) {
                                final rad = rad_patients[index];
                                return _buildPatientCard(rad, "Total");
                              },
                            ),
                            ListView.builder(
                              itemCount: pending.length,
                              itemBuilder: (context, index) {
                                final rad = pending[index];
                                return _buildPatientCard(rad, "Progress");
                              },
                            ),
                            ListView.builder(
                              itemCount: rad_pending.length,
                              itemBuilder: (context, index) {
                                final rad = rad_pending[index];
                                return _buildPatientCard(rad, "Pending");
                              },
                            ),
                            ListView.builder(
                              itemCount: holded.length,
                              itemBuilder: (context, index) {
                                final hold = holded[index];
                                return _buildPatientCard(hold, "Holded");
                              },
                            ),
                            ListView.builder(
                              itemCount: rad_reviewed.length,
                              itemBuilder: (context, index) {
                                final rad = rad_reviewed[index];
                                return _buildPatientCard(rad, "Reviewed");
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _sleep() async {
    await Future.delayed(Duration(seconds: 1));
  }

  Widget _buildTabWithBadge(String label, int badgeCount) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                label,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (badgeCount > 0) ...[
            // SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: BoxConstraints(minWidth: 14, minHeight: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount.toString(),
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCard(RequestPatientDetails patient, String buttonText) {
    String formattedDate = DateFormat(
      'dd-MM-yyyy hh:mm a',
    ).format(DateTime.parse(patient.date));
    String assignTime = "";
    if (patient.assign_time != "") {
      assignTime = DateFormat(
        'dd-MM-yyyy hh:mm a',
      ).format(DateTime.parse(patient.assign_time));
    }
    DateTime? estimationDateTime;
    List<String> parts = patient.name.split('/');

    String name = parts[0].trim();

    RegExp agePattern = RegExp(r'\((\d+)\s*Y\)');
    String age = '';
    Match? match = agePattern.firstMatch(patient.name);
    if (match != null) {
      age = '(${match.group(1)}y)';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Card(
            elevation: 6,
            shadowColor: Colors.orangeAccent,
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    patient.name.toUpperCase().contains(
                                          'FEMALE',
                                        )
                                        ? 'assets/woman.png'
                                        : 'assets/man.png',
                                    width: 40,
                                    height: 45,
                                    color:
                                        patient.name.toUpperCase().contains(
                                          'FEMALE',
                                        )
                                        ? Colors.pink
                                        : Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$name $age',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        SizedBox(height: 1),
                                        Row(
                                          children: [
                                            const Text(
                                              "patient Id: ",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${patient.id}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Text(
                                              "Accession no: ",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${patient.accession_no}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Center(
                      child: Text(
                        "${patient.test}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Center(
                      child: Text(
                        "${patient.client_name}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 55, 70, 239),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/user.png',
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "${patient.radiologist_name}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/time.png',
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  assignTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if ((patient.file_path != '' ||
                                    patient.file_path_wos != '') &&
                                patient.approve_status == "")
                              Tooltip(
                                message: 'Review',
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    _showpdf(
                                      patient.accession_no,
                                      patient.file_path,
                                      patient.file_path_wos,
                                      patient.approve_status,
                                      patient.radiology_id,
                                      emp_name,
                                      context,
                                    );
                                  },
                                  icon: Image.asset(
                                    'assets/review.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  label: Text(
                                    'Review',
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Color.fromARGB(187, 13, 72, 161),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                            if (patient.approve_status == "1")
                              InkWell(
                                onTap: () {
                                  _showpdf(
                                    patient.accession_no,
                                    patient.file_path,
                                    patient.file_path_wos,
                                    patient.approve_status,
                                    patient.radiology_id,
                                    emp_name,
                                    context,
                                  );
                                },
                                child: Tooltip(
                                  message: 'Approved',
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/approved.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Approved',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (patient.approve_status == "2")
                              InkWell(
                                onTap: () {
                                  _showpdf(
                                    patient.accession_no,
                                    patient.file_path,
                                    patient.file_path_wos,
                                    patient.approve_status,
                                    patient.radiology_id,
                                    emp_name,
                                    context,
                                  );
                                },
                                child: Tooltip(
                                  message: 'Hold',
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/hold.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Hold',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                            255,
                                            183,
                                            0,
                                            33,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              patient.center_name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showpdf(
    accession_no,
    file_path,
    file_path_wos,
    approve,
    radiology_id,
    emp_name,
    BuildContext context,
  ) {
    var filePathWos = file_path_wos;
    var filePath = file_path;

    var new_path = '';

    if (filePath == null || filePath.isEmpty) {
      new_path = filePathWos.replaceAll("-wos", "");
      List<String> parts = new_path.split("/");
      if (parts.length > 5 && parts[5].contains("_")) {
        List<String> split_name = parts[5].split("_");
        if (split_name.length > 1) {
          parts[5] = split_name[1];
        }
      }
      new_path = parts.join("/");
    } else {
      new_path = filePath;
    }

    print("Updated Path: $new_path");
    var response = APIService.encryptData(new_path);

    String pdfUrl =
        Config.apiURL +
        Config.pdfViewer +
        '?file=' +
        Uri.encodeComponent(response);
    // print(pdfUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          radiology_id: radiology_id,
          file_path: pdfUrl,
          accession_no: accession_no,
          emp_name: emp_name,
          approve_status: approve,
        ),
      ),
    );
  }
}
