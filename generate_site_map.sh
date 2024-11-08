#!/bin/bash

# Base URL for your GitHub Pages site
BASE_URL="https://leonletto.github.io"

# Output sitemap file
SITEMAP_FILE="sitemap.xml"

# Function to convert .md paths to .html
convert_md_to_html() {
  local md_path="$1"
  # Change .md extension to .html
  echo "${md_path%.md}.html"
}

# Initialize the sitemap file
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > "$SITEMAP_FILE"
echo "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">" >> "$SITEMAP_FILE"

# Find all .md files and convert to .html entries in sitemap
find . -type f -name "*.md" | while read -r md_file; do
  # Convert the path to relative URL
  relative_path=$(convert_md_to_html "${md_file#./}")

  # Add the entry to the sitemap
  echo "  <url>" >> "$SITEMAP_FILE"
  echo "    <loc>$BASE_URL/$relative_path</loc>" >> "$SITEMAP_FILE"
  echo "    <lastmod>$(date -I)</lastmod>" >> "$SITEMAP_FILE"
  echo "    <changefreq>weekly</changefreq>" >> "$SITEMAP_FILE"
  echo "    <priority>0.8</priority>" >> "$SITEMAP_FILE"
  echo "  </url>" >> "$SITEMAP_FILE"
done

# Close the sitemap file
echo "</urlset>" >> "$SITEMAP_FILE"

echo "Sitemap generated at $SITEMAP_FILE"
