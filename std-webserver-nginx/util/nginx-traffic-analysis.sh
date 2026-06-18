#!/bin/bash
# ============================================================
# nginx-traffic-analysis.sh
# Lesbarer Traffic-Report einer Site aus dem nginx-Access-Log.
#
# Das Log wird im cache_log-Format erwartet (siehe nginx.conf):
#   $remote_addr - $upstream_cache_status [$time_local]
#   "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
#
# Der Report ist zum Durchlesen gedacht: er zeigt die Fakten,
# die Einschaetzung (welche IP blocken etc.) machst Du selbst.
# Zentrale Kennzahl ist der Cache-Status: HIT wird von nginx
# ausgeliefert (billig), alles andere (MISS/BYPASS/EXPIRED/"-")
# geht ans Backend (PHP-FPM bzw. Proxy) durch und erzeugt Last.
#
# Usage:  ./nginx-traffic-analysis.sh <site> [--no-dns]
# Bsp.:   ./nginx-traffic-analysis.sh fors.ch
#         ./nginx-traffic-analysis.sh fors.ch --no-dns   (schneller)
# ============================================================

set -u

# --- Parameter ---
SITE="${1:-}"
RESOLVE_DNS=1
TOP_N=15
HIGH_VOLUME=500   # IPs mit mehr Requests gelten als auffaellig

if [ -z "$SITE" ]; then
  echo "Fehler: Kein Site-Parameter angegeben." >&2
  echo "Usage: $0 <site> [--no-dns]" >&2
  echo "Beispiel: $0 fors.ch" >&2
  exit 1
fi

# Restliche Argumente (Flags) auswerten
shift
for arg in "$@"; do
  case "$arg" in
    --no-dns) RESOLVE_DNS=0 ;;
    *) echo "Warnung: unbekanntes Argument '$arg' ignoriert." >&2 ;;
  esac
done

LOGFILE="/home/sites/${SITE}/pub/log/nginx-access.log"

# --- Logfile pruefen ---
if [ ! -f "$LOGFILE" ]; then
  echo "Fehler: Logfile nicht gefunden: $LOGFILE" >&2
  echo "Hinweis: Fuer diese Site ist kein access_log vorhanden." >&2
  exit 1
fi

if [ ! -s "$LOGFILE" ]; then
  echo "Fehler: Logfile ist leer: $LOGFILE" >&2
  exit 1
fi

# --- Hilfsfunktionen ---
separator() {
  echo "------------------------------------------------------------"
}

header() {
  echo ""
  echo "============================================================"
  echo "  NGINX Traffic Analysis: $SITE"
  echo "  Generiert: $(date '+%d.%m.%Y %H:%M:%S')"
  echo "  Logfile  : $LOGFILE"
  echo "============================================================"
}

# --- Zeitrahmen ---
# Im cache_log-Format ist Feld 4 == [TT/Mon/JJJJ:HH:MM:SS
get_timeframe() {
  local first last lines
  first=$(awk 'NF>=4 {print substr($4,2); exit}' "$LOGFILE")
  last=$(awk 'NF>=4 {x=substr($4,2)} END {print x}' "$LOGFILE")
  lines=$(wc -l < "$LOGFILE")
  echo ""
  separator
  echo "  ZEITRAHMEN"
  separator
  echo "  Start : $first"
  echo "  Ende  : $last"
  echo "  Total : $lines Requests"
}

# --- Cache-Uebersicht ---
# Feld 3 == $upstream_cache_status. Zeigt auf einen Blick,
# wieviel Traffic aus dem Cache kommt vs. ans Backend durchschlaegt.
get_cache_overview() {
  echo ""
  separator
  echo "  CACHE-UEBERSICHT (Feld \$upstream_cache_status)"
  separator
  printf "  %-8s %-7s %s\n" "COUNT" "ANTEIL" "STATUS"
  separator
  awk '
    { c[$3]++; t++ }
    END {
      for (s in c) printf "  %-8d %5.1f%%  %s\n", c[s], c[s]/t*100, s
    }' "$LOGFILE" | sort -rn

  echo ""
  awk '
    { t++; if ($3 != "HIT") be++ }
    END {
      printf "  => Backend-Last (kein HIT): %d von %d Requests (%.1f%%)\n", \
             be, t, (t ? be/t*100 : 0)
    }' "$LOGFILE"
  echo "     Hinweis: \"-\" = keine Cache-Direktive aktiv => geht immer ans Backend."
}

