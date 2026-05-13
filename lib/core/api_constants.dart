class ApiConstants {
  // Jika pakai Emulator Android, gunakan 10.0.2.2
  // Jika pakai HP Fisik, gunakan IP Laptop (misal: 192.168.1.10)
<<<<<<< HEAD
  static const String baseUrl = 'http://192.168.141.5:8000/api';

=======
static const String baseUrl = 'http://10.43.144.213:8000/api';
  
>>>>>>> fddf7d61684dff125eae5764d4f1a57dc3cbfea4
  // Endpoint Auth
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';

  // Endpoint Data
  static const String products = '$baseUrl/products';
  static const String buyNow = '$baseUrl/orders/buy-now';
  static const String categories = '$baseUrl/categories';
  static const String cart = '$baseUrl/cart';
  static const String checkout = '$baseUrl/checkout';
<<<<<<< HEAD
}
=======
  static const String orders = '$baseUrl/orders';
}
>>>>>>> fddf7d61684dff125eae5764d4f1a57dc3cbfea4
