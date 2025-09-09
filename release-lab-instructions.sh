#!/usr/bin/env bash
set -Eeuo pipefail

# release-lab-instructions.sh
# Skapar och pushar en annoterad tagg: lab_<version>
# GitHub Actions-workflow som lyssnar på "lab_*" bygger PDF.

REMOTE="origin"

usage() {
  cat <<'USAGE'
Usage:
  release-lab-instructions.sh -v <version> [-m "message"] [-r <remote>] [-y]

Options:
  -v  Versionssträng (t.ex. 2025-09-01 eller v1.2.3).  REQ
  -m  Taggmeddelande (annoterad tag). Om utelämnas öppnas editor.
  -r  Git remote (default: origin)
  -y  Svara "ja" på alla frågor (överskriv tagg utan att fråga)
  -h  Visa denna hjälp

Exempel:
  ./release-lab-instructions.sh -v v1.0.1
  ./release-lab-instructions.sh -v 2025-09-01 -m "HT25 lab release"
  ./release-lab-instructions.sh -v v2 -r origin -y
USAGE
}

confirm() {
  local prompt="${1:-Är du säker? (y/N) }"
  read -r -p "$prompt" ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

delete_tag_if_exists() {
  local tag="$1"
  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "Taggen $tag finns redan lokalt."
    if $ASSUME_YES || confirm "Vill du ersätta taggen $tag? (y/N) "; then
      git tag -d "$tag" || true
      if git ls-remote --tags "$REMOTE" | grep -q "refs/tags/$tag$"; then
        git push "$REMOTE" --delete "$tag" || true
      fi
    else
      echo "Avbryter."
      exit 1
    fi
  else
    # Om den inte finns lokalt, kolla endast remote
    if git ls-remote --tags "$REMOTE" | grep -q "refs/tags/$tag$"; then
      echo "Taggen $tag finns på remote."
      if $ASSUME_YES || confirm "Vill du ersätta taggen $tag på remote? (y/N) "; then
        git push "$REMOTE" --delete "$tag" || true
      else
        echo "Avbryter."
        exit 1
      fi
    fi
  fi
}

VERSION=""
MESSAGE=""
ASSUME_YES=false

while getopts ":v:m:r:yh" opt; do
  case "$opt" in
    v) VERSION="$OPTARG" ;;
    m) MESSAGE="$OPTARG" ;;
    r) REMOTE="$OPTARG" ;;
    y) ASSUME_YES=true ;;
    h) usage; exit 0 ;;
    \?) echo "Okänd flagga: -$OPTARG"; usage; exit 1 ;;
    :) echo "Flagga -$OPTARG kräver ett värde."; usage; exit 1 ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(date +%Y-%m-%d)"
  echo "Ingen version angiven. Använder dagens datum som version: $VERSION"
fi

TAG="lab_${VERSION}"

# Hämta taggar
git fetch --tags "$REMOTE" >/dev/null 2>&1 || true

echo "Sammanfattning:"
echo "  Version: $VERSION"
echo "  Tagg:    $TAG"
echo "  Remote:  $REMOTE"
$ASSUME_YES || confirm "Skapa och pusha taggen nu? (y/N) " || { echo "Avbrutet."; exit 1; }

# Ta bort befintlig tagg (lokalt/remote) vid behov
delete_tag_if_exists "$TAG"

# Om inget -m: öppna editor för att skriva ett meddelande
if [[ -z "$MESSAGE" ]]; then
  tmpfile="$(mktemp)"
  {
    echo "Lab instructions $VERSION"
    echo
    echo "(Skriv ditt meddelande ovan. Ta inte bort sista raden.)"
    echo "---"
  } > "$tmpfile"
  "${GIT_EDITOR:-${VISUAL:-vi}}" "$tmpfile"
  MESSAGE="$(sed '/^---$/,$d' "$tmpfile" | sed -e '${/^$/d}')"
  rm -f "$tmpfile"
  [[ -z "$MESSAGE" ]] && MESSAGE="Lab instructions $VERSION"
fi

# Skapa annoterad tagg
git tag -a "$TAG" -m "$MESSAGE"

# Pusha
git push "$REMOTE" "$TAG"

echo "Klart! Taggen $TAG skapades och pushades till $REMOTE."
