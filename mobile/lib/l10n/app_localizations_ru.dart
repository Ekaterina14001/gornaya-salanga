// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Горная Саланга';

  @override
  String get onboardingTitle1 => 'Добро пожаловать';

  @override
  String get onboardingBody1 =>
      'Ваш персональный гид по курорту Горная Саланга.';

  @override
  String get onboardingTitle2 => 'Бонусы и QR';

  @override
  String get onboardingBody2 => 'Копите бонусы и показывайте QR-код на кассе.';

  @override
  String get onboardingTitle3 => 'Всё под рукой';

  @override
  String get onboardingBody3 =>
      'Погода, трассы, веб-камеры и уведомления в одном приложении.';

  @override
  String get next => 'Далее';

  @override
  String get skip => 'Пропустить';

  @override
  String get start => 'Начать';

  @override
  String get login => 'Вход';

  @override
  String get register => 'Регистрация';

  @override
  String get verify => 'Подтверждение';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get phone => 'Телефон';

  @override
  String get code => 'Код подтверждения';

  @override
  String get loginButton => 'Войти';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get verifyButton => 'Подтвердить';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get hasAccount => 'Уже есть аккаунт?';

  @override
  String get home => 'Главная';

  @override
  String get bonus => 'Бонусы';

  @override
  String get catalog => 'Каталог';

  @override
  String get profile => 'Профиль';

  @override
  String get qrCode => 'QR-код';

  @override
  String get bookRoom => 'Забронировать номер';

  @override
  String get installAppTitle => 'Установить приложение';

  @override
  String get installAppButton => 'Установить';

  @override
  String get installAppHint =>
      'Добавьте на главный экран — так открывать курорт будет быстрее.';

  @override
  String get installAppIosHint =>
      'Safari → Поделиться → «На экран Домой» → Добавить.';

  @override
  String get installAppAndroidHint =>
      'Chrome → меню ⋮ → «Установить приложение» или «Добавить на главный экран».';

  @override
  String get weather => 'Погода';

  @override
  String get trails => 'Трассы';

  @override
  String get webcams => 'Веб-камеры';

  @override
  String get notifications => 'Уведомления';

  @override
  String get contact => 'Контакты';

  @override
  String get balance => 'Баланс бонусов';

  @override
  String get refreshQr => 'Обновить QR';

  @override
  String qrExpiresIn(int seconds) {
    return 'QR действителен ещё $seconds сек';
  }

  @override
  String get loading => 'Загрузка…';

  @override
  String get errorGeneric => 'Что-то пошло не так';

  @override
  String get retry => 'Повторить';

  @override
  String get logout => 'Выйти';

  @override
  String get guestName => 'Гость';

  @override
  String bonusPoints(int points) {
    return '$points бонусов';
  }

  @override
  String get catalogPlaceholder =>
      'Каталог услуг курорта скоро будет доступен.';

  @override
  String get weatherPlaceholder => 'Данные о погоде загружаются с сервера.';

  @override
  String get trailsPlaceholder => 'Информация о трассах скоро будет доступна.';

  @override
  String get webcamsPlaceholder => 'Прямые трансляции с камер курорта.';

  @override
  String get notificationsPlaceholder => 'Здесь будут ваши уведомления.';

  @override
  String get contactPlaceholder => 'Свяжитесь с администрацией курорта.';

  @override
  String get profilePlaceholder => 'Настройки профиля и личные данные.';
}
