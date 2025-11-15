// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serve_to_be_free/core/services/auth_service.dart';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/core/services/user_service.dart';
import 'package:serve_to_be_free/core/services/project_service.dart';

import 'package:serve_to_be_free/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize services
    final mqttService = MqttService();
    final authService = AuthService(mqttService);
    final userService = UserService(mqttService);
    final projectService = ProjectService(mqttService);

    await tester.pumpWidget(MainApp(
      mqttService: mqttService,
      authService: authService,
      userService: userService,
      projectService: projectService,
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
