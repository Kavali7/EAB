# Export fiscal Excel a partir du modele officiel

## Objectif

L'export fiscal final doit produire un classeur Excel pret a etre imprime en PDF et depose aux impots. Le format attendu n'est pas un simple tableau exporte depuis l'application : le classeur doit reprendre la structure du fichier modele place a la racine du projet.

Fichier modele actuel :

`Exempele de bilan pour une societe a but lucratif 2025.xlsx`

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

Les totaux, sous-totaux et nets du classeur doivent rester des formules Excel. Le generateur ne doit ecrire que les cellules sources, sauf lorsqu'une formule doit explicitement remplacer une valeur manuelle du modele.

Un test verrouille cette logique :

`test/features/fiscal_dossier/syscebnl_excel_mapping_test.dart`

Points couverts par le test :

- les comptes 28 ne sont pas inclus dans l'immobilisation brute ;
- les amortissements sont presentes dans les colonnes d'amortissement/depreciation ;
- les creances et dettes de classe 4 sont separees selon leur nature active ou passive ;
- les produits classe 7 et charges classe 6 alimentent le resultat selon une logique SYSCEBNL ;
- le resultat net du passif est repris depuis la feuille `RESULTAT`.

## Ajustements avant generation

Le niveau autorise, generalement le plus haut niveau comptable, doit pouvoir effectuer des ajustements temporaires avant generation :

- reclasser un montant dans une cellule de sortie ;
- ajouter une correction fiscale de presentation ;
- forcer un libelle ou un total de depot ;
- verifier les controles actif/passif/resultat avant export.

Ces ajustements ne doivent jamais modifier les ecritures comptables, les mouvements financiers ou les donnees de base. Ils doivent rester dans une couche d'export, par exemple :

- brouillon d'export fiscal ;
- table ou objet JSON d'ajustements de presentation ;
- application des ajustements uniquement lors de la generation Excel/PDF.

## Implication pour le developpement

La suite doit etre construite en trois niveaux :

1. Donnees consolidees filtrees par organisation et perimetre actif.
2. Mappage SYSCEBNL vers les cellules du modele fiscal.
3. Generation Excel depuis template, puis impression/partage PDF.

La migration `00036` consolide le premier niveau en ajoutant des RPC de rapports financiers filtrees par unite active.
