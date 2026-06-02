#!/usr/bin/env bash
# Generate sitemap.xml for the personal site only.
#
# Includes every .md file in the repo (outside excluded dirs), converted
# to its rendered .html URL under https://leonletto.github.io/.
#
# Previously this script also folded URLs from the Thrum sub-site into
# the same sitemap, because Search Console refused to verify the /thrum/
# URL-prefix property. As of 2026-05-16 the Thrum site moved to its own
# domain (https://thrum.team), so the fold-in is no longer needed:
# thrum.team has its own Search-Console-verified Domain property and
# publishes its own sitemap at https://thrum.team/sitemap.xml.
#
# Idempotent. Overwrites sitemap.xml on every run.

set -uo pipefail

BASE_URL="https://leonletto.github.io"
SITEMAP_FILE="sitemap.xml"

# Build directory exclusions for find. These never belong in a sitemap:
# - .git, .venv, __pycache__ — internal
# - _site, _layouts, _includes, _data — Jekyll machinery (templates, build out)
# - node_modules — JS deps if any
# - .jekyll-cache — Jekyll build cache
# - .thrum, .claude — agent coordination/config; dot-dirs Jekyll never builds,
#   so their .md files would be 404s if listed here
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
  -not -path './.thrum/*'
  -not -path './.claude/*'
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

echo '</urlset>' >> "${SITEMAP_FILE}"

# ── Report ────────────────────────────────────────────────────────────
echo "Sitemap generated at ${SITEMAP_FILE}"
echo "  Personal-site URLs: ${PERSONAL_COUNT}"
