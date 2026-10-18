# What OpenSSL Is

Almost every secure conversation on the
internet rests on three promises: nobody else
can read this, nobody has quietly changed it,
and the machine at the other end is the one
it claims to be. **TLS** — the protocol behind
the padlock, behind `https`, behind most
encrypted mail and chat and API traffic — is
the machinery that makes those promises. And
TLS needs parts: ways to generate keys, agree
on secrets, sign things, check signatures, and
carry identity documents called certificates.

OpenSSL is the box those parts come in.

It began in the 1990s as SSLeay, an
implementation of the young SSL protocol, and
grew into the default cryptography library of
the Unix world. Today it is two things:

- **A library** (two, really: `libcrypto` for
  the raw algorithms and key handling,
  `libssl` for TLS itself) that other programs
  link and call. Web servers, mail servers,
  database clients, programming languages —
  a very large share of them do their TLS
  through OpenSSL without you ever seeing its
  name.
- **A command line**, the `openssl` program,
  which exposes the same machinery to you at a
  terminal. It generates keys, builds and
  reads certificates, hashes and encrypts
  files, and can act as a TLS server or client
  for testing.

This guide is about the command line. The
library matters here for one reason: when a
program that uses OpenSSL prints an error,
the error is written in OpenSSL's vocabulary —
`verify error:num=20`, `error 10 at 0 depth
lookup` — and the command line is where you
learn that vocabulary fastest, because you can
make every one of those errors happen on
purpose.

## The certificate idea, in one paragraph

A **certificate** is a signed statement. It
says: *the public key in this document belongs
to the name in this document* — and it is
signed by an issuer, a **certificate
authority** (CA), whose own certificate says
who signed *it*, and so on up to a **root**:
a self-signed certificate that operating
systems and browsers carry in a built-in trust
store because somebody — Mozilla, Apple,
Microsoft, a Linux distribution — decided to
believe it. Checking a certificate means
walking that **chain of trust** to a root you
already hold, confirming every signature,
every date, and that the name matches the
machine you wanted. Chapter 2 gives the
vocabulary properly; the rest of the guide is
that paragraph, made runnable.

## Why a command-line guide, in the ACME era

Fair question: real websites get certificates
from Let's Encrypt and friends, automatically,
and you may never hand-sign anything in
production. The command line still earns its
place three ways:

- **Reading.** Certificates arrive as files.
  `openssl x509` is how you ask one what it
  is, who issued it, when it dies, and which
  names it covers — the first questions in any
  TLS incident.
- **Testing.** `openssl s_client` talks TLS
  to anything, shows its working, and prints
  exactly why a connection was refused. No
  browser's friendly error page does that.
- **Small worlds.** Home labs, internal
  services, development setups, and embedded
  gear still run on hand-made CAs — the two
  chapters here on building one are the honest
  way to learn what a CA actually does.

Everything the lab here makes is a specimen:
fake names, throwaway keys, one deliberately
silly password. That is stated again wherever
it matters, because the same commands with
real names and careless storage are how real
keys leak.

Next: the vocabulary, then the program itself.
