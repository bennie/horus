#!/bin/sh
find . -type f | grep -v CVS | grep -v sums.txt | grep -v resum.sh | xargs md5sum | sed -e 's/\.\///' > sums.txt
