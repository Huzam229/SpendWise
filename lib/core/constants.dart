import 'package:flutter/material.dart';

import '../data/models/category.dart';

const List<Category> kExpenseCategories = [
  Category(name: 'Food', icon: Icons.restaurant, color: Colors.orange),
  Category(name: 'Transport', icon: Icons.directions_car, color: Colors.blue),
  Category(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.purple),
  Category(name: 'Bills', icon: Icons.receipt_long, color: Colors.red),
  Category(name: 'Health', icon: Icons.favorite, color: Colors.pink),
  Category(name: 'Other', icon: Icons.more_horiz, color: Colors.grey),
];

const List<Category> kIncomeCategories = [
  Category(
    name: 'Salary',
    icon: Icons.account_balance_wallet,
    color: Colors.green,
  ),
  Category(name: 'Freelance', icon: Icons.laptop_mac, color: Colors.teal),
  Category(name: 'Investment', icon: Icons.trending_up, color: Colors.indigo),
  Category(name: 'Gift', icon: Icons.card_giftcard, color: Colors.amber),
  Category(name: 'Other', icon: Icons.more_horiz, color: Colors.grey),
];

/// All categories used for lookup in lists/charts.
const List<Category> kCategories = [
  ...kExpenseCategories,
  Category(
    name: 'Salary',
    icon: Icons.account_balance_wallet,
    color: Colors.green,
  ),
  Category(name: 'Freelance', icon: Icons.laptop_mac, color: Colors.teal),
  Category(name: 'Investment', icon: Icons.trending_up, color: Colors.indigo),
  Category(name: 'Gift', icon: Icons.card_giftcard, color: Colors.amber),
];

List<Category> categoriesFor({required bool isIncome}) {
  return isIncome ? kIncomeCategories : kExpenseCategories;
}
