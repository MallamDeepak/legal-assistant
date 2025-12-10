import 'package:flutter/material.dart';

class LanguageSelectorDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const LanguageSelectorDropdown({Key? key, required this.value, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'hi', child: Text('Hindi')),
      ],
      onChanged: onChanged,
    );
  }
}
