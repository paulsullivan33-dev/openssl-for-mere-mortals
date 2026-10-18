# Hashes, HMAC and Symmetric Encryption

Not everything in the box is certificates.
OpenSSL also carries the everyday primitives:
hashes that fingerprint data, a keyed
variant that proves who sent it, symmetric
encryption for files, and the random numbers
everything else is built from. This chapter
runs each once, honestly — including the one
with warts.

## Hashes: `dgst`

A **hash** turns any input into a fixed-size
fingerprint — same input, same fingerprint;
any change, a totally different one. (A
certificate fingerprint in chapter 4 was
exactly this, over the certificate.) On
files:

```
$ printf 'the quick brown fox\n' > message.txt
$ openssl dgst -sha256 message.txt
SHA2-256(message.txt)= 6e459fed18ddb06d57c8e9f0d000c302c7e01389926db6e89884bfbe91a2a5df
$ sha256sum message.txt
6e459fed18ddb06d57c8e9f0d000c302c7e01389926db6e89884bfbe91a2a5df  message.txt
```

Two programs, one answer — the agreement is
the point of a standard algorithm, and the
cross-check is the point of the exercise.
`dgst` with no algorithm defaults to SHA-256
in the 3.x line; name it anyway, because a
fingerprint that doesn't say its algorithm
will eventually be compared against the wrong
one. SHA-256 is the workhorse; the MD5 and
SHA-1 entries in `openssl list
-digest-algorithms` are for reading old
things, never for new fingerprints where
collision resistance matters.

A hash proves data hasn't changed **if** you
trust where you got the hash. It says
nothing about who made the data — anyone can
hash anything. That gap is what the keyed
version fills.

## HMAC: a hash with a key

**HMAC** mixes a secret key into the hash.
Only someone holding the key can produce or
check the result, so a matching HMAC proves
the message came from a key-holder and
arrived unchanged — authentication without
certificates, for parties who already share
a secret.

```
$ openssl dgst -sha256 -hmac "s3cret-key" message.txt
HMAC-SHA2-256(message.txt)= caa5b3091910d2a49213c3d8bcf1455921ac92fb3c9898a55e90675b9c9d7ebc
```

The 3.x line also has a general-purpose
`mac` command — and a genuine paper cut,
kept here because the tool really does it:
HMAC through `mac` refuses to run until you
name the digest explicitly.

```
$ openssl mac -macopt key:s3cret-key -macopt digest:SHA256 HMAC < message.txt
CAA5B3091910D2A49213C3D8BCF1455921AC92FB3C9898A55E90675B9C9D7EBC
```

Same bytes in, same MAC out (uppercase is
cosmetic). Either command serves; `dgst
-hmac` is the one-liner to remember.

## Symmetric encryption: `enc`, with its caveats stated

`enc` encrypts a file with a password: one
secret both encrypts and decrypts
(**symmetric**, unlike the key pairs of
chapter 5). The round trip:

```
$ openssl enc -aes-256-cbc -salt -pbkdf2 -in message.txt -out message.enc -pass pass:correct-horse
$ openssl enc -aes-256-cbc -d -pbkdf2 -in message.enc -pass pass:correct-horse
the quick brown fox
```

Now the honesty. `enc` announces its own
main caveat, verbatim, the moment you omit
`-pbkdf2`:

```
*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better.
```

A password is not a key; it must be *derived*
into one. The historical derivation is a
single fast hash round — quick for you, and
quick for an attacker trying a million
passwords. `-pbkdf2` derives through many
rounds (10,000 by default) and is the least
you should accept; `-salt` makes each file's
derivation unique, and its mark is visible
at the start of every `enc` file:

```
$ head -c 16 message.enc | od -c | head -2
0000000   S   a   l   t   e   d   _   _ 016 276 034 270   q   j 234   m
```

`Salted__` plus eight bytes of salt, then the
ciphertext. And the failure mode, with the
wrong password:

```
$ openssl enc -aes-256-cbc -d -in message.enc -pass pass:wrong-horse
[...]
bad decrypt
```

— followed by garbage bytes on the terminal.
`enc` has no integrity check: it cannot
distinguish a wrong password from corrupted
data, and a tampered ciphertext decrypts to
tampered plaintext without complaint. For a
file you toss across a desk it is fine; for
anything that matters, use a tool built for
the job (an AEAD cipher via a real file
encryption program, e.g. `age` or `gpg`),
where a wrong key fails cleanly and nothing
silent slips through. This guide keeps `enc`
because it is everywhere — scripts, tutorials,
and legacy backups are full of it — and
reading it correctly includes its limits.

## Randomness and base64

Everything above stands on unpredictable
numbers; `rand` is the tap:

```
$ openssl rand -hex 16
23fb607cabe501af651093c450998400
$ openssl rand -base64 24
Gx7aEFiexnATerViStU0r8G7PrIxVty9
```

This output feeds tokens, salts, and test
data everywhere. Use the tool's, never a
shell `$RANDOM` or a timestamp, for anything
security-shaped.

Base64 — the encoding that makes PEM PEM —
is its own tiny subcommand, worth knowing
because half the binary blobs in computing
arrive wearing it:

```
$ echo "hello, world" | openssl base64
aGVsbG8sIHdvcmxkCg==
$ echo "aGVsbG8sIHdvcmxkCg==" | openssl base64 -d
hello, world
```

The trailing `=` signs are padding, and a
blob that won't decode is usually line-wrapped
or truncated — try `-A` for one-line inputs
that arrive without newlines.
