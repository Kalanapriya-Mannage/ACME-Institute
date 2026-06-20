import 'package:flutter/material.dart';

class SummaryStatBox extends StatelessWidget {
	final IconData icon;
	final String number;
	final String label;

	const SummaryStatBox({
		super.key,
		required this.icon,
		required this.number,
		required this.label,
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(10),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [Icon(icon), const SizedBox(height: 6), Text(number), const SizedBox(height: 4), Text(label)],
				),
			),
		);
	}
}
