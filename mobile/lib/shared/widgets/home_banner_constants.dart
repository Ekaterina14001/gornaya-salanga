const kHomeBannerGap = 10.0;
const kHomeBannerRadius = 20.0;

/// Сколько «торчит» следующий баннер справа (подсказка, что можно листать).
const kHomeCarouselPeek = 56.0;

/// Ширина одной плитки: почти весь экран минус peek следующего.
double kHomeCarouselPageWidth(double maxWidth) =>
    maxWidth - kHomeCarouselPeek - kHomeBannerGap;

/// Доля PageView: один слайд целиком + часть следующего.
double kHomeCarouselViewportFraction(double maxWidth) {
  if (maxWidth <= 0) return 0.88;
  return (kHomeCarouselPageWidth(maxWidth) / maxWidth).clamp(0.72, 0.92);
}

/// Нижняя карусель: высота плитки ~ квадрат по ширине активного слайда.
double kHomeCarouselTileHeight(double width) {
  final tileW = kHomeCarouselPageWidth(width);
  return tileW.clamp(150.0, 240.0);
}

/// Верхний промо-блок «Забронировать»: почти кварат, слоганы сверху.
double kHomeTopBannerHeight(double width) =>
    width.clamp(280.0, 420.0);
