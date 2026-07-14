import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentGatewayException implements Exception {
  PaymentGatewayException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PaymentSuccessData {
  const PaymentSuccessData({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

class PaymentGateway {
  Razorpay? _razorpay;
  Completer<PaymentSuccessData>? _completer;

  Future<PaymentSuccessData> open({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String passengerName,
    required String passengerMobile,
    required String description,
  }) async {
    if (keyId.trim().isEmpty) {
      throw PaymentGatewayException(
        'UPI payment is not configured. Please choose Cash or contact support.',
      );
    }
    if (_completer != null && !_completer!.isCompleted) {
      throw PaymentGatewayException('A payment window is already open.');
    }

    final razorpay = Razorpay();
    _razorpay = razorpay;
    final completer = Completer<PaymentSuccessData>();
    _completer = completer;

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (dynamic raw) {
      final response = raw as PaymentSuccessResponse;
      if (!completer.isCompleted) {
        completer.complete(
          PaymentSuccessData(
            paymentId: response.paymentId ?? '',
            orderId: response.orderId ?? orderId,
            signature: response.signature ?? '',
          ),
        );
      }
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic raw) {
      final response = raw as PaymentFailureResponse;
      if (!completer.isCompleted) {
        completer.completeError(
          PaymentGatewayException(
            response.message ?? 'Payment was cancelled or failed.',
          ),
        );
      }
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (dynamic raw) {
      final response = raw as ExternalWalletResponse;
      if (!completer.isCompleted) {
        completer.completeError(
          PaymentGatewayException(
            'External wallet ${response.walletName ?? ''} is not supported for this ride.',
          ),
        );
      }
    });

    razorpay.open(<String, dynamic>{
      'key': keyId,
      'order_id': orderId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'ASTRIDE',
      'description': description,
      'prefill': <String, dynamic>{
        'name': passengerName,
        'contact': passengerMobile,
      },
      'theme': <String, dynamic>{'color': '#0D1B3D'},
      'retry': <String, dynamic>{'enabled': true, 'max_count': 2},
    });

    try {
      return await completer.future;
    } finally {
      razorpay.clear();
      if (identical(_razorpay, razorpay)) _razorpay = null;
      if (identical(_completer, completer)) _completer = null;
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    final completer = _completer;
    _completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(PaymentGatewayException('Payment window closed.'));
    }
  }
}
