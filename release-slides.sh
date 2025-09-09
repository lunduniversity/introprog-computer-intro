#!/usr/bin/env bash
set -Eeuo pipefail

# release-slides.sh
# Skapar och pushar en eller flera taggar på formen: slides_<subject>_<version>
# Dessa ska matcha ditt GitHub Actions-workflow som lyssnar på "slides_*_*".

# ---- Konfiguration ----
ALLOWED_SUBJECTS=("intro" "git" "latex" "unix" "machine-code")
REMOTE="origin"

# ---- Hjälpfunktioner ----
usage() {
  cat <<'USAGE'
Usage:
  release-slides.sh -v <version> -s <subject[,subject2,...]|all> [-m "message"] [-y]

Options:
  -v  Versionssträng (t.ex. 2025-09-01 eller v1.2.3).  REQ
  -s  Ämnen att släppa: intro, git, latex, unix, machine-code eller "all".  REQ
      Kan vara kommaseparerad lista eller flera -s-flaggor.
  -m  Gemensamt taggmeddelande. Om utelämnas öppnas editor för att skriva ett.
  -y  Svara "ja" på alla frågor (överskriv taggar utan att fråga).

Exempel:
  ./release-slides.sh -v 2025-09-01 -s intro
  ./release-slides.sh -v v1.0.0 -s intro,git,latex
  ./release-slides.sh -v v2 -s all -m "HT25 handout release"
USAGE
}

contains() {
  local needle="$1"; shift
  for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
  return 1
}

ensure_allowed_subject() {
  local s="$1"
  if ! contains "$s" "${ALLOWED_SUBJECTS[@]}"; then
    echo "Fel: Ogiltigt ämne: '$s'"
    echo "Tillåtna: ${ALLOWED_SUBJECTS[*]}"
    exit 1
  fi
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
      # Ta även bort på remote om den finns
      if git ls-remote --tags "$REMOTE" | grep -q "refs/tags/$tag$"; then
        git push "$REMOTE" --delete "$tag" || true
      fi
    else
      echo "Hoppar över $tag."
      return 1
    fi
  fi
  return 0
}

# ---- Argumentparsing ----
VERSION=""
declare -a SUBJECTS_RAW=()
MESSAGE=""
ASSUME_YES=false

while getopts ":v:s:m:yh" opt; do
  case "$opt" in
    v) VERSION="$OPTARG" ;;
    s) SUBJECTS_RAW+=("$OPTARG") ;;
    m) MESSAGE="$OPTARG" ;;
    y) ASSUME_YES=true ;;
    h) usage; exit 0 ;;
    \?) echo "Okänd flagga: -$OPTARG"; usage; exit 1 ;;
    :) echo "Flagga -$OPTARG kräver ett värde."; usage; exit 1 ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(date +%Y-%m-%d)"
  echo "Notis: Ingen version angavs, använder dagens datum: $VERSION"
fi

[[ ${#SUBJECTS_RAW[@]} -eq 0 ]] && echo "Fel: minst en -s <subject> krävs." && usage && exit 1

# Expandera subjects (komma-listor + flera -s)
declare -a SUBJECTS=()
for item in "${SUBJECTS_RAW[@]}"; do
  if [[ "$item" == "all" ]]; then
    SUBJECTS=("${ALLOWED_SUBJECTS[@]}")
    break
  fi
  IFS=',' read -r -a tmp <<< "$item"
  SUBJECTS+=("${tmp[@]}")
done

# Deduplikera SUBJECTS
declare -A seen
declare -a SUBJECTS_UNIQ=()
for s in "${SUBJECTS[@]}"; do
  [[ -n "${seen[$s]:-}" ]] && continue
  SUBJECTS_UNIQ+=("$s")
  seen["$s"]=1
done
SUBJECTS=("${SUBJECTS_UNIQ[@]}")

# Validera subjects
for s in "${SUBJECTS[@]}"; do
  ensure_allowed_subject "$s"
done

# Hämta senaste taggar från remote
git fetch --tags "$REMOTE" >/dev/null 2>&1 || true

# Om inget -m angavs: öppna editor EN gång för ett gemensamt meddelande
if [[ -z "$MESSAGE" ]]; then
  tmpfile="$(mktemp)"
  {
    echo "Slides release $VERSION"
    echo
    echo "Ämnen: ${SUBJECTS[*]}"
    echo
    echo "(Skriv ditt meddelande ovan. Ta inte bort sista raden.)"
    echo "---"
  } > "$tmpfile"
  "${GIT_EDITOR:-${VISUAL:-vi}}" "$tmpfile"
  MESSAGE="$(sed '/^---$/,$d' "$tmpfile" | sed -e '${/^$/d}')"
  rm -f "$tmpfile"

  if [[ -z "$MESSAGE" ]]; then
    # Om användaren tömde meddelandet, fall tillbaka per-tag-standard
    MESSAGE=""
  fi
fi

echo "Version:  $VERSION"
echo "Ämnen:    ${SUBJECTS[*]}"
echo "Remote:    $REMOTE"
$ASSUME_YES || confirm "Skapa och pusha taggar nu? (y/N) " || { echo "Avbrutet."; exit 1; }

# ---- Skapa & pusha taggar ----
overall_ok=true
for s in "${SUBJECTS[@]}"; do
  tag="slides_${s}_${VERSION}"

  # Rensa ev. befintlig tag
  if ! delete_tag_if_exists "$tag"; then
    overall_ok=false
    continue
  fi

  # Välj meddelande
  msg="$MESSAGE"
  [[ -z "$msg" ]] && msg="Slides $s $VERSION"

  # Skapa annoterad tagg
  git tag -a "$tag" -m "$msg"
  # Pusha tagg
  git push "$REMOTE" "$tag"
  echo "Skapade och pushade: $tag"
done

if $overall_ok; then
  echo "Klart: alla begärda taggar skapades och pushades."
else
  echo "Färdigt: vissa taggar hoppades över eller misslyckades (se loggen ovan)."
fi
