import 'dart:async';

import 'package:flutter/material.dart';

class TaskSearchBar extends StatefulWidget {
  const TaskSearchBar({
    super.key,
    required this.onChanged,
    required this.onClear,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<TaskSearchBar> createState() => _TaskSearchBarState();
}

class _TaskSearchBarState extends State<TaskSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _onClear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onChanged('');
    widget.onClear();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('taskSearchField'),
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar tareas...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                key: const Key('clearSearchBtn'),
                icon: const Icon(Icons.clear),
                onPressed: _onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
