import 'package:flutter/material.dart';
import 'order_placed_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressConfirmScreen()));
          },
          child: const Text('Proceed to Address'),
        ),
      ),
    );
  }
}

class AddressConfirmScreen extends StatelessWidget {
  const AddressConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Address')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
          },
          child: const Text('Proceed to Payment'),
        ),
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Mock placing order with COD
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderPlacedScreen()));
              },
              child: const Text('Pay with COD'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Mock placing order with UPI
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderPlacedScreen()));
              },
              child: const Text('Pay with UPI'),
            ),
          ],
        ),
      ),
    );
  }
}
