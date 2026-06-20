import 'package:flutter/material.dart';
class GradeBoxCard extends StatelessWidget { final int grade; const GradeBoxCard({super.key, required this.grade}); @override Widget build(BuildContext context)=>Card(child:ListTile(title:Text('Grade $grade'))); }
