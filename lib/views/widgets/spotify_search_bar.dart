import 'package:flutter/material.dart';

class SpotifySearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final String hint;

  const SpotifySearchBar({super.key, required this.onSearch, this.hint = "Rechercher un titre, un artiste..."});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onSubmitted: onSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1DB954)),
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}