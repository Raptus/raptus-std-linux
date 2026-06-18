#!/bin/bash
# ============================================================
# nginx-traffic-analysis.sh
# Aufgeraeumter Traffic-Report einer Site aus dem nginx-Access-Log.
#
# Erwartet das cache_log-Format (siehe nginx.conf):
#   $remote_addr - $upstream_cache_status [$time_local]
#   "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
#
# Jeder Request wird in eine von drei Klassen einsortiert:
#   CACHE    = $upstream_cache_status == HIT     -> von nginx aus Cache, billig
#   STATISCH = $upstream_cache_status == "-" und URL ist eine statische
#              Datei (.css/.js/Bilder/Fonts ...) -> von nginx ab Platte, billig
#   BACKEND  = alles andere (MISS/BYPASS/EXPIRED/STALE/UPDATING, sowie
#              dynamische "-")                   -> geht an PHP-FPM/Proxy, teuer
#
# Nur BACKEND erzeugt die Last, die den Webserver in die Knie zwingt.
# Der Report rankt IPs, URLs und Bots nach genau dieser Backend-Last.
#
# Usage:  ./nginx-traffic-analysis.sh <site> [--no-dns]
# Bsp.:   ./nginx-traffic-analysis.sh fors.ch
#         ./nginx-traffic-analysis.sh fors.ch --no-dns   (ohne Reverse-DNS)
#
# Laufzeit: ein voller Durchgang ueber das Log + Reverse-DNS der Top-IPs;
# bei grossen Logs durchaus 1-2 Minuten.
# ============================================================

set -u

# --- Parameter ---
SITE="${1:-}"
RESOLVE_DNS=1
TOP_N=15

if [ -z "$SITE" ]; then
  echo "Fehler: Kein Site-Parameter angegeben." >&2
  echo "Usage: $0 <site> [--no-dns]" >&2
  echo "Beispiel: $0 fors.ch" >&2
  exit 1
fi

shift
for arg in "$@"; do
  case "$arg" in
    --no-dns) RESOLVE_DNS=0 ;;
    *) echo "Warnung: unbekanntes Argument '$arg' ignoriert." >&2 ;;
  esac
done

LOGFILE="/home/sites/${SITE}/pub/log/nginx-access.log"

if [ ! -f "$LOGFILE" ]; then
  echo "Fehler: Logfile nicht gefunden: $LOGFILE" >&2
  echo "Hinweis: Fuer diese Site ist kein access_log vorhanden." >&2
  exit 1
fi
if [ ! -s "$LOGFILE" ]; then
  echo "Fehler: Logfile ist leer: $LOGFILE" >&2
  exit 1
fi

