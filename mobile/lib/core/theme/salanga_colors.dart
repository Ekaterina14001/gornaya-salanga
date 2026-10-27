import 'package:flutter/material.dart';

/// Brand palette from salanga.ru (main.css / app.css).
abstract final class SalangaColors {
  static const green = Color(0xFF9CBF00);
  static const greenDark = Color(0xFF77AF0F);
  static const burgundy = Color(0xFF7A0030);
  static const burgundyHover = Color(0xFFED1A3B);
  static const cream = Color(0xFFFFF2D6);
  static const sand = Color(0xFFE1D1C5);
  static const warmBrown = Color(0xFFAA896F);
  static const border = Color(0xFFC3AD9C);
  static const textPrimary = Color(0xFF524B48);
  static const textDark = Color(0xFF221B15);
  static const textHeading = Color(0xFFAA896F);
  static const surface = Color(0xFFFFFFFF);
  static const pageBackground = Color(0xFFF6F1E8);
  static const navBar = Color(0xFFCBB5A1);
  /// Подсветка активной/нажатой вкладки (прямоугольник на всю высоту).
  static const navBarSelected = Color(0xFFAC9183);
  static const navBarInactive = Color(0xFF8C786C);
  static const navBarActive = Color(0xFFE8D7B8);

  /// Пункты меню на главной (макет Open Sans 29).
  static const menuText = Color(0xFF7B6A58);
  static const menuIcon = Color(0xFFB38C6D);
  static const menuDivider = Color(0xFFCBB7A0);

  /// Плашка бонусов на главной (макет).
  static const bonusPlaqueBg = Color(0xFFCBB4A0);
  static const bonusPlaqueInk = Color(0xFF634E42);

  /// Меню разделов каталога (тёмная панель на макете).
  static const catalogHubBackground = Color(0xFFAC9183);
  static const catalogHubItem = Color(0xFF957F71);
  static const catalogHubText = Color(0xFFF6F1E8);
  static const catalogHubChevron = Color(0xFFE8D7B8);

  /// Карточки прайса «Услуги» / «Прокат» (макет с hex-подписями).
  static const priceCardHeaderBg = Color(0xFFCBB5A1);
  static const priceCardHeaderText = Color(0xFF7B6A58);
  static const priceCardBodyBg = Color(0xFFF6F1E8);
  static const priceCardRowText = Color(0xFF644F43);
  static const priceCardGroupTitle = Color(0xFF7C6B59);
  static const priceCardRentalColumn = Color(0xFFB18D67);
  static const priceCardDivider = Color(0xFFCBB7A0);
}
