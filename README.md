# WinRegTools
Fontos Regisztry értékek Win tuninghoz, okos beállításokhoz, optimalizáláshoz



# 1. Összefoglaló: Van még relevanciája?
A cikkeimben leírt 48-bit LBA (EnableBigLba) probléma ma már csak retró környezetben (XP SP1 előtt) releváns a 137 GB feletti merevlemezek kezeléséhez. 

# A modern rendszereken (Win10/11) tapasztalt "túl hosszú nevek" hiba már nem címzési korlát (LBA), hanem a 260 karakteres elérési út korlátja (MAX_PATH). Bár a jelenség hasonló (adatvesztés vagy hiba), a megoldás már egy másik regisztrációs kulcs: LongPathsEnabled

2. Retró gépekhez: 48-bit LBA .reg fájlok
Ezeket a fájlokat Windows 2000 (SP3 előtt) és Windows XP (SP1 előtt) rendszereken használd.
- 48BitLBA_On.reg
- 48BitLBA_Off.reg


3. Mai gépekhez: Modern PowerShell szkript (Hosszú nevek kezelése)
Ez a szkript lekérdezi a jelenlegi állapotot, és rákérdez a módosításra. Alapból rendszergazdai jogot kér.


4. Melyiket mikor érdemes kapcsolni?
Rendszer 	Beállítás típusa	Javaslat	Indoklás
95 / 98	N/A	Driver kell	Regisztrációs kulcs önmagában nem elég, harmadik féltől származó patch/driver szükséges.
NT 4.0	48-bit LBA	Be (SP6 után)	Csak SP6 és speciális ATAPI driver frissítés után működik stabilan.
XP / Win2000	48-bit LBA	Be (Kötelező)	Ha 137 GB-nál nagyobb a lemez, SP1/SP3 előtt kézzel kell, utána elvileg alapból megy, de ellenőrizni érdemes.
Win7	48-bit LBA	Alapból Be	Itt már nincs szükség kézi beavatkozásra a lemezmérethez.
Win10 / 11	Long Paths	Be (Opcionális)	Ha sok a mély mappaszerkezeted, kapcsold be, de tudd: az Intéző (Explorer) még így is korlátokba ütközhet.
Fontos: A retró gépeken (XP és korábbiak) a 48-bit LBA bekapcsolása előtt győződj meg róla, hogy az alaplap BIOS-a is támogatja azt, különben adatvesztés történhet.