# Temp-Verzeichnis fuer die Zwischenergebnisse des awk-Durchgangs
TMP=$(mktemp -d /tmp/nta.XXXXXX) || { echo "mktemp fehlgeschlagen" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# --- Hilfsfunktionen ---
section() {
  local title="$1" line fill
  line="=== $title "
  fill=$((60 - ${#line}))
  test "$fill" -lt 0 && fill=0
  printf '\n%s%s\n' "$line" "$(printf '%*s' "$fill" '' | tr ' ' '=')"
}

# Zahl mit Tausender-Hochkomma (Schweizer Notation): 68178 -> 68'178
fmt() {
  awk -v n="$1" 'BEGIN{
    s=sprintf("%d", n); o=""; c=0
    for (i=length(s); i>0; i--) { o=substr(s,i,1) o; if (++c%3==0 && i>1) o="\47" o }
    print o
  }'
}

# Prozent a von b, eine Nachkommastelle
pct() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.1f", (b ? a/b*100 : 0)}'; }

# ============================================================
#  EIN Durchgang ueber das Log: klassifizieren + aggregieren
# ============================================================
gawk -v F_STATUS="$TMP/status" -v F_CLASS="$TMP/class" -v F_IP="$TMP/ip" \
     -v F_URL="$TMP/url" -v F_UA="$TMP/ua" -v F_META="$TMP/meta" '
{
  total++
  status = $3

  # Zeitrahmen: Feld 4 == [TT/Mon/JJJJ:HH:MM:SS
  if (total == 1) first = substr($4, 2)
  last = substr($4, 2)

  # Pfad aus dem Request "GET /pfad?x=1 HTTP/1.1" == Feld 7, Query weg
  path = $7; sub(/\?.*/, "", path); lp = tolower(path)
  is_static = (lp ~ /\.(css|js|mjs|png|jpe?g|gif|svg|ico|bmp|webp|avif|tiff?|woff2?|ttf|eot|otf|mp4|webm|ogg|mp3|wav|flac|pdf|zip|gz|tgz|tar|map|txt|webmanifest)$/)

  # User-Agent == letztes Quote-Paar der Zeile
  if (match($0, /"([^"]*)"[ \t]*$/, m)) ua = m[1]; else ua = "-"

  statuscount[status]++

  if (status == "HIT")      cls = "cache"
  else if (status == "-")   cls = (is_static ? "static" : "backend")
  else                      cls = "backend"
  classcount[cls]++

  iptot[$1]++
  uatot[ua]++
  if (cls == "backend") {
    ipbe[$1]++
    uabe[ua]++
    if (path != "") urlbe[path]++
  }
}
END {
  for (s in statuscount) printf "%d\t%s\n",      statuscount[s], s        > F_STATUS
  for (c in classcount)  printf "%d\t%s\n",      classcount[c],  c        > F_CLASS
  for (ip in iptot)      printf "%d\t%d\t%s\n",   ipbe[ip]+0, iptot[ip], ip > F_IP
  for (u in urlbe)       printf "%d\t%s\n",       urlbe[u], u             > F_URL
  for (a in uatot)       printf "%d\t%d\t%s\n",   uabe[a]+0, uatot[a], a   > F_UA
  printf "%d\t%s\t%s\n", total, first, last                              > F_META
}' "$LOGFILE"

# --- Aggregierte Kennzahlen einlesen ---
IFS=$'\t' read -r TOTAL FIRST LAST < "$TMP/meta"
BACKEND=$(awk -F'\t' '$2=="backend"{print $1}' "$TMP/class"); BACKEND=${BACKEND:-0}
CACHE=$(awk   -F'\t' '$2=="cache"{print $1}'   "$TMP/class"); CACHE=${CACHE:-0}
STATIC=$(awk  -F'\t' '$2=="static"{print $1}'  "$TMP/class"); STATIC=${STATIC:-0}

# Cache-Hit-Ratio nur ueber cachebare Requests (Status != "-")
HITRATIO=$(awk -F'\t' '$2!="-"{tot+=$1} $2=="HIT"{hit=$1} END{printf "%.1f", (tot?hit/tot*100:0)}' "$TMP/status")

# Top-Backend-IP fuer die Zusammenfassung
read -r TOPBE_BE TOPBE_TOT TOPBE_IP < <(sort -t$'\t' -k1,1 -rn "$TMP/ip" | head -1 | tr '\t' ' ')
TOPBE_BE=${TOPBE_BE:-0}; TOPBE_TOT=${TOPBE_TOT:-0}; TOPBE_IP=${TOPBE_IP:--}

# ============================================================
#  Ausgabe
# ============================================================
echo ""
echo "============================================================"
echo "  NGINX Traffic-Report: $SITE"
echo "  $LOGFILE"
echo "  $(date '+%d.%m.%Y %H:%M:%S')"
echo "============================================================"

section "ZUSAMMENFASSUNG"
printf "  Zeitraum : %s  bis  %s\n" "$FIRST" "$LAST"
printf "  Requests : %s total\n" "$(fmt "$TOTAL")"
echo ""
printf "  %-26s %12s  %5s%%\n" "BACKEND-LAST (PHP/Proxy)" "$(fmt "$BACKEND")" "$(pct "$BACKEND" "$TOTAL")"
printf "  %-26s %12s  %5s%%\n" "Aus Cache (HIT)"          "$(fmt "$CACHE")"   "$(pct "$CACHE" "$TOTAL")"
printf "  %-26s %12s  %5s%%\n" "Statisch (nginx ab Platte)" "$(fmt "$STATIC")" "$(pct "$STATIC" "$TOTAL")"
echo ""
if [ "$TOPBE_BE" -gt 0 ]; then
  printf "  Groesster Backend-Verursacher: %s\n" "$TOPBE_IP"
  printf "    %s Backend-Requests von %s total (%s%% dieser IP)\n" \
         "$(fmt "$TOPBE_BE")" "$(fmt "$TOPBE_TOT")" "$(pct "$TOPBE_BE" "$TOPBE_TOT")"
fi

section "CACHE-EFFEKTIVITAET"
printf "  %-9s %12s %7s\n" "STATUS" "COUNT" "ANTEIL"
sort -t$'\t' -k1,1 -rn "$TMP/status" | while IFS=$'\t' read -r cnt st; do
  printf "  %-9s %12s %6s%%\n" "$st" "$(fmt "$cnt")" "$(pct "$cnt" "$TOTAL")"
done
echo ""
printf "  Hit-Ratio (HIT / cachebare Requests): %s%%\n" "$HITRATIO"
echo "  \"-\" = keine Cache-Direktive aktiv (statisch ODER ungecacht ans Backend)"

section "TOP $TOP_N IPs NACH BACKEND-LAST"
printf "  %9s %9s %6s  %-18s %s\n" "BACKEND" "TOTAL" "BE%" "IP" "HOSTNAME"
sort -t$'\t' -k1,1 -rn "$TMP/ip" | head -"$TOP_N" | while IFS=$'\t' read -r be tot ip; do
  test "$be" -eq 0 && continue
  host="-"
  if [ "$RESOLVE_DNS" -eq 1 ]; then
    host=$(timeout 2 dig +short -x "$ip" 2>/dev/null | sed 's/\.$//' | head -1)
    [ -z "$host" ] && host="-"
  fi
  printf "  %9s %9s %5s%%  %-18s %s\n" \
         "$(fmt "$be")" "$(fmt "$tot")" "$(pct "$be" "$tot")" "$ip" "$host"
done

section "TOP $TOP_N URLs NACH BACKEND-LAST"
printf "  %9s  %s\n" "BACKEND" "URL"
sort -t$'\t' -k1,1 -rn "$TMP/url" | head -"$TOP_N" | while IFS=$'\t' read -r cnt url; do
  printf "  %9s  %s\n" "$(fmt "$cnt")" "$url"
done

section "BOTS / AUTOMATISIERTER TRAFFIC (nach Backend-Last)"
BOT_PATTERNS="bot|crawl|spider|scan|python-requests|curl|wget|scrapy|zgrab|masscan|nikto|sqlmap|nmap|Go-http|libwww|Jakarta|Apache-HttpClient|okhttp|axios|java/|HeadlessChrome|PetalBot|SemrushBot|AhrefsBot|MJ12bot|DotBot|GPTBot|ClaudeBot|Bytespider"
printf "  %9s %9s  %s\n" "BACKEND" "TOTAL" "USER-AGENT"
sort -t$'\t' -k1,1 -rn "$TMP/ua" | grep -iE "$BOT_PATTERNS" | head -"$TOP_N" \
  | while IFS=$'\t' read -r be tot ua; do
      printf "  %9s %9s  %s\n" "$(fmt "$be")" "$(fmt "$tot")" "$ua"
    done

section "GEGENMASSNAHMEN (zum Kopieren ins Ticket)"
echo "  IP blockieren (nginx)    : deny <IP>;   in server {} oder http {}"
echo "  IP blockieren (Firewall) : shorewall reject <IP>   bzw. Cloudflare-Rule"
echo "  Rate-Limiting (nginx)    :"
echo "    limit_req_zone \$binary_remote_addr zone=one:10m rate=30r/m;"
echo "  Cache greift nicht?      : hoher MISS-Anteil oder viele dynamische \"-\""
echo "                             => fastcgi_cache auf der Site aktivieren"

echo ""
echo "============================================================"
echo "  Report abgeschlossen."
echo "============================================================"
echo ""
