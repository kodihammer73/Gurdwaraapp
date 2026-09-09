import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Prayer {
  final String id;
  final String titleGurmukhi;
  final String titleEnglish;
  final String jsonAssetPath;

  const Prayer({
    required this.id,
    required this.titleGurmukhi,
    required this.titleEnglish,
    required this.jsonAssetPath,
  });
}

class Verse {
  final String gurmukhi;
  final String transliteration;
  final String translation;

  const Verse({
    required this.gurmukhi,
    required this.transliteration,
    required this.translation,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      gurmukhi: json['gurmukhi'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
    );
  }
}

final List<Prayer> nitnemPrayers = [
  const Prayer(
    id: 'japji',
    titleGurmukhi: 'ਜਪੁਜੀ ਸਾਹਿਬ',
    titleEnglish: 'Japji Sahib',
    jsonAssetPath: 'assets/prayers/japji_sahib.json',
  ),
  const Prayer(
    id: 'rehraas',
    titleGurmukhi: 'ਰਹਰਾਸਿ ਸਾਹਿਬ',
    titleEnglish: 'Rehraas Sahib',
    jsonAssetPath: 'assets/prayers/rehraas_sahib.json',
  ),
  const Prayer(
    id: 'sukhmani',
    titleGurmukhi: 'ਸੁਖਮਨੀ ਸਾਹਿਬ',
    titleEnglish: 'Sukhmani Sahib',
    jsonAssetPath: 'assets/prayers/sukhmani_sahib.json',
  ),
  const Prayer(
    id: 'ardas',
    titleGurmukhi: 'ਅਰਦਾਸਿ',
    titleEnglish: 'Ardaas',
    jsonAssetPath: 'assets/prayers/ardaas.json',
  ),
];

class PrayerReaderScreen extends StatefulWidget {
  const PrayerReaderScreen({super.key});

  @override
  State<PrayerReaderScreen> createState() => _PrayerReaderScreenState();
}

enum ReadingTheme { light, sepia, dark }

class _PrayerReaderScreenState extends State<PrayerReaderScreen> {
  Prayer _selectedPrayer = nitnemPrayers.first;
  final Map<String, List<Verse>> _loadedVerses = {};
  bool _isLoadingVerses = false;

  final bool _showGurmukhi = true;
  final bool _showTransliteration = true;
  final bool _showTranslation = true;
  double _fontSize = 18.0;
  ReadingTheme _theme = ReadingTheme.light;

  @override
  void initState() {
    super.initState();
    _loadSelectedPrayer(_selectedPrayer);
  }

  Future<void> _loadSelectedPrayer(Prayer prayer) async {
    setState(() {
      _selectedPrayer = prayer;
    });

    if (!_loadedVerses.containsKey(prayer.id)) {
      setState(() {
        _isLoadingVerses = true;
      });
      try {
        final String jsonString = await rootBundle.loadString(prayer.jsonAssetPath);
        final List<dynamic> jsonList = json.decode(jsonString);
        final verses = jsonList.map((item) => Verse.fromJson(item)).toList();
        setState(() {
          _loadedVerses[prayer.id] = verses;
          _isLoadingVerses = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingVerses = false;
        });
      }
    }
  }

  Color _getBgColor() {
    switch (_theme) {
      case ReadingTheme.sepia:
        return const Color(0xFFFBF0D9);
      case ReadingTheme.dark:
        return const Color(0xFF121212);
      case ReadingTheme.light:
        return const Color(0xFFF9F9F9);
    }
  }

  Color _getCardBgColor() {
    switch (_theme) {
      case ReadingTheme.sepia:
        return const Color(0xFFF3E5AB);
      case ReadingTheme.dark:
        return const Color(0xFF1E1E1E);
      case ReadingTheme.light:
        return Colors.white;
    }
  }

  Color _getTextColor() {
    switch (_theme) {
      case ReadingTheme.dark:
        return Colors.white;
      case ReadingTheme.sepia:
        return const Color(0xFF4A3B32);
      case ReadingTheme.light:
        return const Color(0xFF222222);
    }
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reader Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('Light'),
                        selected: _theme == ReadingTheme.light,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _theme = ReadingTheme.light);
                            setModalState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Sepia'),
                        selected: _theme == ReadingTheme.sepia,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _theme = ReadingTheme.sepia);
                            setModalState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Dark'),
                        selected: _theme == ReadingTheme.dark,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _theme = ReadingTheme.dark);
                            setModalState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_fontSize.round()} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 30.0,
                    divisions: 8,
                    activeColor: const Color(0xFFE8A838),
                    onChanged: (val) {
                      setState(() => _fontSize = val);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final verses = _loadedVerses[_selectedPrayer.id] ?? [];
    final textColor = _getTextColor();
    final cardBg = _getCardBgColor();

    return Scaffold(
      backgroundColor: _getBgColor(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<Prayer>(
            value: _selectedPrayer,
            dropdownColor: const Color(0xFF1B365D),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: nitnemPrayers.map((prayer) {
              return DropdownMenuItem<Prayer>(
                value: prayer,
                child: Text('${prayer.titleEnglish} (${prayer.titleGurmukhi})'),
              );
            }).toList(),
            onChanged: (prayer) {
              if (prayer != null) {
                _loadSelectedPrayer(prayer);
              }
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Reader Settings',
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: _isLoadingVerses
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8A838)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                return Card(
                  elevation: 1,
                  color: cardBg,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showGurmukhi && verse.gurmukhi.isNotEmpty) ...[
                          Text(
                            verse.gurmukhi,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _fontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_showTransliteration && verse.transliteration.isNotEmpty) ...[
                          Text(
                            verse.transliteration,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _fontSize - 2,
                              fontStyle: FontStyle.italic,
                              color: textColor.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_showTranslation && verse.translation.isNotEmpty) ...[
                          Text(
                            verse.translation,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _fontSize - 3,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
