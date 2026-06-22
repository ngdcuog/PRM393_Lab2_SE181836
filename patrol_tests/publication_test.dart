import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:journal_trend_analyzer/main.dart';
import 'package:journal_trend_analyzer/widgets/publication_card.dart';

void main() {
  patrolTest('search and view publication detail', ($) async {
    // Launch app
    await $.pumpWidgetAndSettle(const JournalTrendApp());

    // Nhập "Machine Learning" vào search field
    await $(TextField).enterText('Machine Learning');
    await $.pumpAndSettle();

    // Tap search icon
    await $(Icons.search).tap();
    await $.pumpAndSettle();

    // Verify có ít nhất 1 PublicationCard hiển thị
    expect($(PublicationCard), findsWidgets);

    // Tap vào card đầu tiên
    await $(PublicationCard).first.tap();
    await $.pumpAndSettle();

    // Verify navigate đến Publication Detail screen và hiện đúng title, DOI
    expect($('Publication Details'), findsOneWidget);
    expect($('Open DOI Link'), findsWidgets);
  });

  patrolTest('view journal navigation', ($) async {
    // Launch app
    await $.pumpWidgetAndSettle(const JournalTrendApp());

    // Tap vào Journals tab trong bottom nav
    await $(Icons.library_books).tap();
    await $.pumpAndSettle();

    // Verify journal list hiển thị
    expect($(ListTile), findsWidgets);

    // Tap vào journal đầu tiên
    await $(ListTile).first.tap();
    await $.pumpAndSettle();

    // Verify journal detail hiện đúng tên và statistics
    expect($('Total Publications'), findsWidgets);
  });
}
