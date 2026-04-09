# WinRegTools
Fontos Regisztry értékek Win tuninghoz, okos beállításokhoz, optimalizáláshoz



# Összefoglaló:
Hamarosan!
Lista:
- 48 Bit LBA (On - Off)
- LongPaths (On - Off)
- Lapozófájl törlése kilépéskor (Csökkenti a lemezterület töredezettségét, gyorsabb az elindulás, hátrány: talán picit lassabb a leállítás)
- Temp (TMP, temp, TEMP) mappák egységes kezelése (Kevesebb szemét, kevésbé töredezett meghajtó, gyorsabb telepítések, rendszer elérés)
- 



# 1. 48 Bit LBA: Van még relevanciája?
A cikkeimben leírt 48-bit LBA (EnableBigLba) probléma ma már csak retró környezetben (XP SP1 előtt) releváns a 137 GB feletti merevlemezek kezeléséhez. 

A modern rendszereken (Win10/11) tapasztalt "túl hosszú nevek" hiba már nem címzési korlát (LBA), hanem a 260 karakteres elérési út korlátja (MAX_PATH). Bár a jelenség hasonló (adatvesztés vagy hiba), a megoldás már egy másik regisztrációs kulcs: LongPathsEnabled

# 2. Retró gépekhez: 48-bit LBA .reg fájlok
Ezeket a fájlokat Windows 2000 (SP3 előtt) és Windows XP (SP1 előtt) rendszereken használd.
- 48BitLBA_On.reg
- 48BitLBA_Off.reg

# 3. Mai gépekhez: Modern PowerShell szkript (Hosszú nevek kezelése)
Ez a szkript lekérdezi a jelenlegi állapotot, és rákérdez a módosításra. Alapból rendszergazdai jogot kér.

# 4. Melyiket mikor érdemes kapcsolni?


| Rendszer | Beállítás típusa | Javaslat | Indoklás |
| :--- | :--- | :--- | :--- |
| **Windows 95 / 98** | N/A | **Driver kell** | Regisztrációs kulcs önmagában nem elég; harmadik féltő patch/driver szükséges. |
| **Windows NT 4.0** | 48-bit LBA | **Be (SP6 után)** | Csak SP6 és speciális ATAPI driver frissítés után működik stabilan. |
| **Windows 2000 / XP** | 48-bit LBA | **Be (Kötelező)** | >137 GB-nál SP1/SP3 előtt kézzel kell, utána elvileg megy, de ellenőrizni érdemes. |
| **Windows 7** | 48-bit LBA | **Alapból Be** | Nincs szükség kézi beavatkozásra a lemezmérethez. |
| **Windows 10 / 11** | Long Paths | **Be (Opcionális)** | Segít a mély mappaszerkezetnél, de az Intéző (Explorer) korlátokba ütközhet. |

> [!IMPORTANT]
> **Fontos:** Retró gépeken (XP és korábbiak) a 48-bit LBA bekapcsolása előtt győződj meg róla, hogy az alaplap BIOS-a is támogatja azt, különben adatvesztés történhet!



