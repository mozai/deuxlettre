#!/bin/bash
# gather what I can about each two-letter domain-name
#  done in bash to be perverse

####################
# config

SUFFIX="com"
DNSTYPES=(A AAAA CNAME MX NS SOA)


####################
# init

die(){ echo >&2 "$*"; exit 1; }

check_requirements(){
  if command -v "host" >/dev/null 2>/dev/null; then
    dns_get2(){ host -c IN -t "$2" "$1" 2>/dev/null |sed -nr 's/^.*( handled by | server | has address | has IPv6 address | SOA record )//p'; }
  elif command -v nslookup >/dev/null 2>/dev/null; then
    dns_get2(){ nslookup "-querytype=$2" "$1" 2>/dev/null |sed -nr 's/^.*=[[:space:]]*//p'; }
  elif command -v dig >/dev/null 2>/dev/null; then
    dns_get2(){ dig -c IN -q "$1" -t "$2" +short 2>/dev/null; }
  elif command -v drill >/dev/null 2>/dev/null; then
    dns_get2(){ drill "$1" "$2" IN 2>/dev/null |sed -nr "s/.*\t$2\t//p"; }
  else
    die "I need one of dig, drill, nslookup or (BIND9) host!"
  fi
  # can't use wget because it doesn't tell me the final relocated URL
  if command -v curl >/dev/null; then
    # curl --max-time doesn't work, because some sites are tarbabies
    http_get(){ 
      { timeout 5 curl -L -s "https://$1" -w '\n<x-url-effective>%{url_effective}</x-url-effective><foobar/>\n' 2>/dev/null; } \
      || \
      { timeout 5 curl -L -s "http://$1"  -w '\n<x-url-effective>%{url_effective}</x-url-effective><foobar/>\n' 2>/dev/null; }
    }
  else
    die "I need curl!"
  fi
  if ! command -v xargs >/dev/null; then
    die "I need xargs!"
  fi
}

get_stuff(){
  # $1 = hostname
  h=$1;
  errors="";

  # DNS stuff
  for i in "${DNSTYPES[@]}"; do
    i=${i^^}
    res=$(dns_get2 "$h" "$i") || errors+=" DNS-$i fail"
    while read -r line; do
      [ -n "$line" ] && echo -e "$h\t$i\t$line" && break
    done < <(sort <<<"$res")
  done

  # HTTP/HTML stuff
  # well at least I'm not using regexps to parse HTML
  # ... not entire parts of HTML *cough*
  local body h iconurl tag title rel href found url
  h=$1
  local IFS=\>
  while read -r -d \< tag body; do
    found=1
    [[ "$tag" =~ ^/ ]] && continue
    [[ "$tag" =~ /$ ]] && continue
    [[ "${tag^^}" =~ ^SCRIPT ]] && continue
    [[ "${tag^^}" =~ ^STYLE ]] && continue
    # shellcheck disable=SC2116,2086
    tag=$(unset IFS; echo $tag |tr -d '\r' )  # cheap way to flatten whitespace
    # shellcheck disable=SC2116,2086
    body=$(unset IFS; echo $body)  # cheap way to flatten whitespace
    if [[ "${tag^^}" =~ ^TITLE ]]; then
      title=$(<<<"$body" tr -d '\r')
    elif [[ "${tag^^}" =~ ^X-URL-EFFECTIVE ]]; then
      url=$(<<<"$body" tr -d '\r')
    elif [[ "${tag^^}" =~ ^LINK ]]; then
      #eval local ${tag#* }  # I hated this, and it broke on attribs like "data-n-g="
      rel=$(sed -r '{s/.*[[:space:]]rel="([^"]*)".*/\1/;s/.*[[:space:]]rel='"'"'([^'"'"']*)'"'"'.*/\1/;s/.*[[:space:]]rel=([^[:space:]]*).*/\1/;}' <<<"$tag")
      href=$(sed -r '{s/.*[[:space:]]href="([^"]*)".*/\1/;s/.*[[:space:]]href='"'"'([^'"'"']*)'"'"'.*/\1/;s/.*[[:space:]]href=([^[:space:]]*).*/\1/;}' <<<"$tag")
      if [[ "${rel^^}" =~ ICON ]] && [[ -n "$href" ]]; then
        iconurl=$href
        iconurl=${iconurl% *}
      fi
      if [[ "$iconurl" =~ ^data: ]]; then
        if [[ "$iconurl" =~ ^data:image/svg ]]; then
          iconurl=""  # TODO: what do?
        elif [[ ! "$iconurl" =~ ^data:image ]]; then
          iconurl=""
        fi
      fi
    fi
  done < <(http_get "$h" || http_get "www.$h")
  if [ -n "$found" ]; then
    if [[ "$iconurl" =~ ^/[^/] ]]; then
      iconurl="//${h%.}$iconurl"
    fi
    [ -n "$iconurl" ] && echo -e "$h\tICON\t$iconurl"
    [ -n "$title" ] && echo -e "$h\tTITLE\t$title"
    if [ -n "$url" ]; then
      url=$(sed -r 's/\.\//\//;s/\?.*//' <<<"$url")
      echo -e "$h\tURL\t$url"
    else
      # errors+=" HTTP no x-url-effective tag"
      : pass
    fi
  fi
  [ -n "$errors" ] && echo -e "$h\tERRORS\t$errors"
}

list_targets(){
  local i j k
  k=$1
  for i in {a..z}; do
    for j in {a..z}; do
      echo "${i}${j}.${k}.";
    done
  done
}

#list_targets(){
#  # shorter list for testing
#  echo "aa.com.";  # "access denied" for curl
#  echo "wy.com.";  # misisng the URL record
#  # just some problems to fix by iteration
#  #echo "qb.com."; echo "xo.com."; echo "oj.com.";
#}

####################
# main

if [ "$1" == "-child" ]; then
  check_requirements;
  get_stuff "$2"
else
  ## shellcheck disable=SC2064
  #TMPDIR=$(mktemp -d); trap "rm -r $TMPDIR" EXIT;
  list_targets "$SUFFIX" | xargs -P0 -n1 "$SHELL" "$0" -child
fi

