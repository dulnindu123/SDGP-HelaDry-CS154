class MockDevice {
  final String name;
  final int rssi;
  final String quality;

  const MockDevice({
    required this.name,
    required this.rssi,
    required this.quality,
  });
}

class MockWifiNetwork {
  final String ssid;
  final String quality;
  final bool isSecured;

  const MockWifiNetwork({
    required this.ssid,
    required this.quality,
    this.isSecured = true,
  });
}

class MockBatchRecord {
  final String id;
  final String cropName;
  final String cropEmoji;
  final String status; // 'active' or 'completed'
  final double weightKg;
  final String startDate;
  final String? endDate;
  final int trays;
  final double targetTemp;

  const MockBatchRecord({
    required this.id,
    required this.cropName,
    required this.cropEmoji,
    required this.status,
    required this.weightKg,
    required this.startDate,
    this.endDate,
    required this.trays,
    required this.targetTemp,
  });
}

class CropInfo {
  final String name;
  final String emoji;
  final double tempC;
  final String duration;
  final String sliceThickness;
  final String pretreatment;
  final String fanMode;
  final String trayLoad;
  final String sliceTip;
  final List<Map<String, String>> preparationSteps;
  final List<String> dryingTips;

  const CropInfo({
    required this.name,
    required this.emoji,
    required this.tempC,
    required this.duration,
    required this.sliceThickness,
    required this.pretreatment,
    required this.fanMode,
    required this.trayLoad,
    required this.sliceTip,
    required this.preparationSteps,
    required this.dryingTips,
  });
}

class MockData {
  static const List<MockDevice> devices = [
    MockDevice(name: 'HELADRY-A1B2', rssi: -45, quality: 'Excellent'),
    MockDevice(name: 'HelaDry-C3D4', rssi: -62, quality: 'Fair'),
    MockDevice(name: 'HELADRY-E5F6', rssi: -78, quality: 'Weak'),
    MockDevice(name: 'HELADRY-TEST', rssi: -55, quality: 'Good'),
  ];

  static const List<MockWifiNetwork> wifiNetworks = [
    MockWifiNetwork(ssid: 'Home WiFi', quality: 'Excellent'),
    MockWifiNetwork(ssid: 'Office Network', quality: 'Good'),
    MockWifiNetwork(ssid: 'Guest Network', quality: 'Fair'),
    MockWifiNetwork(ssid: 'FarmNet-5G', quality: 'Weak'),
  ];

  static const List<MockBatchRecord> batchRecords = [
    MockBatchRecord(
      id: 'BATCH-001',
      cropName: 'Mango',
      cropEmoji: '🥭',
      status: 'active',
      weightKg: 5.0,
      startDate: '2026-03-04',
      trays: 4,
      targetTemp: 60,
    ),
    MockBatchRecord(
      id: 'BATCH-002',
      cropName: 'Tomato',
      cropEmoji: '🍅',
      status: 'completed',
      weightKg: 3.5,
      startDate: '2026-03-01',
      endDate: '2026-03-03',
      trays: 3,
      targetTemp: 55,
    ),
    MockBatchRecord(
      id: 'BATCH-003',
      cropName: 'Banana',
      cropEmoji: '🍌',
      status: 'completed',
      weightKg: 4.2,
      startDate: '2026-02-25',
      endDate: '2026-02-28',
      trays: 5,
      targetTemp: 58,
    ),
  ];