# --- Top IPs (nach Backend-Last) ---
# Sortiert nach Requests, die NICHT aus dem Cache kamen, denn die
# erzeugen die Serverlast. Total-Spalte als Kontext daneben.
get_top_ips() {
  echo ""
  separator
  echo "  TOP ${TOP_N} IPs (sortiert nach Backend-Last)"
  separator
  printf "  %-8s %-8s %-7s %-18s %s\n" \
         "BACKEND" "TOTAL" "BE%" "IP" "HOSTNAME"
  separator
  awk '
    { tot[$1]++; if ($3 != "HIT") be[$1]++ }
    END {
      for (ip in tot) printf "%d %d %s\n", be[ip]+0, tot[ip], ip
    }' "$LOGFILE" \
    | sort -rn \
    | head -"$TOP_N" \
    | while read -r becount total ip; do
        local pct host
        pct=$(awk "BEGIN{printf \"%.0f%%\", ($total ? $becount/$total*100 : 0)}")
        host="-"
        if [ "$RESOLVE_DNS" -eq 1 ]; then
          host=$(timeout 1 dig +short -x "$ip" 2>/dev/null | sed 's/\.$//' | head -1)
          [ -z "$host" ] && host="-"
        fi
        printf "  %-8s %-8s %-7s %-18s %s\n" \
               "$becount" "$total" "$pct" "$ip" "$host"
      done
}

# --- Top URLs (nach Backend-Last) ---
# Zeigt welche Pfade am Cache vorbei ans Backend gehen (uncacheable Hotpaths).
# Request steckt in Feld 6-8: "GET /pfad HTTP/1.1" -> Pfad == Feld 7.
get_top_urls() {
  echo ""
  separator
  echo "  TOP ${TOP_N} URLs (Requests ans Backend, ohne Query-String)"
  separator
  printf "  %-8s %s\n" "COUNT" "URL"
  separator
  awk '
    $3 != "HIT" {
      u = $7; sub(/\?.*/, "", u);
      if (u != "") c[u]++
    }
    END {
      for (u in c) printf "%d %s\n", c[u], u
    }' "$LOGFILE" \
    | sort -rn | head -"$TOP_N" \
    | while read -r count url; do
        printf "  %-8s %s\n" "$count" "$url"
      done
}

# --- Top User-Agents ---
# UA steckt im letzten Quote-Feld: -F'"' Feld 6.
get_top_useragents() {
  echo ""
  separator
  echo "  TOP ${TOP_N} USER-AGENTS"
  separator
  awk -F'"' '{print $6}' "$LOGFILE" \
    | sort | uniq -c | sort -rn | head -"$TOP_N" \
    | while read -r count ua; do
        printf "  %-8s %s\n" "$count" "$ua"
      done
}

# --- Bots / verdaechtige Agents ---
get_bots() {
  echo ""
  separator
  echo "  HIGH-VOLUME BOTS / VERDAECHTIGE AGENTS"
  separator

  local bot_patterns
  bot_patterns="bot|crawl|spider|scan|python-requests|curl|wget|scrapy|zgrab|masscan|nikto|sqlmap|nmap|Go-http|libwww|Jakarta|Apache-HttpClient|okhttp|axios|java/"

  awk -F'"' '{print $6}' "$LOGFILE" \
    | sort | uniq -c | sort -rn \
    | grep -iE "$bot_patterns" \
    | head -"$TOP_N" \
    | while read -r count ua; do
        printf "  %-8s %s\n" "$count" "$ua"
      done

  echo ""
  echo "  IPs mit mehr als ${HIGH_VOLUME} Requests:"
  separator
  awk '{print $1}' "$LOGFILE" \
    | sort | uniq -c | sort -rn \
    | awk -v hv="$HIGH_VOLUME" '$1 > hv {printf "  %-8s %s\n", $1, $2}' \
    | head -"$TOP_N"

  echo ""
  echo "  Request-Dichte: Top IPs nach Requests/Minute"
  echo "  (gleichmaessig hohe Werte deuten auf automatisierten Traffic)"
  separator
  # Feld 1 == IP, Feld 4 == [TT/Mon/JJJJ:HH:MM (Sekunden abgeschnitten)
  awk '{ key = $1 " " substr($4, 2, 18); print key }' "$LOGFILE" \
    | sort | uniq -c | sort -rn | head -10 \
    | awk '{printf "  %-8s %-18s %s\n", $1, $2, $3}'
}

# --- Kurz-Footer (generische Gegenmassnahmen, keine Auto-Interpretation) ---
get_footer() {
  echo ""
  separator
  echo "  GEGENMASSNAHMEN (zum Kopieren ins Ticket)"
  separator
  echo "  IP blockieren (nginx):   deny <IP>;   in server {} oder http {}"
  echo "  IP blockieren (Firewall): shorewall reject <IP>   bzw. Cloudflare-Rule"
  echo "  Rate-Limiting (nginx):"
  echo "    limit_req_zone \$binary_remote_addr zone=one:10m rate=30r/m;"
  echo "  Cache pruefen: hoher \"-\"/MISS-Anteil oben => fastcgi_cache nicht aktiv?"
  separator
}

# --- Hauptprogramm ---
header
get_timeframe
get_cache_overview
get_top_ips
get_top_urls
get_top_useragents
get_bots
get_footer

echo ""
echo "  Analyse abgeschlossen."
echo "============================================================"
echo ""
