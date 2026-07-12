import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Горная Саланга'**
  String get appTitle;

  /// No description provided for @onboardingTitle1.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In ru, this message translates to:
  /// **'Ваш персональный гид по курорту Горная Саланга.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы и QR'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In ru, this message translates to:
  /// **'Копите бонусы и показывайте QR-код на кассе.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ru, this message translates to:
  /// **'Всё под рукой'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In ru, this message translates to:
  /// **'Погода, трассы, веб-камеры и уведомления в одном приложении.'**
  String get onboardingBody3;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get skip;

  /// No description provided for @start.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get start;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get register;

  /// No description provided for @verify.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение'**
  String get verify;

  /// No description provided for @email.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get phone;

  /// No description provided for @code.
  ///
  /// In ru, this message translates to:
  /// **'Код подтверждения'**
  String get code;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerButton;

  /// No description provided for @verifyButton.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get verifyButton;

  /// No description provided for @noAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт?'**
  String get hasAccount;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @bonus.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get bonus;

  /// No description provided for @catalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get catalog;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @qrCode.
  ///
  /// In ru, this message translates to:
  /// **'QR-код'**
  String get qrCode;

  /// No description provided for @weather.
  ///
  /// In ru, this message translates to:
  /// **'Погода'**
  String get weather;

  /// No description provided for @trails.
  ///
  /// In ru, this message translates to:
  /// **'Трассы'**
  String get trails;

  /// No description provided for @webcams.
  ///
  /// In ru, this message translates to:
  /// **'Веб-камеры'**
  String get webcams;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @contact.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get contact;

  /// No description provided for @balance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс бонусов'**
  String get balance;

  /// No description provided for @refreshQr.
  ///
  /// In ru, this message translates to:
  /// **'Обновить QR'**
  String get refreshQr;

  /// No description provided for @qrExpiresIn.
  ///
  /// In ru, this message translates to:
  /// **'QR действителен ещё {seconds} сек'**
  String qrExpiresIn(int seconds);

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get errorGeneric;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @guestName.
  ///
  /// In ru, this message translates to:
  /// **'Гость'**
  String get guestName;

  /// No description provided for @bonusPoints.
  ///
  /// In ru, this message translates to:
  /// **'{points} бонусов'**
  String bonusPoints(int points);

  /// No description provided for @catalogPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Каталог услуг курорта скоро будет доступен.'**
  String get catalogPlaceholder;

  /// No description provided for @weatherPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Данные о погоде загружаются с сервера.'**
  String get weatherPlaceholder;

  /// No description provided for @trailsPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Информация о трассах скоро будет доступна.'**
  String get trailsPlaceholder;

  /// No description provided for @webcamsPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Прямые трансляции с камер курорта.'**
  String get webcamsPlaceholder;

  /// No description provided for @notificationsPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Здесь будут ваши уведомления.'**
  String get notificationsPlaceholder;

  /// No description provided for @contactPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Свяжитесь с администрацией курорта.'**
  String get contactPlaceholder;

  /// No description provided for @profilePlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Настройки профиля и личные данные.'**
  String get profilePlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
