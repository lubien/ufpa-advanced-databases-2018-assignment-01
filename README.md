# Queries over binary files using the BEAM ecosystem

Code used for [@gustavopinto](https://github.com/gustavopinto) Advanced Databases classroom [first assignment](http://gustavopinto.org/teaching/bd2/exercise).

[Full report](https://github.com/lubien/ufpa-advanced-databases-2018-assignment-01-report/releases) is written in portuguese.

Overview:

  * Create a single-file single-table database to save 1 billion people.
  * Each person is a 64 bits tuple with gender (1), age (7), monthly income (10), scholarity (2), idiom (12), country (8) and coordinates (24).
  * Implement 7 queries from the assignment and 3 of your choice.
  * Export the binary database to a relational DBMS.
  * Compare results.

## Setup

Generate the binary file.

```sh
head -c 8000000000 </dev/urandom >people.db
```

Setup PostgreSQL. You may change env variables, but it's optional. Below are the default.

```sh
export DB_NAME=ufpa-databases-2
export DB_USER=postgres

make prepare
```

Export the binary database to CSV then import to PostgreSQL.

```sh
make dump-database
make import-dump
```

Prepare Elixir.

```sh
mix deps.get
mix compile
```
## Query

Elixir.

```sh
# from 1 to 10
mix query --db people.db --query 1
```

PostgreSQL.

```sh
# from 1 to 10
make query-1
```

## Results

This machine was used:

```sh
λ neofetch
OS: Manjaro Linux x86_64 
Host: B250M-D3H 
Kernel: 4.14.77-1-MANJARO 
Uptime: 12 hours, 58 mins 
Packages: 1024 (pacman) 
Shell: bash 4.4.23 
Resolution: 1360x768, 2560x1080 
DE: Xfce 
Theme: Vertex-Maia [GTK2], Breath [GTK3] 
Icons: Vertex-Maia [GTK2], hicolor [GTK3] 
Terminal: xfce4-terminal 
Terminal Font: Monospace 12 
CPU: Intel i5-7400 (4) @ 3.500GHz 
GPU: NVIDIA GeForce GT 610 
Memory: 3204MiB / 7939MiB

λ lscpu
Arquitetura:                x86_64
Modo(s) operacional da CPU: 32-bit, 64-bit
Ordem dos bytes:            Little Endian
CPU(s):                     4
Lista de CPU(s) on-line:    0-3
Thread(s) per núcleo:       1
Núcleo(s) por soquete:      4
Soquete(s):                 1
Nó(s) de NUMA:              1
ID de fornecedor:           GenuineIntel
Família da CPU:             6
Modelo:                     158
Nome do modelo:             Intel(R) Core(TM) i5-7400 CPU @ 3.00GHz
Step:                       9
CPU MHz:                    800.050
CPU MHz máx.:               3500,0000
CPU MHz mín.:               800,0000
BogoMIPS:                   6002.00
Virtualização:              VT-x
cache de L1d:               32K
cache de L1i:               32K
cache de L2:                256K
cache de L3:                6144K
CPU(s) de nó0 NUMA:         0-3

λ sudo hdparm -Tt /dev/sda

/dev/sda:
 Timing cached reads:   26046 MB in  1.99 seconds = 13068.87 MB/sec
 Timing buffered disk reads: 392 MB in  3.00 seconds = 130.50 MB/sec
```

Query       | First (DBMS)    | First (Bin)     | Mean (DBMS)  | Mean (Bin)
------------|-----------------|-----------------|--------------|-----------
1           | 748s            | 134s            | 640s         | 134s
2           | -               | 456s            | -            | 453s
3           | 629s            | 160s            | 622s         | 161s
4           | 620s            | 173s            | 614s         | 163s
5           | 705s            | 59s             | 618s         | 59s
6           | 861s            | 63s             | 623s         | 61s
7           | 631s            | 67s             | 604s         | 62s
8           | 619s            | 60s             | 622s         | 59s
9           | 639s            | 59s             | 626s         | 60s
10          | 622s            | 61s             | 628s         | 60s

Query 2 never finished on PostgreSQL so...
