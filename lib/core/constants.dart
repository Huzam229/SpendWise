import 'package:flutter/material.dart';

import '../data/models/category.dart';

const List<Category> kCategories = [
  Category(name: 'Food', icon: Icons.restaurant, color: Colors.orange),
  Category(name: 'Transport', icon: Icons.directions_car, color: Colors.blue),
  Category(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.purple),
  Category(name: 'Bills', icon: Icons.receipt_long, color: Colors.red),
  Category(name: 'Health', icon: Icons.favorite, color: Colors.pink),
  Category(name: 'Salary', icon: Icons.account_balance_wallet, color: Colors.green),
  Category(name: 'Other', icon: Icons.more_horiz, color: Colors.grey),
];
