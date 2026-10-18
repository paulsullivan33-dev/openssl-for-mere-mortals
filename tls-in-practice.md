# TLS in Practice

Everything so far has been paper — keys and
certificates at rest. TLS is what they do at
work. OpenSSL can stand at both ends of the
conversation: `s_server` is a small TLS
server for testing, `s_client` a client that
connects, shows its working, and reports
exactly what it thought of the certificate
it was handed. Between them, on one machine,
you can run the whole protocol and read it.

## A server

From the lab directory, serving the lab's
server certificate on port 8443:

```
$ openssl s_server -accept 8443 -key server.key.pem -cert server.cert.pem -cert_chain chain.pem -www
```

`-cert_chain` points at the bundle the server
should present alongside its own certificate
— the intermediate (and, in the lab's file,
the root; harmless here, though real servers
send intermediates only, since the root must
come from the client's own store to mean
anything). `-www` makes it answer an HTTP
request with a status page; without it,
`s_server` echoes a tiny interactive
protocol. Leave it running and open a second
terminal.

## A client that trusts the lab

```
$ openssl s_client -connect 127.0.0.1:8443 -CAfile root/root.cert.pem -verify_hostname server.example.test
```

Three clauses do the trusting: `-CAfile`
replaces the trust store with the lab root
alone; `-verify_hostname` says which name the
certificate must cover (necessary because we
dialled an IP address — there was no name to
infer it from); and the connection itself
supplies the rest. The output, in the order
`s_client` prints it, is the handshake's
story:

```
depth=2 CN = Mere Mortals Root CA, O = Example Lab
verify return:1
depth=1 CN = Mere Mortals Intermediate CA, O = Example Lab
verify return:1
depth=0 CN = server.example.test, O = Example Lab
verify return:1
CONNECTED(00000003)
---
Certificate chain
 0 s:CN = server.example.test, O = Example Lab
   i:CN = Mere Mortals Intermediate CA, O = Example Lab
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Oct 18 17:39:13 2026 GMT; NotAfter: Oct 18 17:39:13 2027 GMT
 1 s:CN = Mere Mortals Intermediate CA, O = Example Lab
   i:CN = Mere Mortals Root CA, O = Example Lab
 [...]
 2 s:CN = Mere Mortals Root CA, O = Example Lab
   i:CN = Mere Mortals Root CA, O = Example Lab
 [...]
```

The walk from chapter 7, performed live:
`depth` counts down from the root the server
presented to the leaf at depth 0, each
`verify return:1` a signature checked on the
way. Then the summary that matters:

```
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
[...]
Verify return code: 0 (ok)
```

and it is a working connection — ask it for
the page (`s_server`'s `-www` answers):

```
$ printf 'GET / HTTP/1.0\r\n\r\n' | openssl s_client -connect 127.0.0.1:8443 -CAfile root/root.cert.pem -quiet
HTTP/1.0 200 ok
Content-type: text/html
```

Small print worth knowing: the full output
also carries the line `Server Temp Key:
X25519, 253 bits` — the *ephemeral* key the
two ends generated fresh for this session.
That, not the certificate's RSA key, is what
encrypts the traffic: the certificate's job
in TLS is authentication (proving the name),
and the handshake agrees a disposable key for
confidentiality. It is why a certificate can
be public without the recorded traffic being
readable later.

## Names: SNI, briefly

Real servers hold many names on one address
and choose a certificate based on the name
the client asks for — the **Server Name
Indication**. `s_client` sends it with
`-servername`. Against the public internet
(the one non-lab capture in this guide,
taken on the build machine):

```
$ openssl s_client -connect example.com:443 -servername example.com
subject=CN = example.com
issuer=C = US, O = SSL Corporation, CN = Cloudflare TLS Issuing ECC CA 3
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

No `-CAfile`: the system trust store vouched,
exactly as your browser's does. Same client,
same sentences — the lab and the internet
differ only in who issued the paper.

## Versions and ciphers: negotiation, then force

Left alone, both ends offer what they have
and settle on the best common ground —
TLS 1.3 here. Pin the server to TLS 1.2
(restart `s_server` with `-tls1_2` added) and
the settlement moves:

```
New, TLSv1.2, Cipher is ECDHE-RSA-AES256-GCM-SHA384
    Protocol  : TLSv1.2
```

The cipher name changes its shape, too: 1.3
suites are short fixed names (`TLS_AES_256_
GCM_SHA384`); 1.2 suites describe the whole
bargain — key exchange (`ECDHE`), signature
(`RSA`), bulk cipher and mode
(`AES256-GCM`), hash (`SHA384`).
`openssl ciphers -v` lists what your build
can speak, in those terms.

Now make the client demand what the server
won't give — `-tls1_3` against the 1.2-only
server:

```
$ openssl s_client -connect 127.0.0.1:8443 -CAfile root/root.cert.pem -tls1_3
[...]
error:0A00042E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:...:SSL alert number 70
```

**Alert 70** is TLS's own error code for
"protocol version" — the server answered the
hello with a refusal, in protocol. And note
the trap in that output: it ends with
`Verify return code: 0 (ok)`. The verify code
grades the *certificate*; no certificate was
ever reached, so nothing failed it. Judge a
connection by whether it connected — the
alert, the cipher line, the missing page —
not by the friendliest number on the page.

What breaks at the certificate layer, even
when versions agree, is chapter 11 — every
failure there is reproducible against the
server you just ran.
