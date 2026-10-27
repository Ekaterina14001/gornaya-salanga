import 'package:flutter/foundation.dart';

/// Сброс каталога на список разделов (кнопка «Каталог» в нижней панели).
class CatalogHubController extends ChangeNotifier {
  CatalogHubController._();

  static final instance = CatalogHubController._();

  void showMenu() => notifyListeners();
}
