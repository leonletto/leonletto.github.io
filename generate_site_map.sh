#!/usr/bin/env bash
# Generate sitemap.xml containing:
#   - Pages from this Jekyll site (every .md outside excluded dirs becomes
#     a .html URL under https://leonletto.github.io/)
#   - URLs from the Thrum site, read from either:
#       $THRUM_SITEMAP_LOCAL_PATH (if set and the file exists)
#       OR fetched live from https://leonletto.github.io/thrum/sitemap.xml
#
# Why merged: Google rejects submission of the Thrum-specific sitemap or
# the /thrum/ sub-property. A single sitemap at the site root covers
# every URL under the leonletto.github.io hostname (which is allowed —
# sitemaps are scoped to hostname, not path), and the parent property is
# the only one that needs to be active in Search Console.
#
# Idempotent. Overwrites sitemap.xml on every run.

set -uo pipefail

BASE_URL="https://leonletto.github.io"
SITEMAP_FILE="sitemap.xml"
THRUM_SITEMAP_URL="${BASE_URL}/thrum/sitemap.xml"
THRUM_SOURCE_DESC=""

# Build directory exclusions for find. These never belong in a sitemap:
# - .git, .venv, __pycache__ — internal
# - _site, _layouts, _includes, _data — Jekyll machinery (templates, build out)
# - node_modules — JS deps if any
# - .jekyll-cache — Jekyll build cache
FIND_EXCLUDES=(
  -not -path './.git/*'
  -not -path './.venv/*'
  -not -path './__pycache__/*'
  -not -path './_site/*'
  -not -path './_layouts/*'
  -not -path './_includes/*'
  -not -path './_data/*'
  -not -path './node_modules/*'
  -not -path './.jekyll-cache/*'
  -not -path './.idea/*'
  -not -name 'README.md'
)

convert_md_to_html() {
  # /index.md → /  (Jekyll renders index.md as the root)
  # Everything else: .md → .html
  local md_path="$1"
  if [[ "${md_path}" == "index.md" ]]; then
    echo ""
  else
    echo "${md_path%.md}.html"
  fi
}

# Per-section priority. Home gets 1.0, blog posts 0.7, everything else 0.5.
priority_for_path() {
  local rel="$1"
  if [[ -z "${rel}" ]]; then
    echo "1.0"
  elif [[ "${rel}" == Blog/* ]]; then
    echo "0.7"
  else
    echo "0.5"
  fi
}

# ── Begin writing sitemap ─────────────────────────────────────────────
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
} > "${SITEMAP_FILE}"

# ── Personal-site pages ───────────────────────────────────────────────
TODAY=$(date -u +%Y-%m-%d)
PERSONAL_COUNT=0
while IFS= read -r md_file; do
  rel_md="${md_file#./}"
  rel_html=$(convert_md_to_html "${rel_md}")
  priority=$(priority_for_path "${rel_html}")
  {
    echo "  <url>"
    echo "    <loc>${BASE_URL}/${rel_html}</loc>"
    echo "    <lastmod>${TODAY}</lastmod>"
    echo "    <changefreq>weekly</changefreq>"
    echo "    <priority>${priority}</priority>"
    echo "  </url>"
  } >> "${SITEMAP_FILE}"
  PERSONAL_COUNT=$((PERSONAL_COUNT + 1))
done < <(find . -type f -name '*.md' "${FIND_EXCLUDES[@]}" | sort)

# ── Thrum site URLs ───────────────────────────────────────────────────
THRUM_XML=""
if [[ -n "${THRUM_SITEMAP_LOCAL_PATH:-}" && -f "${THRUM_SITEMAP_LOCAL_PATH}" ]]; then
  THRUM_XML=$(cat "${THRUM_SITEMAP_LOCAL_PATH}")
  THRUM_SOURCE_DESC="local: ${THRUM_SITEMAP_LOCAL_PATH}"
elif command -v curl >/dev/null && curl -sf -m 10 "${THRUM_SITEMAP_URL}" -o "/tmp/thrum-sitemap-$$.xml"; then
  THRUM_XML=$(cat "/tmp/thrum-sitemap-$$.xml")
  rm -f "/tmp/thrum-sitemap-$$.xml"
  THRUM_SOURCE_DESC="live: ${THRUM_SITEMAP_URL}"
else
  echo "WARNING: Could not source Thrum sitemap; output will not include Thrum URLs." >&2
fi

THRUM_COUNT=0
if [[ -n "${THRUM_XML}" ]]; then
  # Extract every <url>...</url> block and append to our sitemap.
  # The Thrum sitemap formats one tag per line so AWK range matching works.
  THRUM_BLOCKS=$(echo "${THRUM_XML}" | awk '/<url>/,/<\/url>/')
  echo "${THRUM_BLOCKS}" >> "${SITEMAP_FILE}"
  THRUM_COUNT=$(echo "${THRUM_BLOCKS}" | grep -c '<url>' || true)
fi

echo '</urlset>' >> "${SITEMAP_FILE}"

# ── Report ────────────────────────────────────────────────────────────
echo "Sitemap generated at ${SITEMAP_FILE}"
echo "  Personal-site URLs: ${PERSONAL_COUNT}"
if [[ -n "${THRUM_SOURCE_DESC}" ]]; then
  echo "  Thrum URLs:         ${THRUM_COUNT} (source: ${THRUM_SOURCE_DESC})"
else
  echo "  Thrum URLs:         0 (sitemap source unavailable — Thrum URLs missing)"
fi
echo "  Total URLs:         $((PERSONAL_COUNT + THRUM_COUNT))"
