# Meet OpenSSL

One program, many trades. Running `openssl`
with no argument drops you at an interactive
prompt almost nobody uses; in practice you
always name the trade first — `openssl x509`,
`openssl req`, `openssl s_client`. The first
word after `openssl` is a **subcommand**, and
each subcommand has its own options, its own
help, and its own chapter in the manual.

What you've got, first:

```
$ openssl version
OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)
```

The version matters more with OpenSSL than
with most tools. The 3.x line (current since
2021) reorganised the internals into
**providers** — pluggable sources of
algorithms — and deprecated some old commands
this guide avoids. The 1.1.1 line is still
common on older systems: nearly everything
here works there too, but a few outputs differ
in wording, and `openssl list` doesn't exist
in the same form. When output in this guide
differs from yours, check `openssl version`
before doubting the chapter.

`openssl version -a` adds the build details,
including `OPENSSLDIR: "/usr/lib/ssl"` — the
directory holding the factory configuration,
`openssl.cnf`. That file sets defaults for
commands that read it (`req`, `ca`); several
chapters pass `-config` to use the lab's own
instead, which is the polite way to run
experiments without touching the system's.

## The map of subcommands

`openssl help` prints the families, several
dozen strong. These are the ones this guide
uses, grouped by the job they do:

| Job | Subcommands |
|-----|-------------|
| Keys | `genpkey`, `pkey`, `rsa`, `ec` |
| Requests and certificates | `req`, `x509`, `ca`, `verify` |
| Reading | `asn1parse`, `crl`, `pkcs7`, `pkcs12` |
| Hashes and encryption | `dgst`, `mac`, `enc`, `rand`, `base64` |
| Live TLS | `s_server`, `s_client` |
| Formats | `pkcs12`, `pkcs7`, `crl2pkcs7` |
| Meta | `version`, `help`, `list`, `ciphers`, `errstr` |

Reading a line of that table you'll also see
ghosts: `genrsa`, `rsautl`, `dhparam`, and
friends are the pre-3.0 one-purpose tools,
kept for compatibility. The modern habit —
taught here — is `genpkey` for making any key
and `pkey` for reading any key, with `rsa` and
`ec` kept for the jobs only they do (the
modulus check in chapter 4 is one).

Every subcommand takes `-help`:

```
$ openssl x509 -help 2>&1 | head -5
Usage: x509 [options]

General options:
 -help                 Display this summary
```

and the manual pages follow the same naming:
`man openssl-x509`, or `man x509` on most
systems. Options are long and hyphenated
(`-noout`, `-subject`), order rarely matters,
and input defaults are PEM unless
`-inform DER` says otherwise.

## `openssl list`: asking the program what it knows

Because algorithms now come from providers,
3.x can enumerate them. The captures below are
the build machine's:

```
$ openssl list -providers
Providers:
  default
    name: OpenSSL Default Provider
    version: 3.0.13
    status: active
```

```
$ openssl list -digest-algorithms | head -5
Legacy:
  RSA-MD4 => MD4
  RSA-MD5 => MD5
  RSA-RIPEMD160 => RIPEMD160
  RSA-SHA1 => SHA1
```

`openssl list -commands` prints the standard
subcommand roster; `openssl list
-public-key-algorithms`, `-cipher-algorithms`,
and `-tls1_3` variants answer their narrower
questions. The provider line is worth knowing
about for one practical reason: in FIPS
environments a second provider appears and
some algorithms vanish from these lists, and
"the algorithm is not available" errors stop
being mysterious once you've seen the list.

## The error voice

OpenSSL errors come in a set dialect you will
meet throughout the guide:

```
40E771A1C87F0000:error:1608010C:STORE routines:ossl_store_handle_load_result:unsupported:...
```

Hex address, error code, then a path of
library:routine:function names, then (usually,
further down) a human sentence. The habit to
build: **read the last line first** — the
human sentence and any `Verify return code`
live there; the stack above it is for
developers. `openssl errstr 1608010C` decodes
a bare code when that's all a log kept.

Check: on your machine, `openssl version`
names your version; `openssl help` lists
subcommands including `s_client`, `x509`, and
`verify`; and `openssl list -providers`
shows at least the default provider, active.
If all three answer, your OpenSSL is whole,
and the rest is practice.
