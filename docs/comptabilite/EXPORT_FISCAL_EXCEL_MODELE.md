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
