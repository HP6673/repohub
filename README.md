# RepoHub

Live GitHub Pages directory of repositories for LJ-Web-Management and HP6673.

## Features

- Switch between the LJ-Web-Management and HP6673 accounts (repos are fetched live from the GitHub API)
- Search by name, description or topic (press `/` to focus, `Esc` to clear)
- Filter by type (sources, forks, archived) and language; sort by last updated, name or stars
- Light/dark theme toggle (defaults to your system setting, choice is remembered)

## Desktop apps

- **macOS** (`macos/`): native app with *Pinned Repos* and *Pinned Sites* desktop widgets. See [macos/README.md](macos/README.md).
- **Windows** (`desktop/`): Electron app wrapping the site. Run locally with `cd desktop && npm install && npm start`.

`.github/workflows/release.yml` builds both. Push a tag (e.g. `git tag v1.0.0 && git push origin v1.0.0`) to publish a GitHub Release; the site's download buttons point to the latest release.
