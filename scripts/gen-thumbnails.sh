#!/usr/bin/env bash
# Render each (new) fragment with headless Chrome and screenshot it to a
# distinct 560x400 thumbnail.png that reflects how the fragment looks.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
THEME="$ROOT/client-extensions/govuk-theme/src/index.css"
FRAGS="$ROOT/site-initializer/fragments/group/govuk/fragments"
WORK="$(mktemp -d)"

# Fragments to (re)generate — the ones we authored (the 16 ported keep theirs).
NEW="govuk-hero govuk-card govuk-pagination govuk-text-input govuk-cookie-banner govuk-styles-showcase govuk-components-showcase govuk-service-navigation"

# Pad the fragment unless it carries its own full-bleed background.
fullbleed() { case "$1" in govuk-hero|govuk-cookie-banner|govuk-service-navigation) return 0;; *) return 1;; esac }

for f in $NEW; do
	dir="$FRAGS/$f"
	[ -f "$dir/index.html" ] || { echo "skip $f (no html)"; continue; }

	# Resolve FreeMarker to a representative default state for the preview.
	html=$(perl -0pe '
		s/\[#assign[^\]]*\]//g;
		s/\[#if[^\]]*\]//g;
		s/\[\/#if\]//g;
		s/\[#list[^\]]*\]//g;
		s/\[\/#list\]//g;
		s/\$\{configuration\.width\}/govuk-input--width-20/g;
		s/\$\{fragmentEntryLinkNamespace\}/preview/g;
		s/\$\{[^}]*\}//g;
	' "$dir/index.html")

	pad="24px"
	wrapstyle="padding:$pad;"
	fullbleed "$f" && wrapstyle="padding:0;"

	cat > "$WORK/$f.html" <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<style>
$(cat "$THEME")
$(cat "$dir/index.css")
html,body{margin:0;background:#ffffff;}
#main-content{font-family:var(--govuk-font-family);}
.thumb-wrap{box-sizing:border-box;$wrapstyle}
</style></head>
<body><div id="main-content"><div class="thumb-wrap">
$html
</div></div></body></html>
HTML

	"$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
		--force-device-scale-factor=2 --window-size=560,400 \
		--default-background-color=FFFFFFFF --virtual-time-budget=1500 \
		--screenshot="$WORK/$f-raw.png" "file://$WORK/$f.html" >/dev/null 2>&1

	# Downscale the 2x capture (1120x800) to the 560x400 thumbnail size.
	sips -z 400 560 "$WORK/$f-raw.png" --out "$dir/thumbnail.png" >/dev/null
	echo "rendered $f -> $(sips -g pixelWidth -g pixelHeight "$dir/thumbnail.png" | grep -oE 'pixel(Width|Height): [0-9]+' | tr '\n' ' ')"
done

echo "done. work dir: $WORK"
