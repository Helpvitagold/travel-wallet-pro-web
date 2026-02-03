import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const CurrencyApp(),
    );
  }
}

class CurrencyApp extends StatefulWidget {
  const CurrencyApp({super.key});
  @override
  State<CurrencyApp> createState() => _CurrencyAppState();
}

class _CurrencyAppState extends State<CurrencyApp> {
  double baseAmount = 1000.0;
  String baseCurrency = 'KRW';
  List<String> targetCurrencies = ['USD', 'JPY', 'EUR'];
  Map<String, double> rates = {};
  List<String> presetNames = ['프리셋 1', '프리셋 2', '프리셋 3', '프리셋 4'];
  String lastUpdated = "업데이트 기록 없음";
  int selectedPresetIndex = -1;

  final Map<String, String> currencyData = {
    'KRW': '대한민국 한국 원 South Korea won',
    'USD': '미국 달러 US dollar america',
    'JPY': '일본 엔 JPY yen japan',
    'EUR': '유럽 유로 EU euro europe',
    'CNY': '중국 위안 CNY yuan china',
    'VND': '베트남 동 VND dong vietnam',
    'THB': '태국 바트 THB baht thailand',
    'PHP': '필리핀 페소 PHP peso philippines',
    'TWD': '대만 달러 TWD taiwan',
    'HKD': '홍콩 달러 HKD hongkong',
    'SGD': '싱가포르 달러 SGD singapore',
    'AUD': '호주 오스트레일리아 달러 AUD australia',
    'GBP': '영국 파운드 GBP pound england',
    'CAD': '캐나다 달러 CAD canada',
    'CHF': '스위스 프랑 CHF swiss',
    'IDR': '인도네시아 루피아 IDR indonesia',
    'MYR': '말레이시아 링깃 MYR malaysia',
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        presetNames =
            prefs.getStringList('preset_names') ??
            ['프리셋 1', '프리셋 2', '프리셋 3', '프리셋 4'];
      });
    }
    await _loadOfflineData();
    fetchRates();
  }

  String _formatNumber(double number, String code) {
    List<String> noDecimalCurrencies = [
      'KRW',
      'JPY',
      'VND',
      'IDR',
      'THB',
      'PHP',
    ];
    String formatted = noDecimalCurrencies.contains(code)
        ? number.round().toString()
        : number.toStringAsFixed(2);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  Future<void> _saveOfflineData(
    Map<String, double> ratesToSave,
    String time,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_rates', json.encode(ratesToSave));
    await prefs.setString('last_updated', time);
  }

  Future<void> _loadOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedRates = prefs.getString('cached_rates');
    String? cachedTime = prefs.getString('last_updated');
    if (cachedRates != null && mounted) {
      setState(() {
        rates = Map<String, double>.from(json.decode(cachedRates));
        lastUpdated = cachedTime ?? "시간 정보 없음";
      });
    }
  }

  String _getFlag(String code) {
    if (code == 'EUR') return "🇪🇺";
    return code
        .substring(0, 2)
        .toUpperCase()
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) + 127397),
        );
  }

  Future<void> fetchRates() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        final Map<String, dynamic> fetchedRates = data['rates'];
        DateTime now = DateTime.now();
        String formattedTime =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        if (mounted) {
          setState(() {
            rates = fetchedRates.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            );
            lastUpdated = formattedTime;
          });
          _saveOfflineData(rates, lastUpdated);
        }
      }
    } catch (e) {
      await _loadOfflineData();
    }
  }

  void _showSearchDialog(bool isBase) {
    String query = "";
    List<String> selectedCodes = [];
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final results = currencyData.keys
              .where(
                (code) => (code + (currencyData[code] ?? ""))
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
          return AlertDialog(
            title: Text(isBase ? "기준 통화 선택" : "통화 다중 추가"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "국가명 또는 코드 입력",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setDialogState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (ctx, i) {
                        final c = results[i];
                        return CheckboxListTile(
                          secondary: Text(
                            _getFlag(c),
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: Text(c),
                          value: selectedCodes.contains(c),
                          onChanged: (val) {
                            setDialogState(() {
                              if (isBase) {
                                selectedCodes = [c];
                              } else {
                                if (val == true) {
                                  selectedCodes.add(c);
                                } else {
                                  selectedCodes.remove(c);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: selectedCodes.isEmpty
                    ? null
                    : () {
                        setState(() {
                          if (isBase) {
                            baseCurrency = selectedCodes.first;
                          } else {
                            for (var code in selectedCodes) {
                              if (!targetCurrencies.contains(code)) {
                                targetCurrencies.add(code);
                              }
                            }
                          }
                          selectedPresetIndex = -1;
                        });
                        fetchRates();
                        Navigator.pop(dialogCtx);
                      },
                child: const Text("확인"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> saveAndRenamePreset(int i) async {
    TextEditingController ctrl = TextEditingController(
      text: i <= presetNames.length ? presetNames[i - 1] : "",
    );
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("프리셋 저장"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "프리셋 이름"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (i > presetNames.length) {
                presetNames.add(ctrl.text);
              } else {
                presetNames[i - 1] = ctrl.text;
              }
              await prefs.setStringList('preset_names', presetNames);
              await prefs.setString('p$i', json.encode(targetCurrencies));
              if (!mounted) return;
              setState(() => selectedPresetIndex = i);
              Navigator.pop(dialogCtx);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  Future<void> loadPreset(int i) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('p$i');
    if (data != null && mounted) {
      setState(() {
        targetCurrencies = List<String>.from(json.decode(data));
        selectedPresetIndex = i;
      });
      fetchRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Travel Wallet Pro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade50,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: ActionChip(
                          avatar: Text(
                            _getFlag(baseCurrency),
                            style: const TextStyle(fontSize: 18),
                          ),
                          label: Text(
                            "기준:$baseCurrency▼",
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _showSearchDialog(true),
                          backgroundColor: Colors.indigo.shade50,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '금액 입력',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandSeparatorInputFormatter()],
                          onChanged: (v) {
                            setState(() {
                              baseAmount =
                                  double.tryParse(v.replaceAll(',', '')) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  width: double.infinity,
                  child: Text(
                    "마지막 업데이트: $lastUpdated",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    // ✨ aspectRatio 조정하여 세로 높이 확보 (Overflow 방지)
                    double aspectRatio = constraints.maxWidth > 600 ? 5.0 : 3.5;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          int i = index + 1;
                          bool isSelected = selectedPresetIndex == i;
                          String name = i <= presetNames.length
                              ? presetNames[i - 1]
                              : "프리셋 $i";
                          return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.indigo
                                    : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => loadPreset(i),
                                    child: Center(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.indigo.shade900
                                              : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => saveAndRenamePreset(i),
                                  child: Container(
                                    width: 45,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.indigo.shade200.withOpacity(
                                              0.4,
                                            )
                                          : Colors.grey.shade100,
                                      border: Border(
                                        left: BorderSide(
                                          color: isSelected
                                              ? Colors.indigo
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // ✨ 아이콘 폰트 대신 절대 안 깨지는 이모지 사용
                                        Text(
                                          "💾",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          "프리셋",
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: Colors.grey,
                                            height: 1.1,
                                          ),
                                        ),
                                        Text(
                                          "저장",
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: Colors.grey,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 110),
                    itemCount: targetCurrencies.length,
                    itemBuilder: (context, index) {
                      String c = targetCurrencies[index];
                      double r = rates[c] ?? 0;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Text(
                            _getFlag(c),
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            "${_formatNumber(baseAmount * r, c)} $c",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("1 $baseCurrency = $r $c"),
                          trailing: IconButton(
                            // ✨ 아이콘 폰트 대신 이모지 사용
                            icon: const Text(
                              "🗑️",
                              style: TextStyle(fontSize: 18),
                            ),
                            onPressed: () {
                              setState(() {
                                targetCurrencies.removeAt(index);
                                selectedPresetIndex = -1;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        width: double.infinity,
        child: FloatingActionButton.extended(
          elevation: 4,
          onPressed: () => _showSearchDialog(false),
          // ✨ 아이콘 폰트 대신 이모지 사용
          icon: const Text("➕", style: TextStyle(fontSize: 20)),
          label: const Text(
            "통화 추가",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String numText = newValue.text.replaceAll(',', '');
    final double? num = double.tryParse(numText);
    if (num == null) return oldValue;
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = numText.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
