# Converting and Bundling

Certificates travel between toolchains that
disagree about formats. This chapter is the
passport office: same objects, different
paper. Everything here is a lossless
re-wrapping — the cryptography inside never
changes, and the fingerprint proves it.

## PEM and DER

Chapter 2's two forms: **PEM**, base64 text
between `-----BEGIN-----` lines, is OpenSSL's
home format; **DER**, the raw binary, is what
much Windows and Java tooling expects. The
`-outform` / `-inform` flags do the moving,
for certificates and keys alike:

```
$ openssl x509 -in server.cert.pem -out server.cert.der -outform DER
$ file server.cert.der
server.cert.der: Certificate, Version=3
$ openssl x509 -in server.cert.der -inform DER -out server-back.pem
```

And the proof nothing was lost — fingerprint
the original and the round-trip:

```
$ cmp <(openssl x509 -in server.cert.pem -noout -fingerprint -sha256) \
       <(openssl x509 -in server-back.pem -noout -fingerprint -sha256) && echo SAME-CERT
SAME-CERT
```

Keys convert the same way with `pkey`
(`-outform DER`), and a key's **PKCS#8** form
— the generic `BEGIN PRIVATE KEY` you met in
chapter 5 — is already the cross-algorithm
standard; the older per-algorithm wrappers
(`BEGIN RSA PRIVATE KEY`) are read everywhere
and written only for compatibility. The most
common format error in the wild is not exotic:
a DER file handed to a tool expecting PEM
fails with some version of "no start line",
and vice versa a PEM fed with `-inform DER`
fails as garbage. The fix is always to match
`-inform` to the file you actually have —
`file` and the first line of the file tell
you which that is.

## Bundles: several certificates, one file

PEM's stackability is a feature: a **chain
file** is just certificates concatenated,
leaf first, each issuer after its subject:

```
$ cat server.cert.pem inter/inter.cert.pem > server-chain.pem
$ grep "^-----BEGIN" server-chain.pem
-----BEGIN CERTIFICATE-----
-----BEGIN CERTIFICATE-----
```

Two `BEGIN` lines, two certificates. Order
matters to some tools and not others — the
safe convention is leaf, intermediate(s),
root last (or omitted: a root in a bundle a
server sends is dead weight, as chapter 8
noted). The lab's `chain.pem` is the
mirror-image bundle — intermediate then
root — built for handing to things that need
the issuers: `s_server -cert_chain`,
`pkcs12 -certfile`, and `verify -untrusted`
in spirit. Most "wrong certificate" mysteries
that survive chapter 11 are, in the end, a
bundle file assembled in an order or with a
member nobody checked — and `openssl
verify` against a candidate bundle remains
the way to check it.

## PKCS#12: the suitcase

When a key *and* its certificate (and usually
its chain) must travel together — into a
browser, a Java keystore, a Windows store —
they go as one password-protected binary, a
`.p12` / `.pfx` file. Packing the lab server:

```
$ openssl pkcs12 -export -name "Example Server" -inkey server.key.pem -in server.cert.pem -certfile chain.pem -out server.p12 -passout pass:correct-horse
```

`-name` is the friendly label stores display;
`-certfile` adds the chain. The inspection
report shows the armour — note that, unlike
`enc` in chapter 9, this format uses a
proper iterated derivation and encrypts the
key bag with AES by default in OpenSSL 3:

```
$ openssl pkcs12 -in server.p12 -passin pass:correct-horse -info -noout
MAC: sha256, Iteration 2048
MAC length: 32, salt length: 8
PKCS7 Encrypted data: PBES2, PBKDF2, AES-256-CBC, Iteration 2048, PRF hmacWithSHA256
Certificate bag
Certificate bag
Certificate bag
PKCS7 Data
Shrouded Keybag: PBES2, PBKDF2, AES-256-CBC, Iteration 2048, PRF hmacWithSHA256
```

Three certificate bags (leaf, intermediate,
root) and one shrouded key. Unpacking is the
same command with intent flags: `-clcerts
-nokeys` prints only the leaf certificate,
`-nocerts -nodes` would print the key. Two
traps live here. Old stores may demand the
*legacy* algorithms — OpenSSL 3 packs modern
defaults, and a `.p12` an elderly Java can't
open wants `-legacy` on export. And the
export password is the whole protection:
an empty-password `.p12` (some tools'
silent default on import) is a key in a
clear envelope, however official the
extension looks.

## PKCS#7: certificates without keys

The chain alone, in a binary envelope, is
**PKCS#7** — the `.p7b` file Windows tooling
likes. `crl2pkcs7` (its name advertises its
other job, wrapping revocation lists) builds
one from a bundle with `-nocrl`:

```
$ openssl crl2pkcs7 -nocrl -certfile server-chain.pem -out bundle.p7b -outform DER
$ openssl pkcs7 -inform DER -in bundle.p7b -print_certs -noout
subject=CN = server.example.test, O = Example Lab
issuer=CN = Mere Mortals Intermediate CA, O = Example Lab
subject=CN = Mere Mortals Intermediate CA, O = Example Lab
issuer=CN = Mere Mortals Root CA, O = Example Lab
```

No keys can ride in a PKCS#7 — that is its
virtue. It is the chain, certified as a set,
for handing to anything that needs the
issuers and must never see a private key.
