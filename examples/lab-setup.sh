#!/bin/sh
# lab-setup.sh -- build the throwaway PKI lab used throughout
# "OpenSSL for Mere Mortals".
#
# Run it in an empty directory:
#
#     mkdir lab && cd lab
#     sh /path/to/lab-setup.sh
#
# It expects ca.cnf and server-req.cnf (both shipped in examples/)
# to sit next to the script; they are copied into the lab.
#
# EVERYTHING it makes is a teaching specimen: fake names
# (example.test, "Example Lab"), throwaway keys, and one password
# (correct-horse) used only so the commands can run unattended.
# Never use any of it to protect anything real.

set -eu

HERE=$(dirname "$0")
cp "$HERE/ca.cnf" "$HERE/server-req.cnf" .

# --- CA bookkeeping files openssl ca insists on -------------------
mkdir -p root/private root/newcerts inter/private inter/newcerts
touch root/index.txt inter/index.txt
echo 1000 > root/serial
echo 1000 > inter/serial

# --- Root CA: a key, then a certificate that signs itself ---------
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out root/private/root.key.pem 2>/dev/null
chmod 600 root/private/root.key.pem
openssl req -new -x509 -key root/private/root.key.pem \
    -out root/root.cert.pem -days 3650 \
    -subj "/CN=Mere Mortals Root CA/O=Example Lab" \
    -config ca.cnf -extensions v3_root_ca

# --- Intermediate CA: the root signs this one ---------------------
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out inter/private/inter.key.pem 2>/dev/null
chmod 600 inter/private/inter.key.pem
openssl req -new -key inter/private/inter.key.pem \
    -out inter.csr.pem \
    -subj "/CN=Mere Mortals Intermediate CA/O=Example Lab"
openssl ca -config ca.cnf -name CA_root -extensions v3_inter_ca \
    -in inter.csr.pem -out inter/inter.cert.pem -batch -notext

# --- The server certificate ---------------------------------------
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out server.key.pem 2>/dev/null
openssl req -new -key server.key.pem -out server.csr.pem \
    -subj "/CN=server.example.test/O=Example Lab"
openssl ca -config ca.cnf -extensions v3_server \
    -in server.csr.pem -out server.cert.pem -batch -notext

# --- Specimens for the troubleshooting chapter ------------------
# An expired twin of the server certificate (valid during 2024).
openssl ca -config ca.cnf -extensions v3_expired \
    -startdate 20240101000000Z -enddate 20250101000000Z \
    -in server.csr.pem -out expired.cert.pem -batch -notext

# A perfectly valid certificate -- for a different name.
openssl req -new -key server.key.pem -out wronghost.csr.pem \
    -subj "/CN=other.example.test/O=Example Lab"
openssl ca -config ca.cnf -extensions v3_wronghost \
    -in wronghost.csr.pem -out wronghost.cert.pem -batch -notext

# A self-signed certificate for the same server name.
openssl req -x509 -newkey rsa:2048 \
    -keyout selfsigned.key.pem -out selfsigned.cert.pem \
    -days 365 -nodes -subj "/CN=server.example.test" \
    -addext "subjectAltName=DNS:server.example.test,IP:127.0.0.1" \
    2>/dev/null

# --- Bundles and exports ------------------------------------------
cat inter/inter.cert.pem root/root.cert.pem > chain.pem
cat server.cert.pem inter/inter.cert.pem > server-chain.pem
openssl x509 -in server.cert.pem -out server.cert.der -outform DER
openssl pkcs12 -export -name "Example Server" \
    -inkey server.key.pem -in server.cert.pem -certfile chain.pem \
    -out server.p12 -passout pass:correct-horse

echo
echo "Lab built. Start with:"
echo "  openssl verify -CAfile root/root.cert.pem \\"
echo "      -untrusted inter/inter.cert.pem server.cert.pem"
