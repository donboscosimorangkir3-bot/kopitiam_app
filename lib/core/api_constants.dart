class ApiConstants {
  // Jika pakai Emulator Android, gunakan 10.0.2.2
  // Jika pakai HP Fisik, gunakan IP Laptop (misal: 192.168.1.10)
static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Endpoint Auth
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  
  // Endpoint Data
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/categories';
  static const String cart = '$baseUrl/cart';
  static const String checkout = '$baseUrl/checkout';
}