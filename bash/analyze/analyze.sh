#!/bin/bash
cd ~/bin/analyze
for x in *.msg; do
  d="${x%.*}"
  mkdir "$d"
  pushd "$d"
  mkdir emaildir
  mkdir -p analysisdir/attachmentdir
  mkdir reportdir
  popd
  casedir=~/"bin/analyze/$d"
  emaildir="$casedir/emaildir"
  analysisdir="$casedir/analysisdir"
  attachmentdir="$analysisdir/attachmentdir"
  reportdir="$casedir/reportdir"
  cp "$x" "$emaildir"
  msgconvert "$emaildir/$x" --outfile "$emaildir/$d.eml"
  cp "$emaildir/$d.eml" "$attachmentdir"
  munpack -C "$attachmentdir" "$attachmentdir/$d.eml"
  cd "$attachmentdir"
  rm "$attachmentdir/$d.eml"
  mv part1 "$analysisdir/$d (RTF).rtf"
  mv part1.desc "$analysisdir/$d.txt"
  cd "$analysisdir"
  find . -type f -exec sha256sum "{}" + > "$d hash values.txt"
  mv "$d hash values.txt" "$reportdir/$d hash values.txt"
done
