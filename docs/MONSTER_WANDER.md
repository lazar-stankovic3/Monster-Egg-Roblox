# Monster kretanje po plotu

Status 2026-09-20: implementirano između faza 17 i 18, čeka Studio potvrdu.

Svaki hatchovani monster automatski ulazi u centralni `MonsterWanderService`. Monster čeka nasumično vreme, bira kratku destinaciju na vlasnikovom `Place` delu, okreće se u smeru kretanja, hoda do nje i ponovo zastaje. Sistem radi i za nove hatch monstere i za monstere vraćene iz PlayerData-a.

Destinacija uzima u obzir veličinu monstera, ivice `Place` dela, druga jaja i druge monstere. Ako nema dovoljno slobodnog prostora, monster ostaje na mestu i pokušava kasnije. Kretanje je server-side i modeli ostaju usidreni, pa fizički sudari igrača ne mogu da ih odguraju sa plota. Trenutna pozicija i orijentacija ulaze u redovan save faze 17.

Brzina, dužina šetnje, vreme pauze, razmak i učestalost provere nalaze se u `ReplicatedStorage.Modules.MonsterWanderConfig`.

## Studio test

1. Postavi i izlegni najmanje dva monstera. Posle 1.5–4.5 sekundi treba samostalno da krenu, pređu kratku razdaljinu, stanu i kasnije nastave.
2. Proveri da se okreću u smeru hodanja, ostaju na površini `Place` dela i ne prelaze preko njegovih ivica.
3. Postavi jaja i više monstera blizu njih. Nove destinacije ne treba da završavaju preko zauzetog mesta; na prepunom plotu monster sme da ostane i čeka.
4. Proveri Tiny i Titanic veličinu. Obe moraju ostati unutar granica plota.
5. Izađi dok su monsteri na različitim mestima i ponovo uđi. Faza 17 treba da vrati njihove pozicije, nakon čega nastavljaju lutanje.
6. Sa dva igrača proveri da svaki monster ostaje samo na plotu svog vlasnika. Reset Character ne sme da zaustavi ili duplira sistem.

Rojo build potvrđuje pakovanje. Vizuelno kretanje, granice i ponašanje u zgusnutom plotu moraju se potvrditi u Studiju.
