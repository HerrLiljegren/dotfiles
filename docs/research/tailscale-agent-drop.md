# Tailnet-only agent artifact drop

Date: 2026-08-10

## Recommendation

Use `dufs` bound to loopback, with Tailscale Serve as the tailnet-only HTTPS
front door. Let local agents write directly into dated, named subdirectories and
return the resulting HTTPS URL. This is small enough to vibe together as
configuration; a custom application is not justified.

```text
agent-drop/
  2026-08-10-avatar-refresh/
    index.html
    avatar.png
    notes.md
```

```text
agents -> /srv/agent-drop -> dufs on 127.0.0.1 -> Tailscale Serve -> browser
```

`dufs --render-try-index` provides the useful hybrid: an artifact directory with
`index.html` opens as a site, while an ordinary directory remains a navigable
file list. It is a single binary with directory browsing, search, optional
editing and uploads, WebDAV, and a curl-friendly API. It can remain read-only
because local agents write through the filesystem.
[dufs repository](https://github.com/sigoden/dufs)
[dufs releases](https://github.com/sigoden/dufs/releases)

Tailscale Serve reverse-proxies the loopback service, provisions HTTPS, and
limits it to the tailnet. A background Serve configuration resumes after
Tailscale or the device restarts. Tailnet access-control rules still apply. The
node's MagicDNS hostname plus the immutable artifact path supplies stable links
without a public endpoint.
[Serve command](https://tailscale.com/docs/reference/tailscale-cli/serve)
[Serve examples](https://tailscale.com/docs/reference/examples/serve)

Use immutable directory names such as `<date>-<short-slug>` so links remain
stable. Agents should write files directly to the directory rather than upload
over HTTP. Keep cleanup separate and transparent: initially delete old artifact
directories manually; add an age-based timer only after the desired retention
period is clear.

Direct Tailscale Serve directory hosting is the zero-dependency prototype. It
already provides a simple listing and static-site hosting, but not the hybrid
try-index behavior, search, upload UI, or richer navigation. It is viable if
even the dufs process feels unnecessary.

## Options compared

| Option | Browse and preview | Agent deposit | Static sites and stable links | Access boundary | Cleanup and operations | Fit |
| --- | --- | --- | --- | --- | --- | --- |
| Tailscale Serve directory | Simple directory links; files use normal browser rendering; no gallery or search | Direct filesystem writes | Serves `index.html` sites; stable node hostname plus path | Tailnet-only HTTPS, constrained by tailnet policy | No built-in retention; no extra service | Best zero-dependency prototype |
| Taildrop | No persistent browser or index | `tailscale file cp` transfers to another device | No URL or static-site hosting | Own devices only; both endpoints need Tailscale; Taildrop transfers are permitted even when device ACLs restrict access | Receiver must retrieve the inbox; on Linux this currently involves root | Wrong abstraction |
| dufs behind Serve | Good file list, search, edit, archive download; no documented thumbnail gallery | Filesystem, browser upload, WebDAV, or `curl -T` | Dedicated index, try-index, and SPA modes | Bind to loopback; Serve supplies the tailnet boundary; optional dufs path/account ACLs | Single binary; deletion can be disabled or enabled explicitly | **Best overall** |
| miniserve behind Serve | Polished list, filename filtering, README rendering; no documented thumbnail gallery | Filesystem, multipart upload, paste, and optional mkdir | Custom index, SPA, and pretty-URL modes | Bind to loopback; optional username/password | Single binary and secure defaults; deletion is opt-in | Good, but dufs has a cleaner agent upload/API surface |
| copyparty behind Serve | Richest experience: grid thumbnails, image/media viewers, Markdown, navigation tree, search, recent uploads | Filesystem, browser, WebDAV, SFTP, and several upload protocols | Supports `index.html`-style web serving through its `h` permission | Bind to loopback; detailed accounts and volume permissions | Python-only core, but thumbnailing/indexing add optional dependencies and `.hist` state; supports upload self-destruction | Excellent media gallery, excessive for the first version |

Tailscale describes Taildrop as an alpha, peer-to-peer transfer feature for a
user's own devices, not shared storage. On Linux, received files are placed in
the Tailscale inbox and currently retrieved by root. It also deliberately works
between a user's devices despite access-control restrictions. Those properties
are useful for sending a file to a phone but do not provide a browsable dumping
ground or a link an agent can return.
[Taildrop documentation](https://tailscale.com/docs/features/taildrop)

`miniserve` is current and pleasantly small. Its official feature set includes
a single dependency-free binary, search/filtering, file upload, directory
creation, README rendering, WebDAV, and optional authentication. Its upload API
uses multipart forms, while dufs documents direct PUT uploads and JSON/simple
directory listings, making dufs slightly easier to automate.
[miniserve repository](https://github.com/svenstaro/miniserve)
[miniserve releases](https://github.com/svenstaro/miniserve/releases)

`copyparty` is also actively released and is the clear choice if visual media
browsing becomes the product: its UI includes grid thumbnails, a navigation
pane, Markdown and text viewers, search, uploads, and recent-upload handling.
That richness brings considerably more configuration and content-processing
surface. Its own security guidance recommends disabling HTML/Markdown rendering
or thumbnail processors for untrusted uploads. Locally produced agent artifacts
are a narrower trust boundary, but it is still more machinery than this use case
currently demonstrates.
[copyparty repository](https://github.com/9001/copyparty)
[copyparty releases](https://github.com/9001/copyparty/releases)

The original `filebrowser/filebrowser` is not a candidate: its repository says
the project is being archived and will receive no further releases, bug fixes,
or security fixes. FileBrowser Quantum is an active fork with strong previews,
search, and authentication, but its current documentation still describes the
new major version as beta and a stable release as forthcoming. It is too large
and unsettled for this small local service.
[File Browser archival notice](https://github.com/filebrowser/filebrowser)
[FileBrowser Quantum](https://github.com/gtsteffaniak/filebrowser)

## Suggested first experiment

Use dufs behind Serve for one week with only three conventions:

1. One dedicated artifact root, never a project or home directory.
2. One immutable `<date>-<slug>` directory per delivery.
3. Each agent returns the direct artifact URL and the containing directory URL.

That experiment will reveal whether the actual missing feature is thumbnails,
phone uploads, retention, or a curated landing page. Switch to copyparty for a
media-first gallery only if thumbnails become important. A custom dashboard can
then be justified by a specific gap instead of recreating a file server
speculatively.
