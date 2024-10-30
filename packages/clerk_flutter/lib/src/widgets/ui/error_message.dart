import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

class ErrorMessage extends StatefulWidget {
  final String? error;

  const ErrorMessage({super.key, this.error});

  @override
  State<ErrorMessage> createState() => _ErrorMessageState();
}

class _ErrorMessageState extends State<ErrorMessage> {
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setErrorMessage();
  }

  @override
  void didUpdateWidget(covariant ErrorMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setErrorMessage();
  }

  void _setErrorMessage() {
    if (widget.error case String error) {
      errorMessage = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final translator = ClerkAuth.translatorOf(context);
    return Closeable(
      open: widget.error is String,
      child: Padding(
        padding: horizontalPadding32 + bottomPadding8,
        child: Text(
          translator.translate(errorMessage),
          textAlign: TextAlign.left,
          maxLines: 2,
          style: ClerkTextStyle.error,
        ),
      ),
    );
  }
}
