//

typedef CityConfig = ({
  String city,
  String countryCode,
  int level,
});

extension CityConfigSetX on Set<CityConfig> {
  CityConfig getCityConfigByLevelOrLast(int level) => firstWhere(
        (e) => e.level == level,
        orElse: () => last,
      );
}
