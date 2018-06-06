#!/bin/bash
#
# attach-eip.sh by <ebo@>
#
# This script attaches an EIP to an EC2 instance.
#
# If no 'instance-id' parameter is specified on then the id of the running EC2 instance will be used.
#
# Usage:
# sudo ./attach-eip.sh <EIP> [instance-id]

set -ueo pipefail

readonly __progname="$(basename "$0")"

errx() {
	echo -e "${__progname}: $*" >&2

	exit 1
}

main() {
	[ "${EUID}" -ne 0 ] && \
		errx "need root"

	for bin in curl aws; do
		which "${bin}" >/dev/null 2>&1 || \
			errx "cannot find '${bin}' in 'PATH=${PATH}'"
	done

	local -r metadataurl="http://169.254.169.254/latest"

	curl -s -m 1 "${metadataurl}" || \
		errx "this script needs to be executed on an Amazon EC2 instance"

	local -r region=$(curl -s "${metadataurl}/dynamic/instance-identity/document" | \
		awk '/region/ { print $3 }' | \
		cut -d '"' -f 2)

	if [[ "$#" -ge 2 ]]; then
		local -r instanceid="$1"
	else
		local -r instanceid=$(curl -s "${metadataurl}/meta-data/instance-id")
	fi

	aws ec2 associate-address \
		--instance-id "${instanceid}" \
		--allocation-id "${eip}" \
		--region "${region}" || \
			errx "aws ec2 associate-address '${eip}' to instance '${instanceid}' failed"

	echo "attached '${eip}' to '${instance_id}'"

	return 0
}

main "$@"

exit $?
