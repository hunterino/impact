import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(PlanMapApp());
}

class PlanMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan Map Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xfff5f5f5),
      ),
      home: PlanMapForm(),
    );
  }
}

class PlanMapModel {
  String city;
  String label;
  String state;
  bool active;
  bool checkBox;
  int dropdown;
  DateTime started;
  String lastName;
  String password;
  Map<String, dynamic> jsonEditor;
  String description;
  double customdial;
  List<int> selectedList;

  PlanMapModel({
    this.city = 'San Jose',
    this.label = 'Your Label',
    this.state = 'California',
    this.active = true,
    this.checkBox = false,
    this.dropdown = 2,
    required this.started,
    this.lastName = 'Alfreds',
    this.password = 'some_thing_goes_here',
    this.jsonEditor = const {"some": "data"},
    this.description = 'this is a long text',
    this.customdial = 25.0,
    this.selectedList = const [1, 2, 3],
  });

  factory PlanMapModel.fromJson(Map<String, dynamic> json) {
    return PlanMapModel(
      city: json['city'] ?? 'San Jose',
      label: json['label'] ?? 'Your Label',
      state: json['state'] ?? 'California',
      active: json['active'] ?? true,
      checkBox: json['checkBox'] ?? false,
      dropdown: json['dropdown'] ?? 2,
      started: DateTime.parse(json['started'] ?? '2024-01-01 09:53:20'),
      lastName: json['lastName'] ?? 'Alfreds',
      password: json['password'] ?? 'some_thing_goes_here',
      jsonEditor: json['jsonEditor'] ?? {"some": "data"},
      description: json['description'] ?? 'this is a long text',
      customdial: (json['customdial'] ?? 25.0).toDouble(),
      selectedList: List<int>.from(json['selectedList'] ?? [1, 2, 3]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'label': label,
      'state': state,
      'active': active,
      'checkBox': checkBox,
      'dropdown': dropdown,
      'started': DateFormat('yyyy-MM-dd HH:mm:ss').format(started),
      'lastName': lastName,
      'password': password,
      'jsonEditor': jsonEditor,
      'description': description,
      'customdial': customdial,
      'selectedList': selectedList,
    };
  }
}

class PlanMapForm extends StatefulWidget {
  @override
  _PlanMapFormState createState() => _PlanMapFormState();
}

class _PlanMapFormState extends State<PlanMapForm> {
  final _formKey = GlobalKey<FormState>();
  late PlanMapModel model;

  // Controller for the JSON editor
  TextEditingController jsonController = TextEditingController();

  // Controllers for text fields
  TextEditingController cityController = TextEditingController();
  TextEditingController labelController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // Dropdown options
  final List<String> stateOptions = ['California', 'New York', 'Texas', 'Florida'];
  final List<int> dropdownOptions = [1, 2, 3, 4, 5];

  // Options for the selectedList
  final List<int> availableListOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  void initState() {
    super.initState();

    // Initialize the model with default values
    model = PlanMapModel(
      started: DateTime.parse('2024-01-01 09:53:20'),
    );

    // Set initial values for controllers
    cityController.text = model.city;
    labelController.text = model.label;
    lastNameController.text = model.lastName;
    passwordController.text = model.password;
    descriptionController.text = model.description;
    jsonController.text = JsonEncoder.withIndent('  ').convert(model.jsonEditor);
  }

  @override
  void dispose() {
    cityController.dispose();
    labelController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    descriptionController.dispose();
    jsonController.dispose();
    super.dispose();
  }

  // Helper method to create a form field wrapper with consistent styling
  Widget _buildFormField(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          field,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Map'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid layout with 2 columns
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 3, // Adjust this for field height
                children: [
                  // City widget
                  _buildFormField(
                    'City',
                    TextFormField(
                      controller: cityController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter city name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          model.city = value;
                        });
                      },
                    ),
                  ),

