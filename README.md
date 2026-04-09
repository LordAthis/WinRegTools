# WinRegTools
Fontos Regisztry értékek Win tuninghoz, okos beállításokhoz, optimalizáláshoz



# Összefoglaló:
Hamarosan!
Lista:
- 48 Bit LBA (On - Off)
- LongPaths (On - Off)
- Lapozófájl törlése kilépéskor (Csökkenti a lemezterület töredezettségét, gyorsabb az elindulás, hátrány: talán picit lassabb a leállítás)
- Temp - HAMAROSAN! (TMP, temp, TEMP) mappák egységes kezelése (Kevesebb szemét, kevésbé töredezett meghajtó, gyorsabb telepítések, rendszer elérés)
- 


# Kompatibilitás:
Egy központi konfigurációs fájl a repó gyökerében szabályozza a rendszerekhez való kompatibilitást (Főleg automatikus használat/telepítés esetén lesz jelentősége!)
Fájlnév: systems_config.json
Ez a fájl tartalmazza a logikát: melyik OS-hez melyik megoldás (script vagy reg) tartozik, és mi a javaslat.


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


| Rendszer | Téma | Megoldás | Javaslat / Indoklás |
| :--- | :--- | :--- | :--- |
| **Win 95 / 98** | 48-bit LBA | Driver kell | Regisztrációs kulcs önmagában nem elég; harmadik féltől patch/driver szükséges. |
| **Win 95 - XP** | Swap Törlés | `.reg` | `ClearPageFileAtShutdown=1`. Csökkenti a töredezettséget. |
| **Win NT 4.0** | 48-bit LBA | `.reg` | Csak SP6 és speciális ATAPI driver frissítés után működik stabilan. |
| **Win XP / 2000** | 48-bit LBA | `.reg` | 137 GB felett kötelező, SP1/SP3 előtt kézzel kell, utána elvileg megy, de ellenőrizni érdemes. (XP SP1 / W2k SP3 előtt). |
| **Windows 7** | 48-bit LBA | **Alapból Be** | Nincs szükség kézi beavatkozásra a lemezmérethez. |
| **Win7** | Swap Törlés | `.ps1` | Itt már PowerShell alapú kezelés javasolt. |
| **Win10 / 11** | Long Paths | `.ps1` | 260 karakter feletti utakhoz (MAX_PATH feloldása). Segít a mély mappaszerkezetnél, de az Intéző (Explorer) korlátokba ütközhet. |
| **Win10 / 11** | Swap Törlés | `.ps1` | SSD-nél kevésbé kritikus, de biztonság miatt kérhető. |

> [!IMPORTANT]
> **Fontos:** Retró gépeken (XP és korábbiak) a 48-bit LBA bekapcsolása előtt győződj meg róla, hogy az alaplap BIOS-a is támogatja azt, különben adatvesztés történhet!



