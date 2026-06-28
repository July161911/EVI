import 'package:flutter/cupertino.dart';
import 'package:material_query_app/config/auth_config.dart';
import 'package:material_query_app/theme/app_theme.dart';
import 'package:material_query_app/widgets/common_widgets.dart';

class CorporateEmailField extends StatelessWidget {
  const CorporateEmailField({
    super.key,
    required this.controller,
    this.placeholder = '请输入邮箱',
  });

  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AuthConfig.emailDomain,
          style: AppTheme.secondary.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}
