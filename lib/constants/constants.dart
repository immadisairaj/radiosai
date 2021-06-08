import 'package:flutter/material.dart';

class MyConstants extends InheritedWidget {
  static MyConstants of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyConstants>();

  const MyConstants({Widget child, Key key}) : super(key: key, child: child);

  // The list of radio sai stream sources
  final List<String> radioStreamLink = const [
    'http://stream.radiosai.net:8002',
    'http://stream.radiosai.net:8004',
    'http://stream.radiosai.net:8006',
    'http://stream.radiosai.net:8000',
    'http://stream.radiosai.net:8008',
    'http://stream.radiosai.net:8020'
  ];

  // The list of radio sai stream source names
  final List<String> radioStreamName = const [
    'Asia Stream',
    'Africa Stream',
    'America Stream',
    'Bhajan Stream',
    'Discourse Stream',
    'Telugu Stream',
  ];

  // The list of items in the top menu bar
  final List<String> menuTitles = const [
    'Schedule',
    'Sai Inspires',
    // 'Vedam',
    'Audio Archive',
    'Settings',
    // TODO: might have to remove later
    'Audio Demo',
  ];

  // list of radio streams for radio schedule
  final Map<String, int> scheduleStream = const {
    'Asia Stream': 1,
    'Africa Stream': 3,
    'America Stream': 2,
    'Discourse Stream': 6,
    'Telugu Stream': 5,
  };

  // list of countries for radio sai schedule
  final Map<String, int> timeZones = const {
    'ANTIGUA AND BARBUDA': 89,
    'ARGENTINA': 2,
    'AUSTRALIA NSW': 3,
    'AUSTRIA': 8,
    'BAHRAIN': 9,
    'BELGIUM': 10,
    'BOLIVIA': 11,
    'BOSNIA': 12,
    'BRAZ-EAST': 16,
    'BRAZ-MAT-GROS': 15,
    'BRAZ-NORTH': 17,
    'BRAZ-WEST': 18,
    'BRAZIL-CAP': 13,
    'BRAZIL-FDN': 14,
    'BRITAIN': 82,
    'BULGARIA': 19,
    'CANADA-ALBERTA': 20,
    'CANADA-MANITOBA': 22,
    'CANADA-MONTREAL': 23,
    'CANADA-VANCOUVER': 21,
    'CHILE': 24,
    'COLOMBIA': 25,
    'COSTA RICA': 87,
    'CROATIA': 26,
    'CUBA': 27,
    'ECUADOR': 28,
    'EL SALVADOR': 29,
    'FIJI': 30,
    'GABON': 31,
    'GERMANY': 32,
    'GHANA': 33,
    'GREECE': 34,
    'GUATEMALA': 35,
    'GUYANA': 36,
    'HAITI': 37,
    'HAWAII': 38,
    'HONG KONG': 39,
    'HUNGARY': 40,
    'INDIA': 1,
    'INDONESIA-CIT': 42,
    'INDONESIA-TIMUR': 43,
    'INDONESIA-WIB': 44,
    'ISRAEL': 45,
    'ITALY': 46,
    'JAPAN': 47,
    'KENYA': 48,
    'KOREA': 49,
    'LATVIA': 50,
    'LITHUANIA': 51,
    'MACEDONIA': 52,
    'MALAWI': 53,
    'MALAYSIA': 54,
    'MAURITIUS': 55,
    'MEXICO': 56,
    'NEPAL': 57,
    'NEW ZEALAND': 58,
    'NICARAGUA': 59,
    'NIGERIA': 60,
    'OMAN': 61,
    'PANAMA': 62,
    'PARAGUAY': 63,
    'PERU': 64,
    'PHILIPPINES': 65,
    'POLAND': 66,
    'PUERTO RICO': 88,
    'RUSSIA-MOSCOW': 67,
    'SAUDI ARABIA': 68,
    'SINGAPORE': 69,
    'SOUTH AFRICA': 70,
    'SPAIN': 71,
    'SRI LANKA': 72,
    'SWEDEN': 73,
    'SWITZERLAND': 74,
    'TAIWAN': 75,
    'TANZANIA': 76,
    'THAILAND': 77,
    'TRINIDAD': 78,
    'UAE': 81,
    'UGANDA': 79,
    'UKRAINE': 80,
    'URUGUAY': 83,
    'US CST': 7,
    'US EST': 5,
    'US MST': 6,
    'US PST': 4,
    'VENEZUELA': 84,
    'WEST INDIES': 90,
    'ZAMBIA': 85,
    'ZIMBABWE': 86,
  };

  // list of themes, don't change or move the values
  final List<String> appThemes = const [
    'Light',
    'Dark',
    'System default',
  ];

  @override
  bool updateShouldNotify(MyConstants oldWidget) => false;
}
