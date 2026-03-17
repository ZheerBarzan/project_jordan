import 'package:flutter/material.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/services/auth_services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('PROFILE', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(
              'Profile stays as-is for this redesign pass.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            MyButtons(
              ontap: () => AuthService().signOut(),
              text: "Sign Out",
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
