import 'package:flutter/material.dart';

class BookingForm extends StatelessWidget {
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final TextEditingController totalPriceController;
  final Function onSubmit;

  const BookingForm({
    Key? key,
    required this.startDateController,
    required this.endDateController,
    required this.totalPriceController,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Property'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: startDateController,
              decoration: InputDecoration(labelText: 'Start Date'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: endDateController,
              decoration: InputDecoration(labelText: 'End Date'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: totalPriceController,
              decoration: InputDecoration(labelText: 'Total Price'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onSubmit(),
              child: Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
