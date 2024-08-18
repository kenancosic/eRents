import 'package:flutter/material.dart';

class PaymentSummary extends StatelessWidget {
  final String paymentMethod;
  final double amount;
  final String paymentStatus;

  const PaymentSummary({
    required this.paymentMethod,
    required this.amount,
    required this.paymentStatus,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method: $paymentMethod', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Amount: \$${amount.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text('Status: $paymentStatus', style: TextStyle(color: paymentStatus == 'Success' ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }
}
