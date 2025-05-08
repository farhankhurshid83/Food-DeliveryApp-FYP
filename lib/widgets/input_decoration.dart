import 'package:flutter/material.dart';

InputDecoration customInputDecoration({required String hintText, Widget? suffixIcon}) {
  return InputDecoration(
    filled: true,
    fillColor: Color(0xfffff5c3),
    hintText: hintText,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    suffixIcon: suffixIcon,
  );
}
