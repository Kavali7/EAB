# Export fiscal Excel a partir du modele officiel

## Objectif

L'export fiscal final doit produire un classeur Excel pret a etre imprime en PDF et depose aux impots. Le format attendu n'est pas un simple tableau exporte depuis l'application : le classeur doit reprendre la structure du fichier modele place a la racine du projet.

Fichier modele actuel :

`Exempele de bilan pour une societe a but lucratif 2025.xlsx`

Copie applicative versionnee :

`assets/templates/fiscal_syscebnl_template.xlsx`

## Constat sur le modele

Le classeur contient 56 feuilles :

- `PAGE DE GARDE`
- `FICHE R1` a `FICHE R4`
- `ACTIF`, `PASSIF`, `RESULTAT`, `TFT`
- `NOTE 1` a `NOTE 36`
- `CODES`

Les feuilles contiennent des formules, cellules fusionnees, mises en page portrait/paysage, largeurs de colonnes, styles et zones de rendu qui doivent etre preserves. Le bon choix technique est donc de copier un modele `.xlsx` versionne, puis de remplir uniquement les cellules ciblees.

## Regle d'adaptation SYSCEBNL

Le modele source est inspire d'un fichier SYSCOHADA de societe commerciale. L'application doit conserver le format de depot, mais alimenter les montants avec le plan SYSCEBNL de l'eglise :

- comptes de ressources durables, actifs, tresorerie, charges, produits et engagements SYSCEBNL ;
- libelles adaptes a une entite a but non lucratif ;
- calculs comptables gardes coherents avec les formules du modele ;
- notes non applicables laissees vides, a zero ou marquees non applicables selon le parametrage final.

## Mapping SYSCEBNL vers le classeur

La logique comptable est isolee dans le service Flutter :

`lib/features/fiscal_dossier/services/syscebnl_excel_mapping.dart`

Ce service ne modifie pas encore le fichier `.xlsx`. Il produit une liste de cellules sources et de formules a appliquer au classeur. Cette separation est volontaire : elle evite de melanger les regles SYSCEBNL avec la librairie technique qui ecrira le fichier Excel.

Premiere couverture du mapping :

| Feuille | Cellules | Regle SYSCEBNL |
| --- | --- | --- |
| `ACTIF` | `D16`, `D18`, `D20`, `D21` | Immobilisations brutes classe 2, en excluant les amortissements classe 28 |
| `ACTIF` | `E18`, `E21` | Amortissements comptes 2813 et 2818, presentes en deduction |
| `ACTIF` | `D29`, `D32`, `D37` | Stocks classe 3, creances classe 4 debitrice, tresorerie active classe 5 |
| `PASSIF` | `D12` | Fonds associatifs, dotations et ressources durables classe 1 |
| `PASSIF` | `D19` | Formule `=RESULTAT!E50`, pour reprendre le resultat net de l'exercice |
| `PASSIF` | `D30`, `D31`, `D32`, `D36` | Fournisseurs, dettes fiscales/sociales, autres dettes, tresorerie passive |
| `RESULTAT` | `E20` | Produits d'eglise : dimes, offrandes, dons, cotisations et autres produits classe 7 |
| `RESULTAT` | `E26`, `E27`, `E29`, `E31`, `E34`, `E39` | Charges par nature : transport, services, autres charges, personnel, dotations, frais financiers |
| `RESULTAT` | `E44`, `E46` | Produits et charges hors activites ordinaires classe 8 |
| `TFT` | `H14` | Formule de capacite d'autofinancement : resultat net + dotations - reprises |

Premiere couverture des annexes :

