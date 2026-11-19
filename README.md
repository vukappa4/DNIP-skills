# research-skills

Prompt templates for AI chat sites, expanded by [Espanso](https://espanso.org).

Each `*.yml` file at the repo root is one Espanso match file. Type its trigger in any chat box, for example `:analysis`.

## Skills

- `company-profile.yml` - `:analysis`: company overview, products and services, business model.

## Install on a Mac

Paste in Terminal:

```
/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/vukappa4/research-skills/main/install-mac.sh)"
```

It installs Espanso and a background job that downloads the skills from `main` every 10 minutes. Then allow Espanso in System Settings > Privacy & Security > Accessibility.

## Update a skill

Edit the `.yml`, commit, push to `main`. Macs pick it up within about 15 minutes. Espanso reloads by itself.

A file must start its matches with a `matches:` line, or the updater skips it.
