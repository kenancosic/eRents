import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../routes/base_screen.dart';
import '../../utils/helpers.dart';

class PaymentScreen extends StatelessWidget {
  final double amount;
  final String currency;

  PaymentScreen({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Payment',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<PaymentProvider>(
          builder: (context, provider, child) {
            if (provider.state == ViewState.Busy) {
              return Center(child: CircularProgressIndicator());
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Amount: $amount $currency'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    bool success = await provider.makePayment(amount, currency);
                    if (success) {
                      showSnackBar(context, 'Payment successful!');
                      Navigator.pop(context);  // Navigate back after payment
                    } else {
                      showSnackBar(context, provider.errorMessage ?? 'Payment failed');
                    }
                  },
                  child: Text('Pay Now'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
