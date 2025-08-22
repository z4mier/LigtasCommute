import 'package:flutter/material.dart';

/// ===== THEME (consistent with your screenshot; no purple) =====
const kPrimaryDark = Color(0xFF0F172A); // dark navy
const kTextMain = Colors.black87;
const kBorderGray = Color(0xFFE5E7EB);
const kCardBg = Color(0xFFF8F8F8);
const kReqCardBg = Color(0xFF6B7280); // requirement card bg
const kAccentOrange = Color(0xFFFFC107);

ButtonStyle kPrimaryBtnStyle = ElevatedButton.styleFrom(
  backgroundColor: kPrimaryDark,
  foregroundColor: Colors.white,
  elevation: 0,
  minimumSize: const Size.fromHeight(44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

ButtonStyle kOutlinedBtnStyle = OutlinedButton.styleFrom(
  side: const BorderSide(color: kPrimaryDark, width: 1.2),
  foregroundColor: kPrimaryDark,
  minimumSize: const Size.fromHeight(44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

SnackBar kSnack(String msg) => SnackBar(
  content: Text(msg),
  backgroundColor: kPrimaryDark,
  behavior: SnackBarBehavior.floating,
);

InputDecoration kInput(String label) => InputDecoration(
  labelText: label,
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: kBorderGray),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryDark),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
);
