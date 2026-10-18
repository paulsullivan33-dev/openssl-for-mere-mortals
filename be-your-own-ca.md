# Be Your Own CA

A certificate authority, stripped of
ceremony, is a key, a certificate that says
`CA:true`, and bookkeeping: what it has
signed, and which serial number comes next.
`openssl ca` is the bookkeeping program. It
is not glamorous — it keeps a text-file
database and flatly refuses to work without
one — but what it does is precisely what
every CA does, with the audits and lawyers
left as an exercise.

The lab builds two CAs on purpose. A **root**
that signs almost nothing and could, in a
realer world, live offline; and an
**intermediate** under it that does the
daily work of signing servers. Two levels is
how the public system is built, and it is
what makes chapter 11's "incomplete chain"
failure possible to demonstrate honestly.
`examples/lab-setup.sh` runs everything in
this chapter end to end; what follows is the
walk-through.

## The configuration

`openssl ca` takes nearly all its orders
from a config file — `examples/ca.cnf`,
which defines both CAs. One section per CA:

```
[ CA_root ]
dir            = ./root
database       = $dir/index.txt
serial         = $dir/serial
new_certs_dir  = $dir/newcerts
private_key    = $dir/private/root.key.pem
certificate    = $dir/root.cert.pem
default_md     = sha256
default_days   = 365
policy         = policy_any
unique_subject = no
```

Directories for its files, paths to its key
and certificate, the hash to sign with, and a
**policy** — which name fields a request
must have. `policy_any` here demands only a
common name; public CAs run policies with
lawyers attached. `unique_subject = no`
permits signing two certificates for the
same name, which the lab needs (a server
certificate and its expired twin).

Plus the extension sections the signatures
will stamp — the root's (`CA:true`), the
intermediate's (`CA:true, pathlen:0` — it may
sign servers but no further CAs), and the
server's (its SAN list, `CA:false`):

```
[ v3_server ]
basicConstraints       = CA:false
keyUsage               = digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
subjectAltName         = DNS:server.example.test, IP:127.0.0.1
```

The bookkeeping files are made by hand,
once: an empty `index.txt` (the database)
and a `serial` file holding the first serial
number, `1000`. If `openssl ca` fails with
a complaint about the database or serial,
this paragraph is why.

## The root

A key, then a certificate it signs for
itself, wearing the `v3_root_ca` extensions:

```
$ openssl req -new -x509 -key root/private/root.key.pem -out root/root.cert.pem -days 3650 -subj "/CN=Mere Mortals Root CA/O=Example Lab" -config ca.cnf -extensions v3_root_ca
$ openssl x509 -in root/root.cert.pem -noout -subject -issuer -dates
subject=CN = Mere Mortals Root CA, O = Example Lab
issuer=CN = Mere Mortals Root CA, O = Example Lab
notBefore=Oct 18 17:39:03 2026 GMT
notAfter=Oct 15 17:39:03 2036 GMT
```

Ten years for the root — roots are long-lived
by design, since replacing one means
redistributing trust itself.

## The intermediate

Key, CSR, and then the root at work via
`openssl ca -name CA_root` (the `-name`
selects which CA section signs; without it
the config's default — the intermediate —
signs):

```
$ openssl ca -config ca.cnf -name CA_root -extensions v3_inter_ca -in inter.csr.pem -out inter/inter.cert.pem -batch -notext
Using configuration from ca.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'Mere Mortals Intermediate CA'
organizationName      :ASN.1 12:'Example Lab'
Certificate is to be certified until Oct 18 17:39:09 2027 GMT (365 days)

Write out database with 1 new entries
Database updated
```

Read that output once and `openssl ca` holds
no mysteries: it checked the CSR's signature,
showed the name it is about to certify,
asked for confirmation (`-batch` answered
yes), and updated its database — the
`root/index.txt` file now holds one line
recording serial `1000`, the dates, and the
subject. That line is the CA's memory; lose
it and the CA forgets what it signed.

```
$ openssl x509 -in inter/inter.cert.pem -noout -subject -issuer
subject=CN = Mere Mortals Intermediate CA, O = Example Lab
issuer=CN = Mere Mortals Root CA, O = Example Lab
```

## The server certificate, and the judge

Chapter 6's CSR, signed by the intermediate
with the `v3_server` extensions:

```
$ openssl ca -config ca.cnf -extensions v3_server -in server.csr.pem -out server.cert.pem -batch -notext
```

Then the moment the whole structure is for.
`openssl verify` walks the chain — here it
needs the root as the trust anchor
(`-CAfile`) and the intermediate offered as
an **untrusted** helper (`-untrusted`): the
chain's middle is evidence, not belief.

```
$ openssl verify -CAfile root/root.cert.pem -untrusted inter/inter.cert.pem server.cert.pem
server.cert.pem: OK
```

`OK` is the smallest complete sentence in
PKI: the signatures check, the dates check,
the chain reaches the root you named. Every
failure in chapter 11 is this command, or an
`s_client` handshake, producing something
else — and now you own a lab where the good
case passes, which is what makes the bad
cases legible.

Also built by the setup script, waiting for
their chapters: `expired.cert.pem` — the same
CSR signed with `-startdate 20240101000000Z
-enddate 20250101000000Z`, `openssl ca`'s way
of minting history; `wronghost.cert.pem` —
valid, signed, and for `other.example.test`;
and the bundle files chapter 10 explains.