| Feuille | Cellules | Regle SYSCEBNL |
| --- | --- | --- |
| `NOTE 3A` | lignes immobilisations, colonnes `B`, `C`, `F`, `H` | Immobilisations brutes : N-1, acquisitions nettes, sorties et cloture par famille de comptes 20, 21, 213, 214-217, 218, 244-245, 238, 26 et 27 |
| `NOTE 3C` | lignes amortissements, colonnes `B`, `C`, `D` | Amortissements cumules : N-1, dotations nettes et reductions par comptes 280, 281 et 284 |
| `NOTE 4` | `B13:C13`, `B17:C17` | Immobilisations financieres courantes et N-1 : titres de participation classe 26 et autres immobilisations financieres classe 27 |
| `NOTE 6` | `B12:C12` | Stocks et en-cours classe 3, courant et N-1 |
| `NOTE 7` | `B12:C12`, `E12` | Creances membres et tiers debiteurs classe 4, courant, N-1 et part a un an au plus |
| `NOTE 8` | lignes `14`, `15`, `16`, `18`, `20` | Autres creances : personnel, organismes sociaux, Etat, entites liees et autres debiteurs |
| `NOTE 11` | `C12:D12`, `C18:D18`, `C21:D23` | Disponibilites : banque, etablissements financiers, caisse, Mobile Money et regies d'avance |
| `NOTE 16A` | `B8:C8`, `F8`, `B38:C38` | Emprunts classe 16 et provisions pour risques classe 19, avec classement court terme par defaut faute d'echeancier detaille |
| `NOTE 17` | `B10:C10`, `B17:C17` | Fournisseurs classe 40 et avances fournisseurs classe 409 |
| `NOTE 18` | lignes `12`, `14`, `20` | Dettes personnel, organismes sociaux et Etat classes 42, 43 et 44, classees a un an au plus par defaut |
| `NOTE 19` | lignes `12`, `17`, formules `B24:C24` | Autres dettes classes 45 a 48, avec total crediteurs divers recalcule |
| `NOTE 20` | `B17:C17`, `B21:C21` | Tresorerie passive : banques locales crediteurs et autres credits de tresorerie classe 5 |
| `NOTE 21` | `B35:C38` | Ressources ordinaires SYSCEBNL : production immobilisee, subventions et produits d'eglise classe 7 |
| `NOTE 22` | `B16:C16`, `B31:C31` | Achats de fournitures classe 601 et autres achats classe 60 |
| `NOTE 23` | `B14:C14` | Transports classe 624 |
| `NOTE 24` | lignes `11`, `13`, `17`, `18`, `23` | Services exterieurs : locations, maintenance, telecommunications, frais bancaires et autres charges externes |
| `NOTE 25` | lignes `11` a `15` | Impots et taxes classe 63 par familles |
| `NOTE 26` | lignes `10`, `15`, `16` | Pertes sur creances, aides/dons accordes et autres charges diverses classes 64/65 |
| `NOTE 27A` | lignes `11`, `13`, `15`, `16` | Charges de personnel classe 66 : remunerations, charges sociales, personnel exterieur et autres charges |
| `NOTE 29` | lignes `10`, `13`, `15`, `19`, `22`, `25`, `30` | Charges et revenus financiers classes 67, 69, 77 et reprises financieres 797 |
| `NOTE 30` | `B10:C10`, `B20:C20` | Charges et produits hors activites ordinaires classe 8 |
| `NOTE 31` | formules `B18:C22`, `B29:C31` | Synthese cinq exercices reliee aux notes 21, 27A et au compte de resultat |

Couverture de securite ajoutee :

- toutes les cellules sources numeriques des feuilles `ACTIF`, `PASSIF`, `RESULTAT` et `TFT` sont ecrasees par le generateur ;
- les cellules non encore mappees sur un compte SYSCEBNL sont forcees a `0` ;
- les colonnes comparatives N-1 sont alimentees par la balance du meme perimetre sur la periode decalee d'un an ;
- si aucune balance N-1 n'existe, les cellules comparatives restent a `0` et le controle avant export affiche un avertissement ;
- les cellules numeriques non formulees des feuilles `PAGE DE GARDE`, `FICHE R1` a `FICHE R4` et `NOTE*` sont neutralisees pour supprimer les anciens chiffres d'exemple ;
- les formules des fiches et notes sont conservees, mais leurs anciennes valeurs cachees sont supprimees pour forcer un recalcul propre a l'ouverture du classeur ;
- les cellules de totaux, sous-totaux et nets restent des formules Excel du modele ;
- le `TFT` conserve ses lignes de calcul, mais ses flux non calculables sans historique sont neutralises pour eviter les montants d'exemple.

Cette regle evite qu'un montant du fichier exemple commercial survive dans un dossier fiscal d'eglise.

Les totaux, sous-totaux et nets du classeur doivent rester des formules Excel. Le generateur ne doit ecrire que les cellules sources, sauf lorsqu'une formule doit explicitement remplacer une valeur manuelle du modele.

Un test verrouille cette logique :

`test/features/fiscal_dossier/syscebnl_excel_mapping_test.dart`

Points couverts par le test :

- les comptes 28 ne sont pas inclus dans l'immobilisation brute ;
- les amortissements sont presentes dans les colonnes d'amortissement/depreciation ;
- les creances et dettes de classe 4 sont separees selon leur nature active ou passive ;
- les produits classe 7 et charges classe 6 alimentent le resultat selon une logique SYSCEBNL ;
- le resultat net du passif est repris depuis la feuille `RESULTAT`.

## Generation technique du classeur

Le prototype de generation utilise une ecriture OOXML minimale :

`lib/features/fiscal_dossier/services/fiscal_excel_template_writer.dart`

Le fichier `.xlsx` est traite comme une archive zip. Le writer copie toutes les entrees du modele et remplace seulement :

- `xl/workbook.xml` pour les noms Excel globaux et le recalcul des formules ;
- les XML des feuilles ciblees pour les cellules sources et formules SYSCEBNL ;
- les libelles incompatibles dans les parties XML du classeur, via le dictionnaire SYSCEBNL.

Cette approche evite de recreer le classeur avec une librairie tableur qui pourrait perdre les dessins, styles, mises en page ou objets non supportes. Les parties non modifiees, y compris les dessins et relations, restent dans l'archive.

Test associe :

`test/features/fiscal_dossier/fiscal_excel_template_writer_test.dart`

Le test verifie :

- l'ecriture de valeurs numeriques ;
- l'ecriture de formules sans le `=` initial dans le XML Excel ;
- la conservation du style d'une cellule existante ;
- le remplacement des noms Excel globaux ;
- la conservation d'une partie dessin non modifiee ;
- le refus d'un classeur qui conserve une occurrence interdite.

