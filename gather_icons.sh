#!/bin/bash
# gets the website icons discovered by gather_records.sh
#   expects a tab-sep file of the form "hostname.\tICON\thttp:some/url"


####################
# config

# where to dump collected icons
OUTDIR="./ico"

####################
# init

die(){ echo >&2 "$*"; exit 1; }

check_requirements(){
  if command -v wget >/dev/null 2>/dev/null; then
    # wget --timeout doesn't work, because some http sites are tarbabies
    http_get(){ local u=$1; u=${u#*//}; timeout 5 wget -qO- "https://$u" 2>/dev/null || timeout 5 wget -qO- "http://$u" 2>/dev/null; }
  elif command -v curl >/dev/null; then
    # curl --max-time doesn't work, because some sites are tarbabies
    http_get(){ local u=$1; u=${u#*//}; timeout 5 curl -L -s "https://$u" 2>/dev/null || timeout 5 curl -L -s "http://$u" 2>/dev/null; }
  else
    die "I need one of wget or curl!"
  fi
  if ! command -v xargs >/dev/null; then
    die "I need xargs!"
  fi
  if ! command -v convert >/dev/null; then
    die "I need Imagemagick's convert!"
  fi
  if ! command -v file >/dev/null; then
    die "I need the 'file' magic commant!"
  fi
}

get_icon_urls() {
  local infile iconurls line h rtype body
  infile=$1  # expecting a tab-separated list
  declare -A iconurls
  while read -r line; do
    IFS=$'\t' read -r h rtype body <<<"$line"
    if [ "$rtype" == "TITLE" ]; then
      if [ -z "${iconurls[$h]}" ]; then
        iconurls[$h]="https://${h%.}/favicon.ico"
      fi
    elif [ "$rtype" == "ICON" ]; then
      iconurls[$h]=$body
    fi
  done <"$infile"
  for i in "${!iconurls[@]}"; do
    echo "$i:${iconurls[$i]}"
  done
}

get_icon() {
  # input is "mozai.com.:https://mozai.com/favicon.ico"
  local h u outfile cache mimetype
  IFS=: read -r h u <<<"$1"
  h=${h%.}
  outfile="${OUTDIR}/${h//\./-}.png"
  # TODO: I want not to write to disk, but how else do I prevent 0-byte
  #   strings piped into Imagemagick convert?
  cache=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm $cache" EXIT
  if [[ "$u" =~ ^data: ]]; then
    if [[ "$u" =~ ^data:image/ ]]; then
      return;  # not an image; some fools post entire plaintext stylesheets
    fi
    u=${u##;base64,}
    u=${cache% *}
    base64 -d <<<"$u" >"$cache"
  else
    http_get "$u" >"$cache"
  fi
  mimetype=$(file -b --mime-type "$cache")
  if [[ ! "$mimetype" =~ ^image ]]; then
    return 1
  fi
  prefix=""
  suffix=""
  if [ "$mimetype" == "image/vnd.microsoft.icon" ]; then
    prefix="ico:"
    suffix="[0]"
  elif [ "$mimetype" == "image/gif" ]; then
    prefix="gif:"
    suffix="[0]"
  fi
  convert "${prefix}${cache}${suffix}" -scale '32x32!' "${outfile}"
}


####################
# main
if [ "$1" == "-child" ]; then
  check_requirements;
  get_icon "$2"
else
  if [ -n "$1" ] && [ -s "$1" ]; then
    get_icon_urls "$1" |xargs -n1 -P0 "$SHELL" "$0" -child
  else
    echo >&2 "Usage: $0 file-created-by-gather_urls-sh"
    echo >&2 "  dumps many many webp files into ${OUTDIR}"
    exit 1;
  fi
fi
