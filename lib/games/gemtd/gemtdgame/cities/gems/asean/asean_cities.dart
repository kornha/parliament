part of 'asean.dart';

const asean_cities = <CityConfig>{
  cambodia,
  vietnam,
  philippines,
  indonesia,
  malaysia,
  thailand,
};

const cambodia = (level: 1, city: "Cambodia", countryCode: "KH");
const vietnam = (level: 2, city: "Vietnam", countryCode: "VN");
const philippines = (level: 3, city: "Philippines", countryCode: "PH");
const indonesia = (level: 4, city: "Indonesia", countryCode: "ID");
const malaysia = (level: 5, city: "Malaysia", countryCode: "MY");
const thailand = (level: 6, city: "Thailand", countryCode: "TH");

// Backward-compat alias for the Hanoi special (hanoi.dart, left untouched),
// whose recipe references the tier-1 ASEAN config by its old name.
const phnom_penh = cambodia;
