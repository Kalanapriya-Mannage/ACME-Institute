import 'package:flutter/material.dart';
class BackButtonHeader extends StatelessWidget { const BackButtonHeader({super.key}); @override Widget build(BuildContext context)=>IconButton(onPressed:()=>Navigator.maybePop(context), icon:const Icon(Icons.arrow_back, color:Colors.white)); }
