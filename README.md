# OpenSSL for Mere Mortals

**OpenSSL** is the cryptography toolkit that
sits underneath most of the secure connections
on earth. When your browser shows a padlock,
when a server proves it is who it claims to
be, when two machines agree on a secret key in
public without ever whispering — the odds are
good that OpenSSL, or something built to its
shape, did the work. It is also the tool you
meet when something is wrong: an expired
certificate, a name that doesn't match, a chain
that doesn't reach a root. Those error
messages are OpenSSL sentences, and this guide
teaches you to read them.

OpenSSL is two things at once: a **library**
that other programs link against, and a
**command line** — one program, `openssl`,
carrying dozens of subcommands for keys,
certificates, hashes, encryption, and live TLS
testing. The library is for programmers. This
guide is about the command line, which is for
anyone who runs a server, inherits a `.pem`
file, or has ever pasted a certificate error
into a search box.

The guide builds a small world and stays in
it: a throwaway certificate authority, an
intermediate, a server certificate, and —
deliberately — an expired one, a wrong-name
one, and a self-signed one, so that every
classic failure can be produced on demand and
read in the tool's own words. Everything is
fake: the names are `example.test`, the
organisation is "Example Lab", the keys are
specimens generated for the page and worth
nothing. `examples/lab-setup.sh` rebuilds the
whole lab in one run.

A note on how this guide was verified.
OpenSSL 3.0.13 was on the build machine, and
essentially everything in these chapters was
run on it: every key, certificate, and error
message quoted is a real capture from the lab
above, produced by the exact commands shown.
The TLS chapters ran against `openssl
s_server` on the same machine, over loopback.
One `s_client` capture against a public site
(example.com) is included in chapter 8,
labelled as such. There is no documented-only
material in this guide; `criteria.md` keeps
the ledger anyway, because that is the series
habit.

## What this guide covers

- [**What OpenSSL is**](what-openssl-is.md) —
  the plumbing under TLS, the library and the
  command line, and where certificates come
  from
- [**The vocabulary**](the-vocabulary.md) —
  key pairs, certificates, CAs, CSRs, chains
  of trust, PEM and DER, fingerprints
- [**Meet OpenSSL**](meet-openssl.md) — the
  one program and its families of subcommands,
  `version`, `help`, and `list`
- [**Looking at certificates**](looking-at-certificates.md) —
  `x509` as a reading tool: subjects, issuers,
  dates, extensions, fingerprints, and the
  modulus trick
- [**Keys**](keys.md) — RSA and EC key pairs,
  reading them, locking them with a passphrase,
  and taking the public half out
- [**CSRs and self-signed certificates**](csrs-and-self-signed.md) —
  asking for a certificate, adding the names
  it must cover, and why browsers refuse to
  trust you about yourself
- [**Be your own CA**](be-your-own-ca.md) — a
  root, an intermediate, and a signed server
  certificate; `openssl ca`, and `openssl
  verify` as the judge
- [**TLS in practice**](tls-in-practice.md) —
  a server and a client on one machine, the
  handshake read line by line, and forcing
  protocol versions until it breaks
- [**Hashes, HMAC and symmetric encryption**](hashes-hmac-and-encryption.md) —
  fingerprints of files, keyed proof, `enc`
  and its honest caveats, `rand`, base64
- [**Converting and bundling**](converting-and-bundling.md) —
  PEM and DER, PKCS#12 suitcases, chain
  bundles, and PKCS#7
- [**Troubleshooting**](troubleshooting.md) —
  the five classic certificate failures, each
  reproduced in the lab, with its real message
  and its fix
- [**Glossary**](glossary.md) — the terms,
  collected in one place

## What it doesn't cover

Programming against the library (the `libssl`
and `libcrypto` APIs), building OpenSSL from
source, engines and providers beyond naming
them, the `ca` program as a production CA for
the public internet — real services use real
CAs or ACME automation such as Let's Encrypt —
and the mathematics of the algorithms. Where a
command has a safer modern replacement or a
known wart, the chapter says so in place.

## How to use this guide

Read the first two chapters away from the
keyboard. Then make a scratch directory,
run `examples/lab-setup.sh`, and work through
chapters 4 to 8 with the lab in front of you —
every command in those chapters is typed
against files the script creates. Keep the
lab. Chapter 11 breaks it five ways on
purpose, and fixing what you broke yourself
is the fastest teacher there is.
