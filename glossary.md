# Glossary

**AES** — the standard symmetric block
cipher. In this guide as AES-256-CBC, the
cipher `enc` and PKCS#12 use. The 256 is the
key length in bits.

**Base64** — an encoding that carries binary
data as printable text, at a cost of about a
third more bytes. PEM files are base64 with
header lines around them.

**Basic constraints** — the certificate
extension that says whether the certificate
may act as a CA (`CA:true`) and, if so, how
many CA levels may sit below it (`pathlen`).

**CA (certificate authority)** — the issuer
of certificates: whoever holds a `CA:true`
certificate and signs others with its key.
A public business, or two files in a lab.

**Certificate** — a signed document binding
a public key to a name: subject, issuer,
serial, dates, extensions, and the issuer's
signature over all of it. Chapter 4 reads
one field by field.

**Chain of trust** — the sequence of
certificates from a leaf up through
intermediates to a root, each signed by the
next. Verification is walking it.

**Cipher suite** — the agreed recipe for a
TLS connection: key exchange, signatures,
bulk cipher, hash. Named in full for TLS
1.2 (`ECDHE-RSA-AES256-GCM-SHA384`),
numbered briefly for 1.3 (`TLS_AES_256_
GCM_SHA384`).

**CSR (certificate signing request)** — the
application form for a certificate: your
public key and requested name, signed with
your private key. The key itself never
travels.

**DER** — the binary storage form of a
certificate or key: compact, one object per
file, common in Windows and Java tooling.

**Distinguished name (DN)** — a certificate
name written as fields: `CN` (common name),
`O` (organisation), `OU`, `L`, `ST`, `C`.
Subjects and issuers are DNs.

**EC / elliptic curve** — the modern key
family: small keys, fast operations, named
by curve. P-256 (`prime256v1`) is the common
one.

**Fingerprint** — a hash of a certificate's
DER form, printed as colon-separated hex.
A name for a certificate: same fingerprint,
same certificate.

**HMAC** — a hash mixed with a secret key:
proves a message came from a key-holder and
arrived unchanged.

**Intermediate CA** — a CA signed by a root
(or a higher intermediate) that does the
everyday signing, keeping the root's key
out of daily use. `pathlen:0` ones can sign
servers but no further CAs.

**KDF (key derivation function)** — the
process that turns a password into a key.
PBKDF2 is the iterated one `enc -pbkdf2`
and PKCS#12 use; the legacy single-round
derivation in `enc` is the weak one.

**PEM** — the text storage form: base64
between `-----BEGIN ...-----` and
`-----END ...-----` lines, the label naming
the object. Several objects may stack in
one file — that is how chain bundles work.

**PKCS#7** — an envelope carrying
certificates (and optionally signed data)
with no private keys; the `.p7b` form.

**PKCS#8** — the generic wrapper for
private keys of any algorithm: PEM label
`PRIVATE KEY`, or `ENCRYPTED PRIVATE KEY`
when locked.

**PKCS#12** — the suitcase format: a
private key plus its certificate and chain
in one password-protected binary file
(`.p12`, `.pfx`).

**Private key** — the secret half of a key
pair. Whoever holds it is, to the protocol,
the owner. Protect it like one.

**Provider** — OpenSSL 3's pluggable source
of algorithms. `openssl list -providers`
shows which are loaded; the default provider
is the usual one.

**Public key** — the shareable half of a
key pair, carried inside certificates and
used to verify signatures.

**Root CA** — a self-signed CA whose
certificate sits in a trust store by
decision rather than by proof. The anchor
every chain walk ends at.

**RSA** — the original public-key family:
keys sized in bits (2048 and up), signatures
and the modulus of chapter 4's matching
trick.

**Salt** — random bytes mixed into a key
derivation or stored with a hash, so the
same password yields different results in
different files. The `Salted__` header of
an `enc` file is one, in the open.

**SAN (Subject Alternative Name)** — the
extension listing the names a certificate
actually covers, as `DNS:` and `IP:` entries.
The list clients check; the CN is a
courtesy.

**Self-signed** — a certificate whose
issuer is itself: subject equals issuer.
Roots are self-signed and trusted by
decision; a server's self-signed certificate
is error 18 to everyone who hasn't made
that decision about it.

**Serial number** — an issuer's unique
number for a certificate, handed out in
sequence from the CA's `serial` file. The
lab's CA started at `1000` (hex).

**SNI (Server Name Indication)** — the name
a TLS client asks for at hello time, so a
server holding many certificates can pick
the right one. `s_client -servername`.

**TLS** — Transport Layer Security: the
protocol that authenticates with these
certificates and encrypts with fresh,
ephemeral keys. Versions 1.2 and 1.3 are
the living ones.

**Trust store** — the set of root
certificates a machine or browser has
decided to believe: `/etc/ssl/certs` on a
Linux box, or one file named by `-CAfile`.

**Verify return code** — `s_client`'s
grade of the certificate it was shown:
0 is `(ok)`; anything else is the error
number of chapters 7 and 11. It grades the
paper, not the connection.
