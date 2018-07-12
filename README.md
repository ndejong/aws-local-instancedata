# AWS local-instancedata

This tool is a simple `/bin/sh` tool that uses `curl` (*nix) or `fetch` (BSD) to walk the AWS instancedata 
from http://169.254.169.254 and create a local copy of that data.

The AWS instancedata end-point at http://169.254.169.254 provides your instance various meta-data and 
user-data that assists the instance to spin-up, configure itself and operate.  Obtaining this data via 
this transport mechanism is great unless you are operating an edge case (perhaps unusual) scenario 
that (a) restricts access to the reserved local-net 169.254.0.0/16 netblock, or (b) requests data from 
this endpoint quick enough that [AWS throttle](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html#instancedata-data-retrieval) 
those requests which can leave you with null/empty response data making the scripts and tooling that 
relies on this data to behave inconsistently or unpredictably.

The code is wrapped in an outer `aws_local_instancedata` function with local variables inside making 
the whole thing easy to cut-n-paste into your user-data startup scripts.  The examples below show the 
code being imported via a standard `.` import mechanism

NB: this is `/bin/sh` not `/bin/bash` or some other shell.

**Example** - using defaults, a full copy of the latest instancedata will be saved at 
the `/var/lib/cloud/instance/instance-data` path:-
```bash
#/bin/sh 
. aws-local-instancedata.sh
aws_local_instancedata
```

**Example** - writing the instancedata to an alternative `/tmp/instancedata` path:-
```bash
#/bin/sh 
. aws-local-instancedata.sh
aws_local_instancedata /tmp/instancedata
```

**Example** - only create a local copy of the instance meta-data and write to an 
alternative `/tmp/meta-data` path - NB: the second `/user-data/` parameter with 
forward-slash at beginning and end:-
```bash
#/bin/sh 
. aws-local-instancedata.sh
aws_local_instancedata /tmp/meta-data /meta-data/
```

This toolchain helpful when bootstrapping firewall instances in AWS because network traffic rules with 
firewall instances can (rightly or wrongly) have opinionated rules and filters that prevent access to 
the local-net 169.254.0.0/16 address space.

#### Warning
Depending on the deployment arrangement, the instancedata may contain sensitive data, you need to consider
if this is appropriate for your use case and manage accordingly.

## Authors
This code is managed by [Verb Networks](https://github.com/verbnetworks).

## License
Apache 2 Licensed. See LICENSE file for full details.
