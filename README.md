# WinRegTools
Fontos Regisztry értékek Win tuninghoz, okos beállításokhoz, optimalizáláshoz



# Összefoglaló:
Hamarosan!
Lista:
- 48 Bit LBA (On - Off)
- LongPaths (On - Off)
- Lapozófájl törlése kilépéskor
- Temp - HAMAROSAN!
- RPC Kiszolgáló Hiba
- Készülőben! QoS Packet Scheduler
- 


# Kompatibilitás:
Egy központi konfigurációs fájl a repó gyökerében szabályozza a rendszerekhez való kompatibilitást (Főleg automatikus használat/telepítés esetén lesz jelentősége!)
Fájlnév: systems_config.json
Ez a fájl tartalmazza a logikát: melyik OS-hez melyik megoldás (script vagy reg) tartozik, és mi a javaslat, így a systems_config.json-ra épülő, dinamikus menürendszer előnye, hogy a script automatikusan a Windows verziójához igazítja az elérhető műveleteket. Ez a megoldás kiküszöböli a felesleges opciókat és egyszerűsíti a jövőbeni bővítéseket a menüpontok fix kódolása nélkül. Az RTS repóhoz is könnyebben használható!

# Vezérlés:
Ezzel a két fájllal lehet indítani, hogy sorban futtatni lehessen a beállításokat, finom-hangolást!
- master.bat (A repó gyökerébe)
Ez a belépési pont. Ha Win7 vagy újabb, átdobja a labdát a PowerShellnek, ha régebbi, marad a karakteres menü a .reg fájlokhoz.
- Script\Master_Script.ps1
Ez a modern rendszerek agya. Beolvassa a JSON-t (ha van), de önállóan is kezeli a menüt az általad kért UTF8/Admin követelményekkel.


# 1. 48 Bit LBA: Van még relevanciája?
A cikkeimben leírt 48-bit LBA (EnableBigLba) probléma ma már csak retró környezetben (XP SP1 előtt) releváns a 137 GB feletti merevlemezek kezeléséhez. 

A modern rendszereken (Win10/11) tapasztalt "túl hosszú nevek" hiba már nem címzési korlát (LBA), hanem a 260 karakteres elérési út korlátja (MAX_PATH). Bár a jelenség hasonló (adatvesztés vagy hiba), a megoldás már egy másik regisztrációs kulcs: LongPathsEnabled

# 2. Retró gépekhez: 48-bit LBA .reg fájlok
Ezeket a fájlokat Windows 2000 (SP3 előtt) és Windows XP (SP1 előtt) rendszereken használd.
- 48BitLBA_On.reg
- 48BitLBA_Off.reg


# 3. Lapozófájl törlése kilépéskor
Csökkenti a lemezterület töredezettségét, gyorsabb az elindulás, hátrány: talán picit lassabb a leállítás


# 4. Temp - HAMAROSAN!
A "TMP", "temp", "TEMP" mappák egységes kezelése a Windows-on!
(Kevesebb szemét, kevésbé töredezett váló meghajtó, gyorsabb telepítések, futtarások, gyorsabb rendszer elérés)


# 4. RPC Kiszolgáló Hiba
Ipsm által okozott "RPC kiszolgáló nem indul" hiba javítása

# 5. QoS Packet Scheduler
A sávszélesség-korlátozás feloldása (QoS Packet Scheduler és társai) klasszikus teljesítményfokozó téma!
(A hálózati sávszélesség kihasználása adatátvitelre)


# Mai gépekhez: Modern PowerShell szkript (Hosszú nevek kezelése)
Ez a szkript lekérdezi a jelenlegi állapotot, és rákérdez a módosításra. Alapból rendszergazdai jogot kér.

# Melyiket mikor érdemes kapcsolni?


| Rendszer | Téma | Megoldás | Javaslat / Indoklás |
| :--- | :--- | :--- | :--- |
| **Win 95 / 98** | 48-bit LBA | Driver kell | Regisztrációs kulcs önmagában nem elég; harmadik féltől patch/driver szükséges. |
| **Win 95 - XP** | Swap Törlés | `.reg` | `ClearPageFileAtShutdown=1`. Csökkenti a töredezettséget. |
| **Win NT 4.0** | 48-bit LBA | `.reg` | Csak SP6 és speciális ATAPI driver frissítés után működik stabilan. |
| **Win XP / 2000** | 48-bit LBA | `.reg` | 137 GB felett kötelező, SP1/SP3 előtt kézzel kell, utána elvileg megy, de ellenőrizni érdemes. (XP SP1 / W2k SP3 előtt). |
| **Windows 7** | 48-bit LBA | **Alapból Be** | Nincs szükség kézi beavatkozásra a lemezmérethez. |
| **Win7** | Swap Törlés | `.ps1` | Itt már PowerShell alapú kezelés javasolt,de a Win7 alapból nem engedi a szkripteket (Restricted), így a master.bat-ban a -ExecutionPolicy Bypass kapcsoló lesz segítségünkre. |
| XP / Win7 | RPC Fix | .reg / .ps1 | Intel Ipsm által okozott "RPC kiszolgáló nem indul" hiba javítása. |
| Win10 / 11 | RPC Fix | .ps1 | Megelőzés: Ellenőrzi és javítja az RPC szolgáltatás indítási típusát. |
| **Win10 / 11** | Long Paths | `.ps1` | 260 karakter feletti utakhoz (MAX_PATH feloldása). Segít a mély mappaszerkezetnél, de az Intéző (Explorer) korlátokba ütközhet. |
| **Win10 / 11** | Swap Törlés | `.ps1` | SSD-nél kevésbé kritikus, de biztonság miatt kérhető. |

> [!IMPORTANT]
> **Fontos:** Retró gépeken (XP és korábbiak) a 48-bit LBA bekapcsolása előtt győződj meg róla, hogy az alaplap BIOS-a is támogatja azt, különben adatvesztés történhet!


---
*Készült az RTS ([Reparing's - Tuning's - Setting's](https://github.com/LordAthis/RTS)) projekt keretében. Használható önállóan vagy a keretrendszer moduljaként is!*
