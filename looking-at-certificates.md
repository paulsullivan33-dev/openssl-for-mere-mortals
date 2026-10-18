# Looking at Certificates

The single most useful OpenSSL habit is
reading a certificate before you deploy it,
renew it, or blame it. The reader is
`openssl x509`, and the rule of thumb is:
`-in <file> -noout` plus the questions you
want answered. `-noout` says "don't reprint
the certificate itself"; without it every
answer arrives with the whole PEM block
attached.

Everything below runs against the lab's
server certificate. Build the lab first
(`examples/lab-setup.sh` in an empty
directory), then, from inside it:

```
$ openssl x509 -in server.cert.pem -noout -subject -issuer -dates
subject=CN = server.example.test, O = Example Lab
issuer=CN = Mere Mortals Intermediate CA, O = Example Lab
notBefore=Oct 18 17:39:13 2026 GMT
notAfter=Oct 18 17:39:13 2027 GMT
```

Three of the four first questions answered in
one line each. **Subject** — the name the
certificate claims. **Issuer** — who signed
it; here the intermediate, not the root. A
`-subject` equal to `-issuer` means
self-signed, and the lab's root shows exactly
that:

```
$ openssl x509 -in root/root.cert.pem -noout -subject -issuer
subject=CN = Mere Mortals Root CA, O = Example Lab
issuer=CN = Mere Mortals Root CA, O = Example Lab
```

**Dates** are in GMT, always — certificates
do not do time zones, and "it expired at
midnight" incidents are usually this fact
wearing a coat. The usual follow-up, "how
long has it got?", is `-enddate` alone paired
with your own calendar, or `-checkend 0`,
which exits quietly if the certificate is
still valid and says so if it isn't.

## The parts that decide things

The subject's `CN` is tradition; what modern
clients actually check is the **Subject
Alternative Name** extension — the list of
names the certificate covers:

```
$ openssl x509 -in server.cert.pem -noout -ext subjectAltName
X509v3 Subject Alternative Name: 
    DNS:server.example.test, IP Address:127.0.0.1
```

`-ext <name>` prints one extension. A
certificate asked for with the wrong SAN list
is the hostname-mismatch failure of chapter
11, pre-loaded. Other switches worth knowing:
`-serial` (the issuer's number for this
certificate — the lab's CA started numbering
at `1000`, hex, printed as `serial=1000`),
and `-purpose`, which lists what OpenSSL
considers the certificate good for, given its
extensions.

## Fingerprint: the certificate's name for humans

```
$ openssl x509 -in server.cert.pem -noout -fingerprint -sha256
sha256 Fingerprint=91:11:B6:F1:60:A2:3C:9C:17:99:40:6F:CB:38:F4:EE:0A:2B:E4:4C:6F:3F:12:C0:98:4D:DA:A3:EB:64:10:1A
```

Fingerprints are how you compare two files
without reading either. Same fingerprint,
same certificate — chapter 10 leans on this
to prove a converted file survived. (Use
`-sha256`; bare `-fingerprint` defaults to
SHA-1, fine for identification, and both are
identification only — a fingerprint is a
name, not a signature check.)

## The whole document

When the specific questions run out, `-text`
prints everything OpenSSL knows how to say
about the certificate. The head of the lab
server certificate's report, trimmed:

```
$ openssl x509 -in server.cert.pem -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4096 (0x1000)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = Mere Mortals Intermediate CA, O = Example Lab
        Validity
            Not Before: Oct 18 17:39:13 2026 GMT
            Not After : Oct 18 17:39:13 2027 GMT
        Subject: CN = server.example.test, O = Example Lab
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d9:bc:bf:6c:5e:26:02:71:68:bc:4c:7f:42:5b:
                    [...]
```

Note the serial again: `4096 (0x1000)` — the
same number `-serial` printed as hex. The
rest of the report is the extensions (where
you'll find the SAN again, the key-usage
limits, and `CA:FALSE` in the basic
constraints — this certificate may not sign
others) and the signature itself. Nobody
reads the modulus bytes; they exist for the
next trick.

## The modulus trick: does this key belong to this certificate?

A server needs a key and a certificate that
match. The files rarely say so. The classic
proof compares the public modulus inside the
certificate with the modulus of the key:

```
$ openssl x509 -in server.cert.pem -noout -modulus | cut -c1-60
Modulus=D9BCBF6C5E26027168BC4C7F425B098070E64856BF1217625064
$ openssl rsa -in server.key.pem -noout -modulus | cut -c1-60
Modulus=D9BCBF6C5E26027168BC4C7F425B098070E64856BF1217625064
```

Same number: same key pair. (In practice you
compare hashes — pipe both through
`openssl md5` — rather than eyeballing hex;
the heads are shown here because they match,
which is the point.) A mismatch is the
"key values mismatch" failure every web
server eventually serves someone; finding it
with two commands beats finding it in a log
at deploy time. For EC keys the equivalent
comparison is the public key text from
`openssl x509 -pubkey` against
`openssl pkey -pubout`.

Check: pick any certificate in the lab;
`-subject`, `-issuer` and `-dates` agree with
the story the file's name tells, and the
modulus of `server.cert.pem` and
`server.key.pem` match. If they do, you can
read a certificate. The next chapter makes
the keys themselves.