  static const List<CropInfo> crops = [
    CropInfo(
      name: 'Mango',
      emoji: '🥭',
      tempC: 60,
      duration: '12–24h',
      sliceThickness: '5mm',
      pretreatment: 'Dip in lemon juice for 5 minutes',
      fanMode: 'Auto',
      trayLoad: 'Single layer, no overlap',
      sliceTip: 'Slice uniformly at 5mm for even drying',
      preparationSteps: [
        {
          'title': 'Wash and peel',
          'desc': 'Clean mangoes thoroughly and remove skin',
        },
        {
          'title': 'Slice evenly',
          'desc': 'Cut into 5mm thick slices for uniform drying',
        },
        {
          'title': 'Pretreat',
          'desc': 'Dip slices in lemon juice to prevent browning',
        },
        {
          'title': 'Arrange on trays',
          'desc': 'Place slices in single layer without overlapping',
        },
      ],
      dryingTips: [
        'Avoid overloading trays for better air circulation',
        'Rotate trays every 4 hours for even drying',
        'Check dryness: should be leathery but pliable',
        'Store in airtight containers after cooling',
      ],
    ),
    CropInfo(
      name: 'Jackfruit',
      emoji: '🍈',
      tempC: 55,
      duration: '18–30h',
      sliceThickness: '8mm',
      pretreatment: 'No pretreatment needed',
      fanMode: 'Auto',
      trayLoad: 'Single layer, no overlap',
      sliceTip: 'Cut into uniform pieces for even drying',
      preparationSteps: [
        {
          'title': 'Separate bulbs',
          'desc': 'Remove seeds and separate fruit bulbs',
        },
        {'title': 'Slice evenly', 'desc': 'Cut into 8mm thick pieces'},
        {'title': 'Remove excess moisture', 'desc': 'Pat dry with clean cloth'},
        {'title': 'Arrange on trays', 'desc': 'Place pieces in single layer'},
      ],
      dryingTips: [
        'Jackfruit has high sugar content, watch for sticking',
        'Rotate trays every 6 hours',
        'Dried jackfruit should be chewy but not wet',
        'Store in cool, dry place',
      ],
    ),
    CropInfo(
      name: 'Tomato',
      emoji: '🍅',
      tempC: 55,
      duration: '8–14h',
      sliceThickness: '6mm',
      pretreatment: 'Light salt sprinkle optional',
      fanMode: 'Auto',
      trayLoad: 'Single layer, cut side up',
      sliceTip: 'Slice uniformly for even drying',
      preparationSteps: [
        {'title': 'Wash thoroughly', 'desc': 'Clean tomatoes and remove stems'},
        {'title': 'Slice evenly', 'desc': 'Cut into 6mm thick slices'},
        {'title': 'Season (optional)', 'desc': 'Sprinkle with salt or herbs'},
        {
          'title': 'Arrange on trays',
          'desc': 'Place cut side up in single layer',
        },
      ],
      dryingTips: [
        'Roma tomatoes work best for drying',
        'Remove seeds for faster drying',
        'Should be leathery when done',
        'Store in olive oil or airtight containers',
      ],
    ),
    CropInfo(
      name: 'Banana',
      emoji: '🍌',
      tempC: 58,
      duration: '10–18h',
      sliceThickness: '5mm',
      pretreatment: 'Dip in lemon water to prevent browning',
      fanMode: 'Auto',
      trayLoad: 'Single layer, no overlap',
      sliceTip: 'Use ripe but firm bananas',
      preparationSteps: [
        {'title': 'Peel bananas', 'desc': 'Remove peel from ripe bananas'},
        {'title': 'Slice evenly', 'desc': 'Cut into 5mm rounds or lengthwise'},
        {'title': 'Pretreat', 'desc': 'Dip in lemon water to prevent browning'},
        {
          'title': 'Arrange on trays',
          'desc': 'Place in single layer without touching',
        },
      ],
      dryingTips: [
        'Riper bananas will be sweeter when dried',
        'Chips should be crispy, not chewy',
        'Rotate trays halfway through',
        'Cool completely before storing',
      ],
    ),
    CropInfo(
      name: 'Papaya',
      emoji: '🫒',
      tempC: 55,
      duration: '10–16h',
      sliceThickness: '6mm',
      pretreatment: 'No pretreatment needed',
      fanMode: 'Auto',
      trayLoad: 'Single layer',
      sliceTip: 'Use firm ripe papaya',
      preparationSteps: [
        {
          'title': 'Wash and peel',
          'desc': 'Clean papaya and remove skin and seeds',
        },
        {'title': 'Slice evenly', 'desc': 'Cut into 6mm thick slices'},
        {'title': 'Remove seeds', 'desc': 'Scoop out all seeds'},
        {'title': 'Arrange on trays', 'desc': 'Place in single layer on trays'},
      ],
      dryingTips: [
        'Choose firm ripe papaya for best results',
        'Dried papaya should be pliable',
        'Rotate trays every 4 hours',
        'Store in airtight containers',
      ],
    ),
    CropInfo(
      name: 'Chili Pepper',
      emoji: '🌶️',
      tempC: 50,
      duration: '8–12h',
      sliceThickness: 'Whole or halved',
      pretreatment: 'Slit lengthwise for faster drying',
      fanMode: 'Auto',
      trayLoad: 'Single layer',
      sliceTip: 'Wear gloves when handling hot peppers',
      preparationSteps: [
        {'title': 'Wash peppers', 'desc': 'Clean and dry thoroughly'},
        {'title': 'Slit or halve', 'desc': 'Cut lengthwise for faster drying'},
        {
          'title': 'Remove seeds (optional)',
          'desc': 'Remove seeds for milder result',
        },
        {
          'title': 'Arrange on trays',
          'desc': 'Place in single layer with space between',
        },
      ],
      dryingTips: [
        'Dry in well-ventilated area',
        'Peppers should be brittle when done',
        'Wear gloves to avoid irritation',
        'Store whole or grind into powder',
      ],
    ),
    CropInfo(
      name: 'Grape',
      emoji: '🍇',
      tempC: 55,
      duration: '24–48h',
      sliceThickness: 'Whole',
      pretreatment: 'Dip in boiling water for 30 seconds',
      fanMode: 'Auto',
      trayLoad: 'Single layer',
      sliceTip: 'Use seedless grapes for best results',
      preparationSteps: [
        {'title': 'Wash grapes', 'desc': 'Clean and remove from stems'},
        {
          'title': 'Blanch briefly',
          'desc': 'Dip in boiling water for 30 seconds to crack skins',
        },
        {'title': 'Pat dry', 'desc': 'Remove excess moisture'},
        {'title': 'Arrange on trays', 'desc': 'Place in single layer on trays'},
      ],
      dryingTips: [
        'Grapes take the longest to dry',
        'Should be wrinkled but not sticky',
        'Rotate trays every 8 hours',
        'Store in cool, dark place',
      ],
    ),
  ];

  static const Map<String, dynamic> liveMetrics = {
    'temperature': 28.0,
    'humidity': 65.0,
    'fanSpeed': 0,
    'heaterStatus': 'OFF',
    'battery': 12.6,
    'solarStatus': 'Charging',
  };

  static const String lastSyncDate = '3/4/2026';
  static const String defaultDeviceId = 'HELADRY-A1B2';
  static const String defaultDeviceName = 'HelaDry';
  static const String firmwareVersion = 'v2.1.4';
  static const String appVersion = 'v1.0.0';
}
