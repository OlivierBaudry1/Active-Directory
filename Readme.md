Installation et automatisation d’un Active Directory sur Windows, en important utilisateurs et groupes depuis un fichier CSV.

Script1 :
Installation des services AD.
Création de la forêt, du domaine, et configuration du mot de passe DSRM.

Script2 :
Lecture du CSV contenant les utilisateurs et leurs groupes. /!\ Par défaut le chemin d'accès du CSV est D:  /!\
Création automatique des unités organisationnelles si elles n’existent pas.
Détection dynamique des colonnes dans le CSV : le script s’adapte à n’importe quelle structure compatible.
Création des groupes listés dans le CSV, sans doublon.
Génération d’identifiants uniques pour chaque utilisateur (3 lettres du prénom + nom, tout en minuscules, sans caractères spéciaux, incrément si collision).
Création des comptes utilisateurs (prénom, nom, UPN, mot de passe par défaut, changement de mot de passe à la première connexion, rattachement à la bonne OU).
Préparation et affectation aux groupes : chaque utilisateur est ajouté à tous ses groupes en une seule opération groupée pour optimiser les appels AD.

test :
Recherche et affiche l’existence des unités organisationnelles cibles.
Récupère groupes et utilisateurs
Liste tous les groupes trouvés.
Liste tous les utilisateurs trouvés.
Pour chaque groupe, affiche ses membres.
