# CSRs and Self-Signed Certificates

A **certificate signing request** is the
application a key fills in. You make one from
a key you already hold; the form carries the
public half and the name you're asking for,
signed with the private half — so a CA
receiving it knows the applicant really holds
the key, without the key ever travelling.

The lab's server gets its CSR like this
(chapter 7 signs it):

```
$ openssl req -new -key server.key.pem -out server.csr.pem -subj "/CN=server.example.test/O=Example Lab"
```

`req -new` is the form-filler; `-subj` answers
the distinguished-name questions inline
(`/CN=` common name, `/O=` organisation; add
`/C=`, `/ST=`, `/L=` as a real CA demands).
Without `-subj`, `req` asks interactively,
reading defaults from the system `openssl.cnf`.
A CSR reads back with the same command:

```
$ openssl req -in server.csr.pem -noout -subject
subject=CN = server.example.test, O = Example Lab
```

## The names that count: SANs on a CSR

Chapter 4's lesson applies at application
time: clients check the **Subject Alternative
Name** list, so that's where the names must
go. There are two ways to attach them, and
the guide demonstrates both.

On the command line, with `-addext`:

```
$ openssl req -x509 -newkey rsa:2048 -keyout selfsigned.key.pem -out selfsigned.cert.pem -days 365 -nodes -subj "/CN=server.example.test" -addext "subjectAltName=DNS:server.example.test,IP:127.0.0.1"
```

(that command is next section's business —
the flag is the point here). In a
configuration file, the way that scales —
`examples/server-req.cnf`:

```
[ req ]
distinguished_name = dn
req_extensions     = ext
prompt             = no

[ dn ]
CN = server.example.test
O  = Example Lab

[ ext ]
subjectAltName = DNS:server.example.test, IP:127.0.0.1
```

```
$ openssl req -new -key server.key.pem -out server2.csr.pem -config server-req.cnf
$ openssl req -in server2.csr.pem -noout -text | grep -A1 "Subject Alternative"
                X509v3 Subject Alternative Name:
                    DNS:server.example.test, IP Address:127.0.0.1
```

The config approach wins whenever the request
is more than a name — SAN lists, key usage,
organisation details — because the file is
the documentation of what was asked for, and
chapter 7's CA is configured the same way.
One warning the CA chapter cashes in: a CA
may honour, alter, or ignore the extensions
a CSR requests. The issued certificate, read
back with chapter 4's tools, is the only
truth about what you got.

## Self-signed: the certificate you issue yourself

Skip the CA entirely and `req` will sign the
certificate with the applicant's own key —
that long command above did five things at
once: made a fresh 2048-bit RSA key
(`-newkey rsa:2048`), saved it unencrypted
(`-nodes`, "no DES", the ancient flag name for
no passphrase), saved the certificate it
signed for itself (`-x509`), valid 365 days,
with the SAN list attached. The result reads
exactly like chapter 4's root:

```
$ openssl x509 -in selfsigned.cert.pem -noout -subject -issuer
subject=CN = server.example.test
issuer=CN = server.example.test
```

Subject equals issuer. The signature is
genuine; the *vouching* is circular — this
certificate says "trust me" in its own
handwriting.

## Why browsers reject it

A browser's refusal is not about the
signature's quality. Verification asks: does
the chain reach a root in my trust store?
A self-signed certificate's chain reaches
itself, and it is not in the store:

```
$ openssl verify selfsigned.cert.pem
CN = server.example.test
error 18 at 0 depth lookup: self-signed certificate
error selfsigned.cert.pem: verification failed
```

**Error 18** is the first of chapter 11's
five. The flip side is instructive: tell the
verifier to trust the certificate itself and
the same file passes instantly —

```
$ openssl verify -CAfile selfsigned.cert.pem selfsigned.cert.pem
selfsigned.cert.pem: OK
```

— because that is what a trust store *is*:
a list of certificates someone decided to
believe. Self-signed certificates have honest
work to do everywhere trust is arranged by
hand — the lab's root is one, and pinned
certificates inside an organisation are
another — but a public website cannot ask
every visitor to hand-arrange trust in it.
That asking is the CA system's entire reason
to exist, and it is next.
