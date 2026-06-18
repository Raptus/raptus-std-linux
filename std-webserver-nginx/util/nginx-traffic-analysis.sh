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
# Mit --enrich werden die Top-Offender-IPs angereichert: Geo (Land/Stadt),
# ASN/Netzbetreiber und Abuse-Reputation. Quellen:
#   - ip-api.com (HTTP, kein Key) fuer Geo + ASN; faellt bei fehlendem
#     HTTP-Zugang automatisch auf Team Cymru (nur DNS) zurueck.
#   - AbuseIPDB fuer Abuse-Score/Reports, sofern ein API-Key vorliegt
#     (Env ABUSEIPDB_KEY oder Eintrag ABUSEIPDB_KEY=... in /root/.rslcfg).
# Diese Lookups gehen an externe Dienste und senden die betroffenen IPs
# dorthin; deshalb opt-in und nur fuer die Top-Offender.
#
# Usage:  ./nginx-traffic-analysis.sh <site> [--no-dns] [--enrich]
# Bsp.:   ./nginx-traffic-analysis.sh fors.ch
#         ./nginx-traffic-analysis.sh fors.ch --enrich
#         ./nginx-traffic-analysis.sh fors.ch --no-dns   (ohne Reverse-DNS)
#
# Laufzeit: ein voller Durchgang ueber das Log + Reverse-DNS der Top-IPs;
# bei grossen Logs durchaus 1-2 Minuten. --enrich kostet zusaetzlich ein
# paar Sekunden pro Offender-IP fuer die externen Lookups.
# ============================================================

set -u

# --- Parameter ---
SITE="${1:-}"
RESOLVE_DNS=1
ENRICH=0
TOP_N=15
N_ENRICH=10        # so viele Top-Offender werden bei --enrich angereichert

if [ -z "$SITE" ]; then
  echo "Fehler: Kein Site-Parameter angegeben." >&2
  echo "Usage: $0 <site> [--no-dns] [--enrich]" >&2
  echo "Beispiel: $0 fors.ch --enrich" >&2
  exit 1
fi

shift
for arg in "$@"; do
  case "$arg" in
    --no-dns) RESOLVE_DNS=0 ;;
    --enrich) ENRICH=1 ;;
    *) echo "Warnung: unbekanntes Argument '$arg' ignoriert." >&2 ;;
  esac
done

# AbuseIPDB-Key aufloesen: Env hat Vorrang, sonst aus /root/.rslcfg
ABUSEIPDB_KEY="${ABUSEIPDB_KEY:-}"
if [ -z "$ABUSEIPDB_KEY" ] && [ -r /root/.rslcfg ]; then
  ABUSEIPDB_KEY=$(awk -F= '/^[[:space:]]*ABUSEIPDB_KEY[[:space:]]*=/{
    v=$2; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); gsub(/["'\'']/,"",v); print v; exit
  }' /root/.rslcfg)
fi

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

# --- JSON-Feld aus flachem JSON ziehen (ohne jq-Abhaengigkeit) ---
# json_str <json> <key>  -> String-Wert (mit Dekodierung haeufiger \uXXXX/\/ Escapes)
# json_raw <json> <key>  -> Zahl/Boolean-Wert
json_str() {
  grep -oP "\"$2\"\\s*:\\s*\"\\K[^\"]*" <<<"$1" | head -1 \
    | sed -e 's/\\u0026/\&/g' -e 's/\\u003c/</g' -e 's/\\u003e/>/g' \
          -e 's#\\/#/#g' -e 's#\\u002[fF]#/#g'
}
json_raw() { grep -oP "\"$2\"\\s*:\\s*\\K(true|false|-?[0-9.]+)" <<<"$1" | head -1; }

# --- Team-Cymru-Lookup (nur DNS) als Fallback: gibt "ASxxxx<TAB>Name<TAB>CC" ---
cymru_lookup() {
  local ip="$1" rev t asn cc name n
  case "$ip" in *:*) return 0 ;; esac          # IPv6 hier nicht unterstuetzt
  rev=$(echo "$ip" | awk -F. 'NF==4{print $4"."$3"."$2"."$1}')
  test -z "$rev" && return 0
  t=$(timeout 3 dig +short TXT "${rev}.origin.asn.cymru.com" 2>/dev/null | head -1 | tr -d '"')
  test -z "$t" && return 0
  # Format: "4134 | 1.0.0.0/24 | CN | apnic | 2011-04-30"
  asn=$(echo "$t" | awk -F'|' '{gsub(/[[:space:]]/,"",$1); print $1}')
  cc=$(echo  "$t" | awk -F'|' '{gsub(/[[:space:]]/,"",$3); print $3}')
  if [ -n "$asn" ]; then
    n=$(timeout 3 dig +short TXT "AS${asn}.asn.cymru.com" 2>/dev/null | head -1 | tr -d '"')
    name=$(echo "$n" | awk -F'|' '{sub(/^[[:space:]]*/,"",$NF); print $NF}')
  fi
  printf 'AS%s\t%s\t%s\n' "$asn" "$name" "$cc"
}

