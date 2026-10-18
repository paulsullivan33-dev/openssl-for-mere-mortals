# The Vocabulary

Certificates intimidate because the words
pile up before the ideas do. There are really
only seven ideas. Everything else in this
guide is combinations of them.

## Key pair

A **key pair** is two matched halves of one
secret. The **private key** is kept hidden:
whoever holds it can sign and can decrypt.
The **public key** is given away freely:
anyone can use it to check those signatures
and to encrypt toward the owner. The math
guarantees the pairing is one-way — the
public half reveals nothing usable about the
private half. A key pair is made by generating
it (chapter 5), never by choosing it.

Two families matter in practice. **RSA** keys
are the old standard: widely understood,
larger, sized in bits (2048 is the floor, 3072
and 4096 the cautious sizes). **EC** keys
(elliptic curve) are the modern default:
smaller and faster at equal strength, named
by their curve — `prime256v1`, universally
called P-256, is the common one.

## Certificate

A **certificate** binds a public key to a
name. It is a small structured document
(the format is called X.509) containing the
name it belongs to (the **subject**), the
public key, the name of whoever vouches for
it (the **issuer**), a **serial number**, a
validity window (**not before** / **not
after**), a list of **extensions** — extra
facts, the important one being the **Subject
Alternative Name** (SAN) list, the names the
certificate actually covers — and a
**signature** over all of it, made with the
issuer's private key.

One sentence to keep: a certificate is not
encryption and it is not secret. It is an ID
card — public, checkable, and worthless if
the signature or the dates fail.

## CA

A **certificate authority** is whoever signs
certificates. A CA's own identity is also a
certificate, marked with a basic constraint
that says *this one may sign others*
(`CA:true`). Public CAs — the ones browsers
trust — are audited businesses. A CA can also
be a file pair on your disk: chapter 7's
two-CA lab is exactly that, and inside its
small world its signatures are just as real.

## CSR

A **certificate signing request** is the
application form: your public key, the name
you are asking for, your requested extensions,
and a signature made with your private key —
proof that the applicant holds the key the
certificate will name. You send a CA the CSR,
never the private key. The CA checks whatever
it checks, then issues the certificate. A CSR
is an input, not a credential; a used CSR is
just a file.

## Chain of trust

Certificates vouch downward. Your server's
certificate is signed by an **intermediate
CA**; the intermediate's certificate is signed
by a **root CA**; the root signs itself and
is *trusted by decree* — it ships in a trust
store. **Verification** walks the chain from
the leaf up: each signature checked against
the next certificate's public key, each
certificate inside its dates, until the walk
reaches a root the verifier already holds.
Any break — a missing link, an expired link,
an unknown root — fails the whole walk, and
chapter 11 is a tour of the five ways it
breaks.

Note what the chain proves and what it
doesn't. It proves the name in the certificate
was vouched for by that chain. That the
*machine answering you* holds the matching
private key is proven separately, live, by
the TLS handshake — a stolen certificate file
alone is not enough to impersonate anyone.

## PEM and DER

The same certificate can be stored two ways.
**DER** is the raw binary form: compact,
unreadable, one object per file, common in
Java and Windows tooling (`.der`, `.cer`).
**PEM** is that same binary base64-encoded
between header lines:

```
-----BEGIN CERTIFICATE-----
MIIDhDCCAmygAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwPTElMCMG...
-----END CERTIFICATE-----
```

PEM is the Unix world's default: it survives
email and editors, and several PEM objects can
be stacked in one file — which is exactly how
a certificate *chain* is shipped. The header
line names the object: `CERTIFICATE`,
`PRIVATE KEY`, `CERTIFICATE REQUEST`, and a
mismatch between the label and what a tool
expects is a classic small-hours error.
Chapter 10 converts between the forms.

A **fingerprint** is a hash of the DER form,
printed as colon-separated hex bytes:

```
sha256 Fingerprint=91:11:B6:F1:60:A2:3C:9C:17:99:40:...
```

It identifies a certificate the way a
fingerprint identifies a person: not the
document, but unique to it. Two copies of the
same certificate have the same fingerprint;
any change, however small, makes a different
one. It is the fastest way to answer "are
these two files the same certificate?" —
chapter 4 uses it that way.

Next: the program itself, and how its
subcommands are organised.
