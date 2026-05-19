class AumData {
  final double totalAum;
  final String lastMeetingTime;
  final double netWorthChangePercentage;

  AumData({
    required this.totalAum,
    required this.lastMeetingTime,
    this.netWorthChangePercentage = 0.0,
  });

  factory AumData.fromFirestore(Map<String, dynamic> data) {
    return AumData(
      totalAum: (data['totalAum'] ?? 0).toDouble(),
      lastMeetingTime: data['lastMeetingTime'] ?? '',
      netWorthChangePercentage: (data['netWorthChangePercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalAum': totalAum,
      'lastMeetingTime': lastMeetingTime,
      'netWorthChangePercentage': netWorthChangePercentage,
    };
  }
}
