import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/theme/app_theme.dart';
import 'package:slot_1_tasks/features/auth/presentation/welcome_page.dart';

void main() {
  testWidgets('Welcome screen renders journey CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.harmonious,
        home: const WelcomePage(),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.startJourney), findsOneWidget);
    expect(find.textContaining('Already have an account'), findsOneWidget);
  });
}
