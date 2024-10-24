import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef InputVerifier = Future<bool> Function(String);

class MultiDigitCodeInput extends StatefulWidget {
  const MultiDigitCodeInput({
    super.key,
    required this.onSubmit,
    this.length = 6,
    this.isSmall = false,
  });

  final InputVerifier onSubmit;
  final int length;
  final bool isSmall;

  @override
  State<MultiDigitCodeInput> createState() => _MultiDigitCodeInputState();
}

class _MultiDigitCodeInputState extends State<MultiDigitCodeInput>
    with TextInputClient
    implements AutofillClient {
  late TextEditingValue _editingValue;
  late FocusNode _focusNode;
  TextInputConnection? _connection;
  AutofillGroupState? _currentAutofillScope;

  bool loading = false;

  bool get _hasInputConnection => _connection?.attached ?? false;

  @override
  TextEditingValue? get currentTextEditingValue => _editingValue;

  @override
  AutofillScope? get currentAutofillScope => _currentAutofillScope;

  @override
  String get autofillId => 'NumberInput-$hashCode';

  @override
  TextInputConfiguration get textInputConfiguration {
    return TextInputConfiguration(
      autofillConfiguration: AutofillConfiguration(
        uniqueIdentifier: autofillId,
        autofillHints: const [AutofillHints.oneTimeCode],
        currentEditingValue: _editingValue,
      ),
      inputType: TextInputType.number,
      inputAction: TextInputAction.go,
      autocorrect: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _editingValue = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
      composing: TextRange(start: 0, end: 0),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => requestKeyboard());
    HardwareKeyboard.instance.addHandler(_onHwKeyChanged);
  }

  bool _onHwKeyChanged(KeyEvent event) {
    if (event case KeyUpEvent event when event.logicalKey == LogicalKeyboardKey.backspace) {
      final text = _editingValue.text;
      if (text.isNotEmpty) {
        final newEditingValue = TextEditingValue(
          text: text.substring(0, text.length - 1),
          selection: TextSelection.collapsed(offset: text.length - 1),
        );
        _connection!.setEditingState(newEditingValue);
        setState(() => _editingValue = newEditingValue);
        return true;
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final AutofillGroupState? newAutofillGroup = AutofillGroup.maybeOf(context);
    if (currentAutofillScope != newAutofillGroup) {
      _currentAutofillScope?.unregister(autofillId);
      _currentAutofillScope = newAutofillGroup;
      _currentAutofillScope?.register(this);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openInputConnection();
    } else {
      _closeInputConnectionIfNeeded();
    }
    setState(() {});
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHwKeyChanged);
    _currentAutofillScope?.unregister(autofillId);
    _focusNode.dispose();
    _closeInputConnectionIfNeeded();
    super.dispose();
  }

  @override
  void autofill(TextEditingValue newEditingValue) {
    final value = int.tryParse(newEditingValue.text)?.toString();
    if (value != null) {
      setState(() {
        _editingValue = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return emptyWidget;

    final text = _editingValue.text;
    final color = ClerkColors.midGrey;

    bool isSmall = widget.isSmall;
    if (isSmall == false) {
      final viewQuery = MediaQueryData.fromView(View.of(context));
      viewQuery.size.height - viewQuery.viewInsets.bottom < 400.0;
    }

    final boxSize = isSmall ? 18.0 : 38.0;
    final cursorHeight = isSmall ? 1.0 : 2.0;

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: requestKeyboard,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ClerkColors.dawnPink),
              ),
              child: SizedBox.square(
                dimension: boxSize,
                child: index < text.length
                    ? Align(
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          text[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      )
                    : _focusNode.hasFocus && index == text.length
                        ? _PulsingCursor(height: cursorHeight)
                        : null,
              ),
            );
          }),
        ),
      ),
    );
  }

  void requestKeyboard() {
    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      _openInputConnection();
    }
  }

  void _openInputConnection() {
    if (!_hasInputConnection) {
      _connection = TextInput.attach(this, textInputConfiguration);
      _connection!.setEditingState(_editingValue);
    }
    _connection!.show();
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _connection!.close();
      _connection = null;
    }
  }

  @override
  void performAction(TextInputAction action) {
    _focusNode.unfocus();
  }

  @override
  Future<void> updateEditingValue(TextEditingValue value) async {
    if (value.text.length == widget.length) {
      setState(() => loading = true);
      final succeeded = await widget.onSubmit.call(value.text);
      if (succeeded == false) {
        _editingValue = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
        requestKeyboard();
      }
      setState(() => loading = false);
    } else {
      _editingValue = value;
    }
    _openInputConnection();
    setState(() => _connection!.setEditingState(_editingValue));
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // Not required
  }

  @override
  void connectionClosed() {
    // Not required
  }

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {
    // Not required
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    // Not required
  }

  @override
  void insertTextPlaceholder(Size size) {
    // Not required
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // Not required
  }

  @override
  void performSelector(String selectorName) {
    // Not required
  }

  @override
  void removeTextPlaceholder() {
    // Not required
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // Not required
  }

  @override
  void showToolbar() {
    // Not required
  }
}

class _PulsingCursor extends StatefulWidget {
  const _PulsingCursor({required this.height});

  final double height;

  @override
  State<_PulsingCursor> createState() => _PulsingCursorState();
}

class _PulsingCursorState extends State<_PulsingCursor> with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(milliseconds: 1200);

  void _update() {
    if (mounted) setState(() {});
  }

  late final _controller = AnimationController(duration: _cycleDuration, vsync: this)
    ..repeat(period: _cycleDuration, reverse: true)
    ..addListener(_update);
  late final _curve = CurvedAnimation(parent: _controller, curve: Curves.decelerate);

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: Padding(
        padding: allPadding4,
        child: SizedBox(
          width: double.infinity,
          height: widget.height,
          child: ColoredBox(
            color: Colors.black.withOpacity(_curve.value * 0.5),
          ),
        ),
      ),
    );
  }
}