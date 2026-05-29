# GOV.UK Design System — Liferay Site Initializer (STRICT)

A Liferay **7.4.13** site initializer that recreates the
[GOV.UK Design System](https://design-system.service.gov.uk) as a reusable site
template, built with the `/ds-site-initializer-strict` shape.

It re-aligns the earlier validated implementation
(`drakonux/liferay-portal @ feature/govuk-design-system-integration`) to the
current strict layout: an OSGi module (PATH A) + a `govuk-theme` client
extension carrying a layered token architecture.

## Mechanism

- **PATH A — OSGi module** (`com.govuk.site.initializer`) with
  `Provide-Capability: liferay.site.initializer`, so it shows up in
  *Add Site → Select Template*.
- **Scenario B — theme client extension** (`govuk-theme`, `themeCSS`) holding
  the primitive → semantic token layers and the GOV.UK focus signature.

## Layout

```
.
├── build-scripts/govuk-site-initializer/   # bnd.bnd + build.gradle (manual Jar)
├── client-extensions/govuk-theme/          # themeCSS CX: src/index.css + token def
├── META-INF/resources/thumbnail.png        # Select-Template tile
├── scripts/{validate.sh,deploy.sh}
└── site-initializer/
    ├── fragments/group/govuk/              # 24 fragments (16 ported + 8 new)
    ├── style-books/govuk-default/          # GOV.UK palette (validated tokens)
    ├── layout-page-templates/master-pages/main/   # header + dropzone + footer
    ├── layout-set/public/                  # metadata.json (Classic) + css.css
    ├── layouts/{1_home,components,styles}/ # 3 reference pages
    └── thumbnail.png
```

### Fragments (24)

**Ported & validated (16):** accordion, back-link, breadcrumbs, button, details,
footer, header, inset-text, notification-banner, panel, phase-banner,
summary-list, table, tabs, tag, warning-text.

**Added (8):** hero, card, pagination, text-input, cookie-banner,
service-navigation, styles-showcase, components-showcase.

Fragments are themed by the **style book** via Classic theme CSS variables
(`--brand-color-1`, `--black`, `--success`, `--font-size-base` …); the
`govuk-theme` CX supplies base typography, the GOV.UK focus state, layout
helpers and the token definition exposed to Style Books.

## Build

```bash
# OSGi JAR (manual jar — reliable for resource-only bundles)
cat > /tmp/govuk-manifest.mf <<'EOF'
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-Name: GOV.UK Site Initializer
Bundle-SymbolicName: com.govuk.site.initializer
Bundle-Version: 1.0.0
Liferay-Site-Initializer-Name: GOV.UK
Provide-Capability: liferay.site.initializer
Web-ContextPath: /site-initializer-govuk

EOF
mkdir -p build-scripts/govuk-site-initializer/build/libs
jar cfm build-scripts/govuk-site-initializer/build/libs/com.govuk.site.initializer-1.0.0.jar \
  /tmp/govuk-manifest.mf -C . site-initializer -C . META-INF
```

The `govuk-theme.zip` under `client-extensions/govuk-theme/dist/` mirrors a
`gradlew :client-extensions:govuk-theme:assemble` output (themeCSS CX config +
`static/index.css` + plugin-package props).

## Validate (blocking)

```bash
LIFERAY_VERSION=7.4.13 bash scripts/validate.sh .   # must exit 0
```

## Deploy (SSH + docker cp)

```bash
SSH_USER=<user> SSH_PASS=<pass> bash scripts/deploy.sh --list-containers   # find container
SSH_USER=<user> SSH_PASS=<pass> CONTAINER=<name> bash scripts/deploy.sh
```

Then: **Control Panel → Sites → Add Site → Select Template → GOV.UK**. After the
site is created, apply the theme under *Site Settings → Look and Feel →
govuk-theme* — on 7.4.13 a CX theme cannot be bound through site-initializer
metadata (kept as `themeName: "Classic"`).

Verify these in the container logs:

```
STARTED com.govuk.site.initializer_1.0.0
STARTED ...govuk-theme...
```

## Lineage

This is a clean, strict re-alignment of the earlier validated implementation on
`drakonux/liferay-portal @ feature/govuk-design-system-integration`. That branch
lives inside the Liferay portal monorepo and does **not** follow this standalone
layout; this repository repackages the same validated fragments, tokens and
palette as a self-contained `/ds-site-initializer-strict` deliverable.

## Credits & licence

The GOV.UK Design System (components, patterns, styles) is © Crown copyright,
published by the Government Digital Service under the
[MIT licence](https://github.com/alphagov/govuk-design-system/blob/main/LICENCE.txt)
(code) and the
[Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
(content). This repository is an **independent** Liferay port for evaluation and
is not affiliated with or endorsed by GDS. The Liferay packaging (OSGi module,
client extension, scripts) is provided as-is.
