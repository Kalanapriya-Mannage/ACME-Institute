import 'package:flutter/material.dart';
class TeacherRectangleCard extends StatelessWidget { final String title; final String subtitle; const TeacherRectangleCard({super.key, required this.title, required this.subtitle}); @override Widget build(BuildContext context)=>Card(child:ListTile(title:Text(title), subtitle:Text(subtitle))); }
