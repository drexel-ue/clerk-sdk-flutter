// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:widgetbook_workspace/cool_button.dart' as _i2;
import 'package:widgetbook_workspace/widgets/authentication/clerk_sign_in_widget.dart'
    as _i3;
import 'package:widgetbook_workspace/widgets/authentication/clerk_sign_up_widget.dart'
    as _i4;
import 'package:widgetbook_workspace/widgets/user/clerk_user_button.dart'
    as _i5;
import 'package:widgetbook_workspace/widgets/user/clerk_user_profile_widget.dart'
    as _i6;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookLeafComponent(
    name: 'CoolButton',
    useCase: _i1.WidgetbookUseCase(
      name: 'Default',
      builder: _i2.buildCoolButtonUseCase,
    ),
  ),
  _i1.WidgetbookFolder(
    name: 'widgets',
    children: [
      _i1.WidgetbookFolder(
        name: 'authentication',
        children: [
          _i1.WidgetbookLeafComponent(
            name: 'ClerkSignInWidget',
            useCase: _i1.WidgetbookUseCase(
              name: 'Authentication',
              builder: _i3.buildClerkSignInWidgetUseCase,
            ),
          ),
          _i1.WidgetbookLeafComponent(
            name: 'ClerkSignUpWidget',
            useCase: _i1.WidgetbookUseCase(
              name: 'Authentication',
              builder: _i4.buildClerkSignUpWidgetUseCase,
            ),
          ),
        ],
      ),
      _i1.WidgetbookFolder(
        name: 'user',
        children: [
          _i1.WidgetbookLeafComponent(
            name: 'ClerkUserButton',
            useCase: _i1.WidgetbookUseCase(
              name: 'User',
              builder: _i5.buildClerkUserButtonUseCase,
            ),
          ),
          _i1.WidgetbookLeafComponent(
            name: 'ClerkUserProfileWidget',
            useCase: _i1.WidgetbookUseCase(
              name: 'User',
              builder: _i6.buildClerkUserProfileWidgetUseCase,
            ),
          ),
        ],
      ),
    ],
  ),
];
