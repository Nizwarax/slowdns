# slowdns

Pack SlowDNS (tunnel DNS / [dnstt](https://www.bamsoftware.com/software/dnstt/)) untuk VPS Debian/Ubuntu, versi bersih — stub bzip2 pembungkusnya sudah dibongkar, jadi `slow.sh` bisa dibaca langsung.

Repo ini **private**; file disajikan lewat GitHub Pages supaya installer bisa `wget` tanpa token:

`https://nizwarax.github.io/slowdns/`

## Isi

| File | Fungsi |
|---|---|
| `slow.sh` | Installer utama: apt deps, build dnstt, generate keypair, dua unit systemd, `rc.local` (badvpn + redirect udp/53), reboot |
| `ns.sh` | Bikin subdomain acak + record NS `dns.<sub>` lewat Cloudflare API, simpan ke `/etc/xray/ns.txt` |
| `plugin.zip` | Source dnstt (server + client) yang di-build di VPS |
| `sshd` | `sshd_config` pengganti (port 22/2222/2269, `PermitRootLogin yes`) |

Zona: `maxe.de5.net`. Target NS: isi `/etc/xray/domain` (hostname VPS atau hostname lain yang mengarah ke VPS, bukan IP).

## Prasyarat

- Debian/Ubuntu, akses root
- Port **udp/53 bebas** — matikan dulu `systemd-resolved` / `dnsmasq` / Docker DNS
- `/etc/xray/domain` sudah ada dan berisi hostname (ns.sh tidak punya cadangan; tanpa file ini skrip gagal)
- `golang`, `unzip`, `screen` boleh terpasang, tidak wajib — installer memasangnya sendiri
- Akun Cloudflare pemilik zona; saat ini kredensial menempel di `ns.sh` (baris 28–29)

## Pasang

```sh
wget -qO slow.sh https://nizwarax.github.io/slowdns/slow.sh
bash slow.sh
```

Installer berakhir dengan `reboot`.

Setelah reboot:

```sh
systemctl status server client
cat /etc/xray/ns.txt
iptables -t nat -L PREROUTING -n | grep 5300
```

## Cara kerja

- `dnstt-server` listen `udp/:5300`, meneruskan ke `127.0.0.1:2269` (SSH)
- `dnstt-client` keluar ke resolver `8.8.8.8:53` menuju `<ns.txt>`, menyediakan `127.0.0.1:3369` (xray)
- `iptables -t nat PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300`
- `rc.local` menyalakan `badvpn-udpgw` di 7100/7200/7300 dan meng-`disable_ipv6`
- Keypair: `/etc/slowdns/server.key` (privat) + `server.pub` (dibagikan ke klien)

Klien: `dnstt-client -udp 8.8.8.8:53 --pubkey-file server.pub <ns.txt> 127.0.0.1:3369`

## Yang perlu diwaspadai

- `wget -O /etc/ssh/sshd_config` **menimpa** konfigurasi SSH tanpa backup dan tanpa `sshd -t`. Simpan dulu: `cp -a /etc/ssh/sshd_config /root/sshd_config.bak`. Kalau unduhan gagal, isi file jadi HTML dan SSH bisa mati.
- `apt purge apache2`, `hostnamectl set-hostname GEOVPN`, dan `reboot` di akhir — jangan jalankan di VPS yang sudah dipakai tanpa pikir.
- Kredensial Cloudflare Global API Key tertulis di `ns.sh` = akses penuh seluruh zona akun itu. Ganti di baris 28–29 (email + key) bila bocor; baris 23 dan 26 (domain dan suffix di `SUB_DOMAIN`) harus ikut diganti ke zona yang sama.
- `iptables` dimuat lewat `rc.local`, bukan unit sendiri; `systemctl enable rc-local` tidak ada di semua distro.
- Installer menghapus `/root/ns.sh` setelah dipakai (`rm -f` di akhir `ns.sh`).
- Tunnel ini lambat (MTU/abuse DNS), tidak cocok untuk transfer besar.

## Verifikasi paket

```sh
sha256sum slow.sh ns.sh plugin.zip
```

Bandingkan dengan nilai di riwayat commit; `sha256sum` untuk `slow.sh` yang beredar di repo ini sebelumnya: `b315656b8ed80bbd5c4809912539400ab12dd620984e91504a267fe84fcb396f` (sebelum URL diarahkan ke `nizwarax.github.io`).