                  // Label widget
                  _buildFormField(
                    'Label',
                    TextFormField(
                      controller: labelController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter label',
                      ),
                      onChanged: (value) {
                        setState(() {
                          model.label = value;
                        });
                      },
                    ),
                  ),

                  // State dropdown widget
                  _buildFormField(
                    'State',
                    DropdownButtonFormField<String>(
                      value: model.state,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: stateOptions.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          model.state = value!;
                        });
                      },
                    ),
                  ),

                  // Active switch widget
                  _buildFormField(
                    'Active',
                    SwitchListTile(
                      title: Text(model.active ? 'Active' : 'Inactive'),
                      value: model.active,
                      onChanged: (value) {
                        setState(() {
                          model.active = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  // Checkbox widget
                  _buildFormField(
                    'Check Box',
                    CheckboxListTile(
                      title: Text(model.checkBox ? 'Checked' : 'Unchecked'),
                      value: model.checkBox,
                      onChanged: (value) {
                        setState(() {
                          model.checkBox = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  // Dropdown numeric widget
                  _buildFormField(
                    'Dropdown Selection',
                    DropdownButtonFormField<int>(
                      value: model.dropdown,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: dropdownOptions.map((int option) {
                        return DropdownMenuItem<int>(
                          value: option,
                          child: Text(option.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          model.dropdown = value!;
                        });
                      },
                    ),
                  ),

                  // DateTime widget
                  _buildFormField(
                    'Started Date',
                    InkWell(
                      onTap: () {
                        DatePicker.showDateTimePicker(
                          context,
                          showTitleActions: true,
                          onChanged: (date) {},
                          onConfirm: (date) {
                            setState(() {
                              model.started = date;
                            });
                          },
                          currentTime: model.started,
                        );
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm:ss').format(model.started),
                        ),
                      ),
                    ),
                  ),

                  // Last Name widget
                  _buildFormField(
                    'Last Name',
                    TextFormField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter last name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          model.lastName = value;
                        });
                      },
                    ),
                  ),

                  // Password widget
                  _buildFormField(
                    'Password',
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter password',
                      ),
                      onChanged: (value) {
                        setState(() {
                          model.password = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Widgets that span both columns (full width)
              SizedBox(height: 16),

              // JSON Editor widget (spans full width)
              _buildFormField(
                'JSON Editor',
                Container(
                  height: 150,
                  child: TextFormField(
                    controller: jsonController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Edit JSON',
                    ),
                    onChanged: (value) {
                      try {
                        Map<String, dynamic> json = jsonDecode(value);
                        setState(() {
                          model.jsonEditor = json;
                        });
                      } catch (e) {
                        // Handle JSON parsing error
                        print('Invalid JSON: $e');
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Description widget (rich text/multiline)
              _buildFormField(
                'Description',
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter description',
                  ),
                  onChanged: (value) {
                    setState(() {
                      model.description = value;
                    });
                  },
                ),
              ),

              SizedBox(height: 16),

              // Custom dial widget
              _buildFormField(
                'Custom Dial: ${model.customdial.toStringAsFixed(1)}',
                Slider(
                  value: model.customdial,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: model.customdial.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      model.customdial = value;
                    });
                  },
                ),
              ),

              SizedBox(height: 16),

              // Selected List widget
              _buildFormField(
                'Selected List',
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: availableListOptions.length,
                    itemBuilder: (context, index) {
                      final option = availableListOptions[index];
                      final isSelected = model.selectedList.contains(option);

                      return CheckboxListTile(
                        title: Text('Option $option'),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected!) {
                              if (!model.selectedList.contains(option)) {
                                model.selectedList.add(option);
                              }
                            } else {
                              model.selectedList.remove(option);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Submit button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Form is valid, save data
                      final jsonData = model.toJson();
                      print(JsonEncoder.withIndent('  ').convert(jsonData));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Form submitted successfully')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 16.0,
                    ),
                    child: Text('Submit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
