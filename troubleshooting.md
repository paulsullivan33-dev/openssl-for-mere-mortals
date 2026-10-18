# Troubleshooting

Every TLS complaint in the world reduces, at
the certificate layer, to a short list of
failures — and every one of them is already
on your disk if you built the lab. This
chapter produces each one twice: once with
`openssl verify` (the paper check), once at
a live handshake with `s_server` /
`s_client` where that adds anything, and
reads the message the way chapter 3 taught:
the human sentence, last, first.

Throughout: add `-verify_return_error` to
`s_client` when testing. Without it,
`s_client` reports verification failures and
*connects anyway* — behaviour inherited from
its debugging purpose, and the cause of more
than one "but OpenSSL said it worked" ghost.

## 1. Unknown issuer — "unable to get local issuer certificate"

The verifier cannot find the certificate
that signed yours in anything it trusts.

```
$ openssl verify server.cert.pem
CN = server.example.test, O = Example Lab
error 20 at 0 depth lookup: unable to get local issuer certificate
error server.cert.pem: verification failed
```

**Error 20.** The usual real-world cause is
not an evil certificate but an *institutional*
one: the issuer is a private CA (your
company's, your lab's) that this machine has
simply never been told about. The fix is the
`-CAfile` / `-CApath` that hands the verifier
its root — or, in a real program, installing
that root in the system store properly. In
the lab, offering the root and the
intermediate settles it:

```
$ openssl verify -CAfile root/root.cert.pem -untrusted inter/inter.cert.pem server.cert.pem
server.cert.pem: OK
```

The same failure wears a sibling's face when
the issuer *is* known but a link is missing —
that is failure 6, below.

## 2. Self-signed — error 18

```
$ openssl verify selfsigned.cert.pem
CN = server.example.test
error 18 at 0 depth lookup: self-signed certificate
error selfsigned.cert.pem: verification failed
```

Live, a server presenting it gets the same
number in the handshake (`Verify return code:
18`). **Error 18** means the certificate's
issuer is itself — chapter 6's circular
vouching. The fix is never a setting on the
certificate; it is trust, arranged on purpose:
install the certificate (or a CA of your own,
chapter 7) into the client's store, or get
the certificate issued by a CA the client
already trusts. If the self-signed certificate
is unexpected — a name you pay a real CA for —
you are looking at the wrong server, a
misconfigured one, or an interception, and
the correct fix is at the server.

## 3. In the chain, but the root isn't trusted — error 19

Present the full lab chain to a client that
trusts nothing (`s_client` with no
`-CAfile`) and the number changes:

```
verify error:num=19:self-signed certificate in certificate chain
Verify return code: 19 (self-signed certificate in certificate chain)
```

**Error 19** is error 18 one level up: the
walk reached a self-signed root — fine — but
that root is not in *this* client's store.
It is the normal state of a private-CA
deployment before the root is distributed,
and the reason chapter 7's root is the one
file you give *everyone*, while the
intermediate's key stays home. Browsers
shipped by an employer do this distribution
for the company CA; your lab does it with
`-CAfile`.

## 4. Expired — error 10

```
$ openssl verify -CAfile root/root.cert.pem -untrusted inter/inter.cert.pem expired.cert.pem
CN = server.example.test, O = Example Lab
error 10 at 0 depth lookup: certificate has expired
error expired.cert.pem: verification failed
```

```
verify error:num=10:certificate has expired
Verify return code: 10 (certificate has expired)
```

**Error 10** is the one failure with a clock
in it. Two readings before renewing anything:
check the *certificate's* dates (chapter 4)
— an expired intermediate fails its whole
family, and `openssl verify` reporting the
leaf at "0 depth" doesn't exempt the chain —
and check the *verifying machine's* clock,
since a client with a wrong date manufactures
error 10 (and its twin, `error 9: certificate
is not yet valid`) against perfect
certificates. The lab's specimen was made
with `openssl ca -startdate 20240101000000Z
-enddate 20250101000000Z`; its real-world
counterpart arrives by itself, on a schedule,
usually during a holiday.

## 5. Hostname mismatch — error 62

The certificate is valid, trusted, in date —
and for a different name.

```
$ openssl verify -CAfile root/root.cert.pem -untrusted inter/inter.cert.pem -verify_hostname server.example.test wronghost.cert.pem
CN = other.example.test, O = Example Lab
error 62 at 0 depth lookup: hostname mismatch
error wronghost.cert.pem: verification failed
```

```
$ openssl s_client -connect 127.0.0.1:8443 -CAfile root/root.cert.pem -verify_hostname other.example.test -verify_return_error
verify error:num=62:hostname mismatch
```

**Error 62.** Remember what is being compared:
the name the *client asked for*
(`-verify_hostname`, or the hostname it
dialled) against the certificate's SAN list —
chapter 4's `-ext subjectAltName` shows the
list it failed to be in. Causes in the wild,
in order: the certificate was issued for a
different name than the service now answers
to; several names share one address and the
server picked the wrong certificate (SNI,
chapter 8); or `www.example.test` is being
served the certificate for `example.test`
without the `www` in its SANs. The fix is
always on the certificate or the server's
choice of it — never on the client's
insistence. Ask the same verifier for the
name the certificate actually carries and
the identical file passes:

```
$ openssl verify -CAfile root/root.cert.pem -untrusted inter/inter.cert.pem -verify_hostname other.example.test wronghost.cert.pem
wronghost.cert.pem: OK
```

## 6. Incomplete chain — the server kept a link

Failure 1 with the anchor *present* but the
middle missing. Serve the lab certificate
*without* `-cert_chain`, to a client that
trusts the root:

```
verify error:num=20:unable to get local issuer certificate
Verify return code: 20 (unable to get local issuer certificate)
```

The client holds the root; the server holds
the intermediate; neither can complete the
walk because the one certificate nobody
shipped is the one that joins them. The
diagnostic question is "what did the server
actually present?" — the `Certificate chain`
block of any `s_client` run lists it, and
one block with only `0 s:...` in it is this
failure photographed. The fix is server-side:
present the chain bundle (chapter 10's
`server-chain.pem`, or `-cert_chain`),
because clients cannot be expected to fetch
your middle links — some do, which is why
this failure classically appears on *some*
clients and not others, and wastes the most
time of any in this chapter.

## The general drill

For any certificate complaint, in order:
read the certificate (chapter 4 — subject,
issuer, dates, SANs); reproduce with
`verify` against a known root; reproduce
with `s_client -verify_return_error` against
the live service and read the chain block;
believe the number, not the prose around it.
The five numbers here — 10, 18, 19, 20, 62 —
cover the overwhelming majority of what
production will ever show you, and now each
one has a face you made yourself.
