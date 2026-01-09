#!/usr/bin/env bash
set -euo pipefail

#get_latest_release() {
#  API="https://api.github.com/repos/$1/releases/latest"
#  echo "GitHub API ==> ${API}\n"
#  curl --silent $API | # Get latest release from GitHub api
#    grep '"tag_name":' |                                            # Get tag line
#    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
#}

get_latest_release() {
  API="https://api.github.com/repos/$1/releases/latest"

  # Try to use GitHub token from environment variable if available
  if [[ -n "${GH_TOKEN:-}" ]]; then
    response=$(curl --silent --fail -H "Authorization: token $GH_TOKEN" "$API") || {
      echo "Error: Failed to fetch GitHub API for '$1' with authentication" >&2
      return 1
    }
  else
    # Fall back to unauthenticated request
    response=$(curl --silent --fail "$API") || {
      echo "Error: Failed to fetch GitHub API for '$1' without authentication" >&2
      return 1
    }
  fi

  if command -v jq >/dev/null; then
    echo "$response" | jq -r '.tag_name'
  else
  	curl --silent $API | # Get latest release from GitHub api
	grep '"tag_name":' |                                            # Get tag line
	sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
  fi
}


ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH=amd64
        ;;
    aarch64)
        ARCH=arm64
        ;;
esac

get_ctop() {
  VERSION=$(get_latest_release bcicen/ctop | sed -e 's/^v//')
  LINK="https://github.com/bcicen/ctop/releases/download/v${VERSION}/ctop-${VERSION}-linux-${ARCH}"
  wget "$LINK" -O /tmp/ctop && chmod +x /tmp/ctop
}

get_calicoctl() {
  VERSION=$(get_latest_release projectcalico/calico)
  LINK="https://github.com/projectcalico/calico/releases/download/${VERSION}/calicoctl-linux-${ARCH}"
  wget "$LINK" -O /tmp/calicoctl && chmod +x /tmp/calicoctl
}

get_termshark() {
  case "$ARCH" in
    *)
      VERSION=$(get_latest_release gcla/termshark | sed -e 's/^v//')
      if [ "$ARCH" == "amd64" ]; then
        TERM_ARCH=x64
      else
        TERM_ARCH="$ARCH"
      fi
      LINK="https://github.com/gcla/termshark/releases/download/v${VERSION}/termshark_${VERSION}_linux_${TERM_ARCH}.tar.gz"
      wget "$LINK" -O /tmp/termshark.tar.gz && \
      tar -zxvf /tmp/termshark.tar.gz && \
      mv "termshark_${VERSION}_linux_${TERM_ARCH}/termshark" /tmp/termshark && \
      chmod +x /tmp/termshark
      ;;
  esac
}

get_grpcurl() {
  if [ "$ARCH" == "amd64" ]; then
    TERM_ARCH=x86_64
  else
    TERM_ARCH="$ARCH"
  fi
  VERSION=$(get_latest_release fullstorydev/grpcurl | sed -e 's/^v//')
  LINK="https://github.com/fullstorydev/grpcurl/releases/download/v${VERSION}/grpcurl_${VERSION}_linux_${TERM_ARCH}.tar.gz"
  wget "$LINK" -O /tmp/grpcurl.tar.gz  && \
  tar --no-same-owner -zxvf /tmp/grpcurl.tar.gz && \
  mv "grpcurl" /tmp/grpcurl && \
  chmod +x /tmp/grpcurl && \
  chown root:root /tmp/grpcurl
}

get_fortio() {
  if [ "$ARCH" == "amd64" ]; then
    TERM_ARCH=x86_64
  else
    TERM_ARCH="$ARCH"
  fi
  VERSION=$(get_latest_release fortio/fortio | sed -e 's/^v//')
  LINK="https://github.com/fortio/fortio/releases/download/v${VERSION}/fortio-linux_${ARCH}-${VERSION}.tgz"
  wget "$LINK" -O /tmp/fortio.tgz  && \
  tar -zxvf /tmp/fortio.tgz && \
  mv "usr/bin/fortio" /tmp/fortio && \
  chmod +x /tmp/fortio
}

get_witr() {
  VERSION=$(get_latest_release pranshuparmar/witr)
  LINK="https://github.com/pranshuparmar/witr/releases/download/${VERSION}/witr-linux-${ARCH}"
  wget "$LINK" -O /tmp/witr && chmod +x /tmp/witr
}


get_websocat() {
  VERSION=$(get_latest_release vi/websocat)
  LINK="https://github.com/vi/websocat/releases/download/${VERSION}/websocat.x86_64-unknown-linux-musl"
  wget "$LINK" -O /tmp/websocat && chmod +x /tmp/websocat
}


if ! get_fortio; then
	echo "get_fortio failed, but script continues"
fi

if ! get_ctop; then
	echo "get_ctop failed, but script continues"
fi
if ! get_calicoctl; then
	echo "get_calicoctl failed, but script continues"
fi
if ! get_termshark; then
	echo "get_termshark failed, but script continues"
fi
if ! get_grpcurl; then
	echo "get_grpcurl failed, but script continues"
fi

if ! get_witr; then
	echo "get_witr failed, but script continues"
fi

if ! get_websocat; then
	echo "get_websocat failed, but script continues"
fi
