# Keys

Everything in PKI stands on key pairs, so
they come first in the lab even though
certificates get the glory. The maker is
`openssl genpkey`, the modern one-command for
every key type; the reader is `openssl pkey`.

## Making keys

An RSA key, 2048 bits:

```
$ openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out rsa.key.pem
......+.....+....+............+...+..+.++++ * ......+...
```

The dots and stars are OpenSSL narrating the
search for primes; the whole story is written
to `rsa.key.pem`, whose first line names what
it is:

```
$ head -2 rsa.key.pem
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCPWL6pMGXe3kCl
```

`BEGIN PRIVATE KEY` — unadorned — is the
PKCS#8 form, OpenSSL 3's default for any
algorithm. (Older tools wrote
`BEGIN RSA PRIVATE KEY`; both are PEM, and
`pkey` reads either.)

An EC key is one line shorter to ask for:

```
$ openssl genpkey -algorithm EC -pkeyopt group:P-256 -out ec.key.pem
```

No narration — EC key generation is fast and
deterministic in feel. Which to choose? For a
new key with no compatibility constraint,
P-256: shorter signatures, faster handshakes,
equal standing. RSA 3072 is the conservative
alternative where old clients matter. What
not to choose: RSA below 2048, or a group
nobody's heard of — interoperability is a
security property.

A file-permission habit that is not optional:
private keys are born readable. Every CA step
in chapter 7 does `chmod 600` on its keys, and
so should you, the moment a key exists.

## Reading a key

`pkey` reads any private key and prints its
works. The EC key, in full — EC keys are
small enough to look at:

```
$ openssl pkey -in ec.key.pem -text -noout
Private-Key: (256 bit)
priv:
    eb:08:d5:67:f1:fd:a1:90:6a:2e:6d:8a:cb:4e:9a:
    b2:40:1e:52:75:b6:d1:5a:2c:c2:7c:2b:8e:57:73:
    83:44
pub:
    04:7f:f0:ba:cf:44:35:31:76:b3:97:96:c4:82:62:
    [...]
ASN1 OID: prime256v1
NIST CURVE: P-256
```

That `priv:` block is the actual secret,
printed because you asked. Knowing the
command exists is the point; needing it is
rare, and pasting its output anywhere is how
keys escape. The RSA version of the same
report leads with its modulus — the number
chapter 4 matched against a certificate:

```
$ openssl pkey -in rsa.key.pem -text -noout | head -3
Private-Key: (2048 bit, 2 primes)
modulus:
    00:8f:58:be:a9:30:65:de:de:40:a5:90:21:10:db:
```

## Locking a key with a passphrase

A private key can itself be encrypted, so the
file alone is not the secret:

```
$ openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass pass:correct-horse -out rsa-enc.key.pem
$ head -3 rsa-enc.key.pem
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFLTBXBgkqhkiG9w0BBQ0wSjApBgkqhkiG9w0BBQwwHAQI1j/AkjJJ9BgCAggA
```

(`correct-horse` is the lab's stock specimen
password — typed here in the open because it
protects nothing. A real key's passphrase is
never written in a command, where shells keep
it in history; tools prompt for it instead.
`-pass pass:...` appears in this guide only
so a script can run unattended.)

The lock is real. Reading the key without the
passphrase gets the prompt, three tries, and
then OpenSSL's error dialect, last line first:

```
$ openssl pkey -in rsa-enc.key.pem -noout < /dev/null
Enter pass phrase for rsa-enc.key.pem:
[...]
Could not read key from rsa-enc.key.pem
```

and with it, success:

```
$ openssl pkey -in rsa-enc.key.pem -passin pass:correct-horse -noout -check
Key is valid
```

Encrypted keys suit keys that must sit still —
a CA's root key above all. They complicate
keys a server must load unattended at boot,
which is why web-server keys are usually
unencrypted and protected by file permissions
and little else. The trade-off is real either
way; the sin is not knowing which you chose.

## Taking the public half out

The public key is derived from the private
key on demand:

```
$ openssl pkey -in rsa.key.pem -pubout -out rsa.pub.pem
$ cat rsa.pub.pem
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAj1i+qTBl3t5ApZ...
[...]
-----END PUBLIC KEY-----
```

This is the half you may give away — it is,
in fact, the same public key a certificate
would carry for this key pair. The flow of
the next two chapters is exactly this shape:
the private half stays home, the public half
travels — inside a CSR, to a CA, and comes
back wearing a signature.
