# Faza 10 — PlotService

Prilagođeno 2026-09-20 na korisnikov zahtev za slobodno postavljanje jajeta.

PlotService koristi postojeće Workspace.Plots modele sa direktnim, usidrenim Place Part-om. Svakom igraču dodeljuje jedan plot, postavlja OwnerUserId i SlotCapacity=6, zadržava vlasništvo na respawn-u i oslobađa plot pri izlasku. Kada nema slobodnih plotova, igrač čeka i dobija prvi oslobođeni plot.

Šest slotova sada znači kapacitet šest slobodno postavljenih jaja. Nema fiksnih Slot1–Slot6 Part-ova niti PlotOrigin zahteva. Servis kreira i čisti samo namenski runtime folder PlacedEggs. Postojeći Build i ostali delovi mape ostaju sačuvani.

Postavka, atributi i objedinjeni Studio test dodele i postavljanja: [FAZA_11.md](FAZA_11.md). Faza 10 i dalje čeka Studio potvrdu; nije označena kao prošla.
