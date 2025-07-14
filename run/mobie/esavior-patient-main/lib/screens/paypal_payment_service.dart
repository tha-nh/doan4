import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';

class PayPalPaymentService {
  static const String _clientId = "AeG-ZT8O4yhQvzCBjVp-w4bNu4oa0O1u7CIMWVg5MBDGmWQ3KwgQuDASxQup6DqOCCuo1QKILXWt4rUD";
  static const String _secretKey = ""; // Thay bằng secret key thực tế
  static const bool _sandboxMode = true; // false cho production

  static void makePayment({
    required BuildContext context,
    required String amount,
    required String currency,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
    required Function() onCancel,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => PaypalCheckoutView(
          sandboxMode: _sandboxMode,
          clientId: _clientId,
          secretKey: _secretKey,
          transactions: [
            {
              "amount": {
                "total": amount,
                "currency": currency,
                "details": {
                  "subtotal": amount,
                  "tax": '0',
                  "shipping": '0',
                  "handling_fee": '0',
                  "shipping_discount": '0',
                  "insurance": '0',
                }
              },
              "description": "Medical Appointment Payment",
              "item_list": {
                "items": [
                  {
                    "name": "Medical Consultation",
                    "quantity": 1,
                    "price": amount,
                    "currency": currency
                  }
                ],
              }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            print("Payment Success: $params");
            // Cast Map<dynamic, dynamic> to Map<String, dynamic>
            final Map<String, dynamic> castedParams = Map<String, dynamic>.from(params);
            onSuccess(castedParams);
          },
          onError: (error) {
            print("Payment Error: $error");
            onError(error.toString());
          },
          onCancel: () {
            print('Payment Cancelled');
            onCancel();
          },
        ),
      ),
    );
  }
}