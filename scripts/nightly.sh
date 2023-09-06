crystal build src/main.cr -o crimson
sha256sum crimson > checksums.txt
tar -zcf crimson-nightly-linux-x86_64.tar.gz crimson checksums.txt

# gh release delete nightly -y || true
gh release create nightly -dpt nightly
gh release upload nightly crimson-nightly-linux-x86_64.tar.gz

rm crimson checksums.txt crimson-nightly-linux-x86_64.tar.gz
