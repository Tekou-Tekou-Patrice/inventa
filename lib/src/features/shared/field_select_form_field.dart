import 'package:flutter/material.dart';

import '../../state/plantation_state.dart';

class FieldSelectFormField extends StatelessWidget {
  const FieldSelectFormField({
    required this.state,
    required this.onSaved,
    super.key,
  });

  final PlantationState state;
  final ValueChanged<String?> onSaved;

  @override
  Widget build(BuildContext context) {
    final initialFieldId =
        state.selectedFieldId ??
        (state.fields.length == 1 ? state.fields.single.id : null);
    return DropdownButtonFormField<String>(
      initialValue: initialFieldId,
      decoration: const InputDecoration(labelText: 'Champ concerné'),
      items: [
        for (final field in state.fields)
          DropdownMenuItem(value: field.id, child: Text(field.name)),
      ],
      validator: (value) =>
          value == null ? 'Sélectionnez ou créez un champ' : null,
      onChanged: (_) {},
      onSaved: onSaved,
    );
  }
}
