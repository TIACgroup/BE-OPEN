# Post-instalacioni koraci

### Kreiranje zajednice i kolekcije

Nakon podizanja aplikacije, potrebno je sa administratorskim nalogom kreirati zajednicu i kolekciju. To se postiže tako što se nakon logovanja klikne na profil > Upravljati > Sadržina > Zajednice & kolekcije.
Potrebno je kreirati zajednicu i za tu zajednicu bar jednu kolekciju.

### Uvoz departmana i istraživača
Alat za import se nalazi u instalacionom direktorijumu na putanji: `install-tools/import`.
U direktorijum `UNS` treba ubaciti Excel dokumente popunjene sa podacima istraživača, primer dokumenta se nalazi u direktorijumu.

Nakon toga, potrebno je otvoriti dokument `BEOPEN - Uvoz istrazivaca.xlsm` i pokrenuti makro za uvoz. Kao rezultat toga, popuniće se dokumenti `dspace-cris-ogranization-import.xls` i `dspace-cris-researcher-import.xls`.

Te dokumente je potrebno importovati na sledeći način: sa administratorskim nalogom se klikne na profil > Upravljati > CRIS modul > Uvoz. Prvo treba selektovati `Organizaciona jedinica` i importovati `dspace-cris-ogranization-import.xls`, a zatim treba selektovati `Istraživač` pa importovati `dspace-cris-researcher-import.xls`.

### Scopus import
Za import publikacija sa Scopus-a potrebno je pokrenuti sledeću skriptu:  
`/dspace/bin/dspace dsrun org.dspace.app.cris.batch.ScopusFeed -q "AF-ID(scopus_id_univerziteta)" -p email_administratora -c 1`  
I nakon što prva završi, sledeću:  
`/dspace/bin/dspace dsrun org.dspace.app.cris.batch.ItemImportMainOA -E email_administratora`  
U obe skripte zameniti `scopus_id_univerziteta` i `email_administratora` sa odgovarajućim parametrima.

### Dnevni taskovi
Poželjno je kao cron taskove dnevno izvršavati sledeće skripte:  
`/dspace/bin/view-and-download-retrieve`  
`/dspace/bin/scopus-retrieve`  
`/dspace/bin/network-builder`  