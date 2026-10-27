/// Разделы каталога (пункты меню — черновик, список можно менять).
enum CatalogSection {
  about,
  services,
  schedule,
  visitRules,
  bonusRules,
}

class CatalogSectionItem {
  const CatalogSectionItem(this.section, this.label);

  final CatalogSection section;
  final String label;
}

/// Группы карточек на экране выбора раздела (как в макете).
const catalogSectionGroups = <List<CatalogSectionItem>>[
  [
    CatalogSectionItem(CatalogSection.services, 'Услуги'),
    CatalogSectionItem(CatalogSection.schedule, 'Расписание'),
  ],
  [
    CatalogSectionItem(CatalogSection.about, 'О курорте'),
    CatalogSectionItem(CatalogSection.visitRules, 'Правила'),
    CatalogSectionItem(CatalogSection.bonusRules, 'Бонусы'),
  ],
];

String catalogSectionTitle(CatalogSection section) {
  for (final group in catalogSectionGroups) {
    for (final item in group) {
      if (item.section == section) return item.label;
    }
  }
  return '';
}
