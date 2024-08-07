#!/bin/bash
#  spew static page
#  depends on tab-sep output from gather_records.sh
#  and expects to find icon files in ./ico/ including null-0.png and null-1.png
#
#  "null-0.png" : this hostname has no records
#  "null-1.png" : this hostname has records but couldnt fetch the favicon

SUFFIX="com"
ICODIR="./ico"
ICODNE="./ico/null-0.gif"  # does not exist
ICO_NA="./ico/null-1.gif"  # not available


declare -A database
slurp_database(){
  local IFS h rtype body
  IFS=$'\t'
  while read -r h rtype body; do
    database["${h}"]=1
    database["${h}|${rtype}"]=$body
  done <"$1"
}
if [ $# == 1 ] && [ -e "$1" ]; then
  slurp_database "$1"
  mtime=$(stat gathered.tsv -c %y)
  mtime=${mtime%.*}
else
  echo >&2 "Usage: $0 output-of-gather.tsv"
  exit 1
fi

cat <<'_EOD'
<!doctype html>
<head>
<meta charset="UTF-8">
<title>deuxlettre</title>
<style>
  html,body { background:#ddd; font-size:10.5pt; font-family:serif; text-align:center; }
  table { border-collapse:collapse; margin:auto; }
  h1 { text-align:center; }
  table td img { height: 16px; width: 16px; }
  table td { height: 24px; width: 24px; text-align:center; }
  #footer { text-align:center; margin:auto; padding-bottom:5em; }
  #footer ul { margin:auto; width:30em; text-align:left; }
tr.tt td div { display:inline-block; position:relative; }
  tr.tt td div span { background-color:#333; border-radius:4px; color:white; left:50%; margin-left:-10em; opacity:0; padding:2px; position:absolute; text-align:center; text-align:left; transition:opacity 0.3s; visibility:hidden; width:20em; z-index:1; }
  tr.tt-above td div span { bottom: 125%; }
  tr.tt-below td div span { top: 125%; }
  tr.tt td div:hover span { opacity:1; visibility:visible; }
</style>
</head><body>
<div id=header>
<h1>DeuxLettre</h1>
<p>What two-letter domain names are owned/ available?</p>
</div>
_EOD

echo "<table>"
echo -n "<tr class=tt><th>.${SUFFIX}</th>"
for i in {a..z}; do echo -n "<th>$i</th>"; done
echo "</tr>"

spew_td(){
  local h tooltiptext j i iconurl
  h="$1"
  if [ -z "${database["${h}."]}" ]; then
    echo -n "<td><div><img alt=\"$h\" src=\"$ICODNE\">"
    echo -n "<span><b>$h</b><ul><li>No DNS records found</li></ul></span>"
    echo "</td>"
    return
  fi
  tooltiptext="<b>$h</b>"
  if [ -n "${database["${h}.|TITLE"]}" ]; then
    tooltiptext+="<br><i>${database["${h}.|TITLE"]}</i>"
  fi
  tooltiptext+="<ul>"
  for j in SOA NS MX A AAAA CNAME; do
    if [ -n "${database["${h}.|${j}"]}" ]; then
      tooltiptext+="<li><b>${j}</b>: ${database["${h}.|${j}"]}</li>"
    fi
  done
  tooltiptext+="</ul>"
  for i in png gif jpg jpeg webp; do
    if [ -e "${ICODIR}/${h//./-}.${i}" ]; then
      iconurl="${ICODIR}/${h//./-}.${i}"
      break;
    fi
  done
  iconurl=${iconurl:-$ICO_NA}
  echo -n "<td><div>"
  if [ -n "${database["${h}.|TITLE"]}" ]; then
    echo -n "<a target=_blank href=\"http://${h}\">"
  fi
  echo -n "<img alt=\"$h\" src=\"$iconurl\">"
  if [ -n "${database["${h}.|TITLE"]}" ]; then
    echo -n "</a>"
  fi
  echo -n "<span>$tooltiptext</span></div>"
  echo "</td>"
}

for i in {a..m}; do
  echo "<tr class=\"tt tt-below\"><th>$i</th>"
  for j in {a..z}; do
    spew_td "${i}${j}.${SUFFIX}"
  done
  echo "</tr>"
done
for i in {n..z}; do
  echo "<tr class=\"tt tt-above\"><th>$i</th>"
  for j in {a..z}; do
    spew_td "${i}${j}.${SUFFIX}"
  done
  echo "</tr>"
done

echo "</table>"

cat <<_EOD
<div id=footer>
<p>Made in bash one weekend when I was sick. - Moses "Mozai" Moore -</p>
<p>Last updated: ${mtime}</p>
<p>TODO list moved to readme file.</p>
</div>
</body>
_EOD
