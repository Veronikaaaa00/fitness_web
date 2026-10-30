import 'package:flutter/material.dart';

class StringOption {
  const StringOption({required this.id, required this.label});
  final String id;
  final String label;
}

class StringMultiSelectField extends StatelessWidget {
  const StringMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<StringOption> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: options.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Нет доступных значений'),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((o) {
                final selected = value.contains(o.id);
                return FilterChip(
                  label: Text(o.label),
                  selected: selected,
                  onSelected: (_) {
                    final next = [...value];
                    selected ? next.remove(o.id) : next.add(o.id);
                    onChanged(next);
                  },
                );
              }).toList(),
            ),
    );
  }
}
