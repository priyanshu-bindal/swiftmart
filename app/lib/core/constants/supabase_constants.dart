class SupabaseConstants {
  // You should ideally load these from environment variables in a real app (.env)
  static const String supabaseUrl = 'https://wfbxhuuvstahijtwsraf.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4';

  // Table names — profile row for auth (same as `users`, or `profiles` if you run that migration)
  static const String profileTable = 'profiles';
  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String ordersTable = 'orders';
  static const String couponsTable = 'coupons';
  static const String flashDealsTable = 'flash_deals';
  static const String bannersTable = 'banners';
  static const String homeConfigTable = 'home_config';
  static const String addressesTable = 'addresses';
  static const String deliveryPartnersTable = 'delivery_partners';

  // Edge Functions
  static const String validateCouponFn = 'validate-CouponModel';
  static const String placeOrderFn = 'place-OrderModel';
}
