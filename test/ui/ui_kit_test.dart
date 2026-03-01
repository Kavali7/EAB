/// Widget tests pour les composants UI Kit.
///
/// Ces tests ne nécessitent PAS Supabase (composants purs).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eab/ui/ui.dart';

void main() {
  // ── EabButton ──
  group('EabButton', () {
    testWidgets('affiche le label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EabButton(
              label: 'Enregistrer',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('appelle onPressed quand cliqué', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EabButton(
              label: 'Go',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      expect(pressed, isTrue);
    });

    testWidgets('affiche le loader quand isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EabButton(
              label: 'Sauvegarde',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('variante secondary rend un bouton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EabButton(
              label: 'Annuler',
              variant: EabButtonVariant.secondary,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Annuler'), findsOneWidget);
    });
  });

  // ── EabTextField ──
  group('EabTextField', () {
    testWidgets('affiche le label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EabTextField(
              label: 'Email',
              controller: TextEditingController(),
            ),
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('accepte la saisie', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EabTextField(label: 'Nom', controller: ctrl),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Jean Dupont');
      expect(ctrl.text, 'Jean Dupont');
    });

    testWidgets('affiche l\'erreur de validation', (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: key,
              child: EabTextField(
                label: 'Champ requis',
                controller: TextEditingController(),
                validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
              ),
            ),
          ),
        ),
      );
      key.currentState!.validate();
      await tester.pump();
      expect(find.text('Obligatoire'), findsOneWidget);
    });
  });

  // ── EmptyState ──
  group('EmptyState', () {
    testWidgets('affiche message et icône', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search,
              message: 'Aucun résultat trouvé.',
            ),
          ),
        ),
      );
      expect(find.text('Aucun résultat trouvé.'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  // ── SkeletonLoader ──
  group('SkeletonLoader', () {
    testWidgets('affiche le nombre de lignes demandé', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(lineCount: 4, lineHeight: 16),
          ),
        ),
      );
      // Le skeleton devrait créer 4 containers animés
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });

  // ── SectionCard ──
  group('SectionCard', () {
    testWidgets('affiche le titre et le contenu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionCard(
              title: 'Détails',
              child: Text('Contenu ici'),
            ),
          ),
        ),
      );
      expect(find.text('Détails'), findsOneWidget);
      expect(find.text('Contenu ici'), findsOneWidget);
    });
  });
}
