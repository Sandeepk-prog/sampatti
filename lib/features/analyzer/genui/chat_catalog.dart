import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'widgets/transaction_table.dart';
import 'widgets/portfolio_summary.dart';

final chatCatalog = Catalog(
  catalogId: 'default',
  [
    CatalogItem(
      name: 'transaction_table',
      dataSchema: S.object(
        properties: {
          'title': S.string(),
          'transactions': S.list(items: S.object(properties: {
            'date': S.string(),
            'description': S.string(),
            'amount': S.number(),
            'type': S.string(),
          })),
        },
      ),
      widgetBuilder: (context) {
        print('Building TransactionTableWidget with data: ${context.data}');
        return TransactionTableWidget(data: context.data as Map<String, dynamic>);
      },
    ),
    CatalogItem(
      name: 'portfolio_summary',
      dataSchema: S.object(
        properties: {
          'totalValue': S.number(),
          'totalInvestment': S.number(),
          'xirr': S.number(),
          'topHoldings': S.list(items: S.object(properties: {
            'name': S.string(),
            'value': S.number(),
          })),
        },
      ),
      widgetBuilder: (context) {
        print('Building PortfolioSummaryWidget with data: ${context.data}');
        return PortfolioSummaryWidget(data: context.data as Map<String, dynamic>);
      },
    ),
  ],
);