# --- Top-Offender mit Geo / ASN / Abuse anreichern ---
enrich_top() {
  section "TOP $N_ENRICH OFFENDER (Geo / ASN / Abuse)"

  local have_curl=0
  command -v curl >/dev/null 2>&1 && have_curl=1
  if [ "$have_curl" -eq 1 ]; then
    echo "  Geo/ASN  : ip-api.com (HTTP), Fallback Team Cymru (DNS)"
  else
    echo "  Geo/ASN  : 'curl' fehlt -> nur Team Cymru (DNS), keine Stadt/ISP"
  fi
  if [ -n "$ABUSEIPDB_KEY" ] && [ "$have_curl" -eq 1 ]; then
    echo "  Abuse    : AbuseIPDB (Key konfiguriert)"
  elif [ -n "$ABUSEIPDB_KEY" ]; then
    echo "  Abuse    : AbuseIPDB-Key gesetzt, aber 'curl' fehlt -> uebersprungen"
  else
    echo "  Abuse    : kein ABUSEIPDB_KEY -> Abuse-Zeile uebersprungen"
  fi
  echo "  (externe Lookups, kann einen Moment dauern ...)"
  echo ""

  sort -t$'\t' -k1,1 -rn "$TMP/ip" | head -"$N_ENRICH" \
    | while IFS=$'\t' read -r be tot ip; do
        test "$be" -eq 0 && continue

        local host="-"
        if [ "$RESOLVE_DNS" -eq 1 ]; then
          host=$(timeout 2 dig +short -x "$ip" 2>/dev/null | sed 's/\.$//' | head -1)
          [ -z "$host" ] && host="-"
        fi

        local country="" cc="" city="" isp="" asfield="" hosting=""
        if [ "$have_curl" -eq 1 ]; then
          local j
          j=$(curl -s --max-time 4 \
              "http://ip-api.com/json/${ip}?fields=status,country,countryCode,city,isp,as,hosting" \
              2>/dev/null)
          if [ -n "$j" ] && [ "$(json_str "$j" status)" = "success" ]; then
            country=$(json_str "$j" country)
            cc=$(json_str "$j" countryCode)
            city=$(json_str "$j" city)
            isp=$(json_str "$j" isp)
            asfield=$(json_str "$j" as)
            hosting=$(json_raw "$j" hosting)
          fi
        fi

        # Fallback auf Cymru-DNS, falls ip-api nichts lieferte
        if [ -z "$asfield" ]; then
          local cy casn cname ccc
          cy=$(cymru_lookup "$ip")
          IFS=$'\t' read -r casn cname ccc <<<"$cy"
          [ -n "${casn:-}" ] && asfield="${casn} ${cname:-}"
          [ -z "$cc" ] && cc="${ccc:-}"
        fi

        local abuse_line=""
        if [ -n "$ABUSEIPDB_KEY" ] && [ "$have_curl" -eq 1 ]; then
          local a score reports usage
          a=$(curl -s --max-time 5 -G https://api.abuseipdb.com/api/v2/check \
              --data-urlencode "ipAddress=${ip}" -d maxAgeInDays=90 \
              -H "Key: ${ABUSEIPDB_KEY}" -H "Accept: application/json" 2>/dev/null)
          score=$(json_raw "$a" abuseConfidenceScore)
          reports=$(json_raw "$a" totalReports)
          usage=$(json_str "$a" usageType)
          if [ -n "$score" ]; then
            abuse_line="Score ${score}% / ${reports:-0} Reports"
            [ -n "$usage" ] && abuse_line="${abuse_line} (${usage})"
          elif [ -n "$a" ]; then
            local errmsg
            errmsg=$(json_str "$a" detail)
            abuse_line="Lookup fehlgeschlagen${errmsg:+: $errmsg}"
          fi
        fi

        # --- Block ausgeben ---
        printf "  %s\n" "$ip"
        printf "    Backend : %s Req (%s%% dieser IP)\n" \
               "$(fmt "$be")" "$(pct "$be" "$tot")"

        local geo="-"
        if [ -n "$country" ]; then
          geo="${country} (${cc:-?})"; [ -n "$city" ] && geo="${geo}, ${city}"
        elif [ -n "$cc" ]; then
          geo="(${cc})"
        fi
        printf "    Geo     : %s\n" "$geo"

        # as-Feld enthaelt bereits ASN + Betreiber; isp nur als Fallback
        local net="${asfield:-}"
        [ -z "$net" ] && net="${isp:--}"
        [ "$hosting" = "true" ] && net="${net}   [Hosting/Datacenter]"
        printf "    Netz    : %s\n" "$net"

        [ -n "$abuse_line" ] && printf "    Abuse   : %s\n" "$abuse_line"
        printf "    rDNS    : %s\n" "$host"
        echo ""
      done
}

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

test "$ENRICH" -eq 1 && enrich_top

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
