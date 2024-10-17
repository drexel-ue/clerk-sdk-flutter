import 'package:clerk_flutter/src/common.dart';
import 'package:flutter/material.dart';

import 'clerk_auth.dart';

/// A widget that builds its child only if we are signed in
/// i.e. a user is present on the client
class ClerkSignedIn extends StatelessWidget {
  final Widget child;

  const ClerkSignedIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final client = ClerkAuth.of(context).clientSync;

    if (client.user != null) {
      return child;
    }

    return emptyWidget;
  }
}