#!/bin/bash

set -euxo pipefail

echo '#!/bin/sh' > /entrypoint.sh
echo "exec cargo +$RUST_VERSION \"\$@\"" >> /entrypoint.sh

chmod +x /entrypoint.sh
