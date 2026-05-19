import 'dart:convert';

class CASParser {
  /// Compresses the raw CAS JSON string to a token-efficient format.
  static String compress(String rawJson) {
    try {
      final Map<String, dynamic> raw = jsonDecode(rawJson);
      final compressed = compressFullCas(raw);
      return jsonEncode(compressed);
    } catch (e) {
      // If parsing fails, return the original or empty to avoid breaking the flow
      return rawJson;
    }
  }

  static Map<String, dynamic> compressFullCas(Map<String, dynamic> raw) {
    if (raw.isEmpty) return {};

    double total = 0;

    Map<String, double> assetTotals = {
      "eq": 0,
      "debt": 0,
      "oth": 0,
    };

    Map<String, double> amcTotals = {};
    List<Map<String, dynamic>> topAssets = [];

    // -------------------------------
    // 1. SUMMARY (FAST PATH)
    // -------------------------------
    final summary = raw["summary"];
    if (summary != null) {
      total = (summary["total_value"] ?? 0).toDouble();

      final accounts = summary["accounts"] ?? {};

      assetTotals["eq"] =
          (accounts["demat"]?["total_value"] ?? 0).toDouble();

      assetTotals["oth"] =assetTotals["oth"]!+
          (accounts["insurance"]?["total_value"] ?? 0).toDouble();

      assetTotals["oth"] = assetTotals["oth"]!+
          (accounts["nps"]?["total_value"] ?? 0).toDouble();

      assetTotals["debt"] =
          (accounts["mutual_funds"]?["total_value"] ?? 0).toDouble();
    }

    // -------------------------------
    // 2. DEMAT PARSE (Equities focus)
    // -------------------------------
    final dematAccounts = raw["demat_accounts"] ?? [];
    for (var acc in dematAccounts) {
      final holdings = acc["holdings"] ?? {};
      final equities = holdings["equities"] ?? [];

      for (var eq in equities) {
        final name = (eq["name"] ?? "Equity").toString();
        final value = (eq["value"] ?? 0).toDouble();

        if (value == 0) continue;

        topAssets.add({"n": name, "v": value});
      }
    }

    // -------------------------------
    // 3. MUTUAL FUNDS PARSE
    // -------------------------------
    final mfs = raw["mutual_funds"] ?? [];
    for (var mf in mfs) {
      final amc = (mf["amc"] ?? "Unknown").toString();
      final value = (mf["value"] ?? 0).toDouble();

      if (value == 0) continue;

      amcTotals[amc] = (amcTotals[amc] ?? 0) + value;

      final schemes = mf["schemes"] ?? [];
      for (var scheme in schemes) {
        final name = (scheme["name"] ?? "MF").toString();
        final val = (scheme["value"] ?? 0).toDouble();

        if (val == 0) continue;

        topAssets.add({"n": name, "v": val});
      }
    }

    // -------------------------------
    // 4. NORMALIZE TOTAL (fallback)
    // -------------------------------
    if (total == 0) {
      total = assetTotals.values.reduce((a, b) => a + b);
    }

    if (total == 0) return {};

    // -------------------------------
    // 5. ALLOCATION %
    // -------------------------------
    Map<String, int> alloc = {};
    assetTotals.forEach((k, v) {
      alloc[k] = ((v / total) * 100).round();
    });

    // -------------------------------
    // 6. AMC %
    // -------------------------------
    List<Map<String, dynamic>> amcList = [];
    amcTotals.forEach((name, value) {
      amcList.add({
        "n": name,
        "p": ((value / total) * 100).round()
      });
    });

    amcList.sort((a, b) => b["p"].compareTo(a["p"]));

    // -------------------------------
    // 7. TOP ASSETS (Top 5)
    // -------------------------------
    topAssets.sort((a, b) => b["v"].compareTo(a["v"]));
    final top = topAssets.take(5).map((e) {
      return {
        "n": e["n"],
        "v": (e["v"] as double).round()
      };
    }).toList();

    // -------------------------------
    // 8. FLAGS
    // -------------------------------
    bool overConcentration =
        amcList.isNotEmpty && amcList.first["p"] > 40;

    bool lowDiversification = amcList.length < 3;

    int inactive = 0; // extend if txn data available

    // -------------------------------
    // 9. FINAL OUTPUT
    // -------------------------------
    return {
      "total": total.round(),
      "alloc": alloc,
      "amc": amcList.take(3).toList(),
      "top": top,
      "flags": {
        "over_concentration": overConcentration,
        "low_diversification": lowDiversification,
        "inactive": inactive
      }
    };
  }
}