## Export depuis l'application

Le service applicatif est :

`lib/features/fiscal_dossier/services/fiscal_excel_export_service.dart`

Regles verrouillees :

- l'export refuse tout dossier sans `church_unit_id` ;
- la balance est lue via `report_balance_generale_scoped`, avec `organization_id`, `church_unit_id`, `date_debut` et `date_fin` du dossier ;
- la balance comparative N-1 est lue avec le meme `organization_id` et le meme `church_unit_id`, sur les dates decalees d'un an ;
- le fichier Excel est genere depuis l'asset `assets/templates/fiscal_syscebnl_template.xlsx` ;
- les noms Excel globaux portent l'organisation, le sigle, le NIF, la devise, l'exercice et le perimetre ;
- le fichier est refuse si une occurrence interdite reste presente apres nettoyage.

Dictionnaire et audit des libelles :

`lib/features/fiscal_dossier/services/fiscal_excel_sanitization.dart`

Termes bloques notamment : `SYSCOHADA`, `OHADA`, `societe`, `commercial`, `marchandise`, `vente`, `capital`, `dividende`, `actionnaire`.

Prototype manuel sur le modele local :

```bash
dart run tool/prototype_fiscal_excel_export.dart
```

Sortie locale non versionnee :

`build/prototypes/dossier_fiscal_syscebnl_prototype_<timestamp>.xlsx`

Le prototype controle que le classeur genere conserve le meme nombre d'entrees zip que le modele, affiche les cellules injectees principales et passe l'audit des libelles SYSCEBNL.

Il controle aussi que les montants d'exemple des fiches et notes annexes sont neutralises ou remplaces par des donnees SYSCEBNL reelles, par exemple `FICHE R1!AQ14`, `NOTE 3A!H23`, `NOTE 3C!C22`, `NOTE 6!B12`, `NOTE 7!B12`, `NOTE 11!C12`, `NOTE 21!B37`, `NOTE 24!B11`, `NOTE 27A!B11` et `NOTE 31!B18`.

## Ajustements avant generation

Le niveau autorise, generalement le plus haut niveau comptable, doit pouvoir effectuer des ajustements temporaires avant generation :

- ajouter une ecriture debit/credit equilibree ;
- reclasser un montant entre deux comptes debiteurs ;
- reclasser un montant entre deux comptes crediteurs ;
- verifier les controles actif/passif/resultat avant export.

Ces ajustements ne doivent jamais modifier les ecritures comptables, les mouvements financiers ou les donnees de base. Ils doivent rester dans une couche d'export, par exemple :

- brouillon d'export fiscal ;
- table ou objet JSON d'ajustements de presentation ;
- application des ajustements uniquement lors de la generation Excel/PDF.

Implementation actuelle :

`lib/features/fiscal_dossier/services/fiscal_export_adjustments.dart`

Les ajustements sont stockes dans les valeurs du dossier fiscal sous la cle :

`export.adjustments`

Garde-fous obligatoires :

- chaque ajustement a un libelle, une justification et au moins deux lignes ;
- une ligne ne peut modifier qu'un cote comptable a la fois ;
- le total des deltas debit doit rester egal au total des deltas credit ;
- un reclassement ne peut pas rendre un compte negatif ;
- apres application, la balance ajustee doit rester equilibree avant generation ;
- les totaux et sous-totaux du fichier restent recalcules par les formules Excel du modele.

Ainsi, un ajustement agit comme une piece d'export controlee : il affecte automatiquement les comptes et cellules dependantes via le mapping SYSCEBNL, mais il ne touche pas aux ecritures source.

Les ajustements s'appliquent uniquement a l'exercice exporte. La balance N-1 reste une lecture historique du meme perimetre, sans ajustement temporaire, pour eviter de melanger les corrections de presentation de l'exercice courant avec les donnees comparatives deja cloturees.

## Controle avant export

Le rapport de controle avant export est porte par :

`lib/features/fiscal_dossier/services/fiscal_export_preflight_service.dart`

Il verifie avant generation :

- presence d'un perimetre fiscal explicite ;
- coherence de la periode ;
- presence d'une balance pour le perimetre et la periode ;
- equilibre debit/credit apres ajustements ;
- presence d'au moins une cellule SYSCEBNL principale alimentee ;
- existence ou non du comparatif N-1 du meme perimetre ;
- application eventuelle des ajustements d'export ;
- neutralisation des anciennes cellules du modele.
- neutralisation des montants d'exemple dans les fiches et notes annexes.

Le bouton `Controles` affiche le rapport dans le dossier fiscal. Le bouton `Excel` execute aussi ce controle : si une anomalie bloquante existe, le rapport est affiche et l'export est refuse.

## Implication pour le developpement

La suite doit etre construite en trois niveaux :

1. Donnees consolidees filtrees par organisation et perimetre actif.
2. Mappage SYSCEBNL vers les cellules du modele fiscal.
3. Generation Excel depuis template, puis impression/partage PDF.

La migration `00036` consolide le premier niveau en ajoutant des RPC de rapports financiers filtrees par unite active.
