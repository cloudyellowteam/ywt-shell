# trivy --help
Usage:
  trivy [global flags] command [flags] target
  trivy [command]

Examples:
  ## Scan a container image
  $ trivy image python:3.4-alpine

  ## Scan a container image from a tar archive
  $ trivy image --input ruby-3.1.tar

  ## Scan local filesystem
  $ trivy fs .

  ## Run in server mode
  $ trivy server

Scanning Commands
  aws         [EXPERIMENTAL] Scan AWS account
  config      Scan config files for misconfigurations
  filesystem  Scan local filesystem
  image       Scan a container image
  kubernetes  [EXPERIMENTAL] Scan kubernetes cluster
  repository  Scan a repository
  rootfs      Scan rootfs
  sbom        Scan SBOM for vulnerabilities and licenses
  vm          [EXPERIMENTAL] Scan a virtual machine image

Management Commands
  module      Manage modules
  plugin      Manage plugins

Utility Commands
  completion  Generate the autocompletion script for the specified shell
  convert     Convert Trivy JSON report into a different format
  help        Help about any command
  server      Server mode
  version     Print the version

Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
  -f, --format string             version format (json)
      --generate-default-config   write the default config to trivy-default.yaml
  -h, --help                      help for trivy
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version

Use "trivy [command] --help" for more information about a command.

## trivy aws --help
Scan an AWS account for misconfigurations. Trivy uses the same authentication methods as the AWS CLI. See https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html

The following services are supported:

- accessanalyzer
- api-gateway
- athena
- cloudfront
- cloudtrail
- cloudwatch
- codebuild
- documentdb
- dynamodb
- ec2
- ecr
- ecs
- efs
- eks
- elasticache
- elasticsearch
- elb
- emr
- iam
- kinesis
- kms
- lambda
- mq
- msk
- neptune
- rds
- redshift
- s3
- sns
- sqs
- ssm
- workspaces

Usage:
  trivy aws [flags]

Examples:
  ### basic scanning
  $ trivy aws --region us-east-1

  ### limit scan to a single service:
  $ trivy aws --region us-east-1 --service s3

  ### limit scan to multiple services:
  $ trivy aws --region us-east-1 --service s3 --service ec2

  ### force refresh of cache for fresh results
  $ trivy aws --region us-east-1 --update-cache


Report Flags
      --compliance string          compliance report to generate (aws-cis-1.2,aws-cis-1.4)
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
      --report string              specify a report format for the output (all,summary) (default "all")
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
  -t, --template string            output template

Misconfiguration Flags
      --cf-params strings                 specify paths to override the CloudFormation parameters files
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules
      --tf-vars strings                   specify paths to override the Terraform tfvars files

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Cloud Flags
      --max-cache-age duration   The maximum age of the cloud cache. Cached data will be requeried from the cloud provider if it is older than this. (default 24h0m0s)
      --update-cache             Update the cache for the applicable cloud provider instead of using cached results.

AWS Flags
      --account string         The AWS account to scan. It's useful to specify this when reviewing cached results for multiple accounts.
      --arn string             The AWS ARN to show results for. Useful to filter results once a scan is cached.
      --endpoint string        AWS Endpoint override
      --region string          AWS Region to scan
      --service strings        Only scan AWS Service(s) specified with this flag. Can specify multiple services using --service A --service B etc.
      --skip-service strings   Skip selected AWS Service(s) specified with this flag. Can specify multiple services using --skip-service A --skip-service B etc.

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version


## trivy config --help
Scan config files for misconfigurations

Usage:
  trivy config [flags] DIR

Aliases:
  config, conf

Scan Flags
      --file-patterns strings   specify config file patterns
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --compliance string          compliance report to generate
      --exit-code int              specify exit code when any security issues are found
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
      --report string              specify a compliance report format for the output (all,summary) (default "all")
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

Registry Flags
      --password strings        password. Comma-separated passwords allowed. TRIVY_PASSWORD should be used for security reasons.
      --registry-token string   registry token
      --username strings        username. Comma-separated usernames allowed.

Misconfiguration Flags
      --cf-params strings                 specify paths to override the CloudFormation parameters files
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules
      --tf-vars strings                   specify paths to override the Terraform tfvars files

Module Flags
      --enable-modules strings   [EXPERIMENTAL] module names to enable
      --module-dir string        specify directory to the wasm modules that will be loaded (default "/root/.trivy/modules")

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Kubernetes Flags
      --k8s-version string   specify k8s version to validate outdated api by it (example: 1.21.0)

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version



## trivy filesystem --help
Scan local filesystem

Usage:
  trivy filesystem [flags] PATH

Aliases:
  filesystem, fs

Examples:
  ### Scan a local project including language-specific files
  $ trivy fs /path/to/your_project

  ### Scan a single file
  $ trivy fs ./trivy-ci-test/Pipfile.lock

Scan Flags
      --file-patterns strings   specify config file patterns
      --include-dev-deps        include development dependencies in the report (supported: npm, yarn)
      --offline-scan            do not issue API requests to identify dependencies
      --parallel int            number of goroutines enabled for parallel scanning, set 0 to auto-detect parallelism (default 5)
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,misconfig,secret,license) (default [vuln,secret])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --compliance string          compliance report to generate
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
      --report string              specify a compliance report format for the output (all,summary) (default "all")
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Registry Flags
      --password strings        password. Comma-separated passwords allowed. TRIVY_PASSWORD should be used for security reasons.
      --registry-token string   registry token
      --username strings        username. Comma-separated usernames allowed.

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

Misconfiguration Flags
      --cf-params strings                 specify paths to override the CloudFormation parameters files
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules
      --tf-vars strings                   specify paths to override the Terraform tfvars files

Module Flags
      --enable-modules strings   [EXPERIMENTAL] module names to enable
      --module-dir string        specify directory to the wasm modules that will be loaded (default "/root/.trivy/modules")

Secret Flags
      --secret-config string   specify a path to config file for secret scanning (default "trivy-secret.yaml")

License Flags
      --ignored-licenses strings         specify a list of license to ignore
      --license-confidence-level float   specify license classifier's confidence level (default 0.9)
      --license-full                     eagerly look for licenses in source code headers and license files

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Client/Server Flags
      --custom-headers strings   custom headers in client mode
      --server string            server address in client mode
      --token string             for authentication in client/server mode
      --token-header string      specify a header name for token in client/server mode (default "Trivy-Token")

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version
## trivy image --help
Scan a container image

Usage:
  trivy image [flags] IMAGE_NAME

Aliases:
  image, i

Examples:
  ### Scan a container image
  $ trivy image python:3.4-alpine

  ### Scan a container image from a tar archive
  $ trivy image --input ruby-3.1.tar

  ### Filter by severities
  $ trivy image --severity HIGH,CRITICAL alpine:3.15

  ### Ignore unfixed/unpatched vulnerabilities
  $ trivy image --ignore-unfixed alpine:3.15

  ### Scan a container image in client mode
  $ trivy image --server http://127.0.0.1:4954 alpine:latest

  ### Generate json result
  $ trivy image --format json --output result.json alpine:3.15

  ### Generate a report in the CycloneDX format
  $ trivy image --format cyclonedx --output result.cdx alpine:3.15

Scan Flags
      --file-patterns strings   specify config file patterns
      --offline-scan            do not issue API requests to identify dependencies
      --parallel int            number of goroutines enabled for parallel scanning, set 0 to auto-detect parallelism (default 5)
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,misconfig,secret,license) (default [vuln,secret])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --compliance string          compliance report to generate (docker-cis)
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
      --exit-on-eol int            exit with the specified code when the OS reaches end of service/life
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
      --report string              specify a format for the compliance report. (all,summary) (default "summary")
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Registry Flags
      --password strings        password. Comma-separated passwords allowed. TRIVY_PASSWORD should be used for security reasons.
      --registry-token string   registry token
      --username strings        username. Comma-separated usernames allowed.

Image Flags
      --docker-host string              unix domain socket path to use for docker scanning
      --image-config-scanners strings   comma-separated list of what security issues to detect on container image configurations (misconfig,secret)
      --image-src strings               image source(s) to use, in priority order (docker,containerd,podman,remote) (default [docker,containerd,podman,remote])
      --input string                    input file path instead of image name
      --platform string                 set platform in the form os/arch if image is multi-platform capable
      --podman-host string              unix podman socket path to use for podman scanning
      --removed-pkgs                    detect vulnerabilities of removed packages (only for Alpine)

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

Misconfiguration Flags
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules

Module Flags
      --enable-modules strings   [EXPERIMENTAL] module names to enable
      --module-dir string        specify directory to the wasm modules that will be loaded (default "/root/.trivy/modules")

Secret Flags
      --secret-config string   specify a path to config file for secret scanning (default "trivy-secret.yaml")

License Flags
      --ignored-licenses strings         specify a list of license to ignore
      --license-confidence-level float   specify license classifier's confidence level (default 0.9)
      --license-full                     eagerly look for licenses in source code headers and license files

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Client/Server Flags
      --custom-headers strings   custom headers in client mode
      --server string            server address in client mode
      --token string             for authentication in client/server mode
      --token-header string      specify a header name for token in client/server mode (default "Trivy-Token")

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version

## trivy kubernetes --help
[EXPERIMENTAL] Scan kubernetes cluster

Usage:
  trivy kubernetes [flags] { cluster | all | specific resources like kubectl. eg: pods, pod/NAME }

Aliases:
  kubernetes, k8s

Examples:
  ### cluster scanning
  $ trivy k8s --report summary cluster

  ### namespace scanning:
  $ trivy k8s -n kube-system --report summary all

  ### resources scanning:
  $ trivy k8s --report=summary deploy
  $ trivy k8s --namespace=kube-system --report=summary deploy,configmaps

  ### resource scanning:
  $ trivy k8s deployment/orion


Scan Flags
      --file-patterns strings   specify config file patterns
      --offline-scan            do not issue API requests to identify dependencies
      --parallel int            number of goroutines enabled for parallel scanning, set 0 to auto-detect parallelism (default 5)
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,misconfig,secret,rbac) (default [vuln,misconfig,secret,rbac])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --compliance string          compliance report to generate (k8s-nsa,k8s-cis,k8s-pss-baseline,k8s-pss-restricted)
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
  -f, --format string              format (table,json,cyclonedx) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
      --report string              specify a report format for the output (all,summary) (default "all")
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Registry Flags
      --password strings        password. Comma-separated passwords allowed. TRIVY_PASSWORD should be used for security reasons.
      --registry-token string   registry token
      --username strings        username. Comma-separated usernames allowed.

Image Flags
      --image-src strings   image source(s) to use, in priority order (docker,containerd,podman,remote) (default [docker,containerd,podman,remote])

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

Misconfiguration Flags
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules

Secret Flags
      --secret-config string   specify a path to config file for secret scanning (default "trivy-secret.yaml")

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Kubernetes Flags
  -A, --all-namespaces                    fetch resources from all cluster namespaces
      --burst int                         specify the maximum burst for throttle (default 10)
      --components strings                specify which components to scan (workload,infra) (default [workload,infra])
      --context string                    specify a context to scan
      --exclude-nodes strings             indicate the node labels that the node-collector job should exclude from scanning (example: kubernetes.io/arch:arm64,team:dev)
      --exclude-owned                     exclude resources that have an owner reference
      --k8s-version string                specify k8s version to validate outdated api by it (example: 1.21.0)
      --kubeconfig string                 specify the kubeconfig file path to use
  -n, --namespace string                  specify a namespace to scan
      --node-collector-imageref string    indicate the image reference for the node-collector scan job (default "ghcr.io/aquasecurity/node-collector:0.0.9")
      --node-collector-namespace string   specify the namespace in which the node-collector job should be deployed (default "trivy-temp")
      --qps float                         specify the maximum QPS to the master from this client (default 5)
      --tolerations strings               specify node-collector job tolerations (example: key1=value1:NoExecute,key2=value2:NoSchedule)

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version

## trivy repository --help
Scan a repository

Usage:
  trivy repository [flags] (REPO_PATH | REPO_URL)

Aliases:
  repository, repo

Examples:
  ### Scan your remote git repository
  $ trivy repo https://github.com/knqyf263/trivy-ci-test
  ### Scan your local git repository
  $ trivy repo /path/to/your/repository

Scan Flags
      --file-patterns strings   specify config file patterns
      --include-dev-deps        include development dependencies in the report (supported: npm, yarn)
      --offline-scan            do not issue API requests to identify dependencies
      --parallel int            number of goroutines enabled for parallel scanning, set 0 to auto-detect parallelism (default 5)
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,misconfig,secret,license) (default [vuln,secret])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Registry Flags
      --password strings        password. Comma-separated passwords allowed. TRIVY_PASSWORD should be used for security reasons.
      --registry-token string   registry token
      --username strings        username. Comma-separated usernames allowed.

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

Misconfiguration Flags
      --cf-params strings                 specify paths to override the CloudFormation parameters files
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules
      --tf-vars strings                   specify paths to override the Terraform tfvars files

Module Flags
      --enable-modules strings   [EXPERIMENTAL] module names to enable
      --module-dir string        specify directory to the wasm modules that will be loaded (default "/root/.trivy/modules")

Secret Flags
      --secret-config string   specify a path to config file for secret scanning (default "trivy-secret.yaml")

License Flags
      --ignored-licenses strings         specify a list of license to ignore
      --license-confidence-level float   specify license classifier's confidence level (default 0.9)
      --license-full                     eagerly look for licenses in source code headers and license files

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Client/Server Flags
      --custom-headers strings   custom headers in client mode
      --server string            server address in client mode
      --token string             for authentication in client/server mode
      --token-header string      specify a header name for token in client/server mode (default "Trivy-Token")

Repository Flags
      --branch string   pass the branch name to be scanned
      --commit string   pass the commit hash to be scanned
      --tag string      pass the tag name to be scanned

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version

## trivy rootfs --help
Scan rootfs

Usage:
  trivy rootfs [flags] ROOTDIR

Examples:
  ### Scan unpacked filesystem
  $ docker export $(docker create alpine:3.10.2) | tar -C /tmp/rootfs -xvf -
  $ trivy rootfs /tmp/rootfs

  ### Scan from inside a container
  $ docker run --rm -it alpine:3.11
  / # curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
  / # trivy rootfs /

Scan Flags
      --file-patterns strings   specify config file patterns
      --offline-scan            do not issue API requests to identify dependencies
      --parallel int            number of goroutines enabled for parallel scanning, set 0 to auto-detect parallelism (default 5)
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,misconfig,secret,license) (default [vuln,secret])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
      --exit-on-eol int            exit with the specified code when the OS reaches end of service/life
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Registry Flags
      --password strings        password. Comma-separated passwords allowed. TRIVY_PASSWORD should be used for security reasons.
      --registry-token string   registry token
      --username strings        username. Comma-separated usernames allowed.

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

Misconfiguration Flags
      --cf-params strings                 specify paths to override the CloudFormation parameters files
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules
      --tf-vars strings                   specify paths to override the Terraform tfvars files

Module Flags
      --enable-modules strings   [EXPERIMENTAL] module names to enable
      --module-dir string        specify directory to the wasm modules that will be loaded (default "/root/.trivy/modules")

Secret Flags
      --secret-config string   specify a path to config file for secret scanning (default "trivy-secret.yaml")

License Flags
      --ignored-licenses strings         specify a list of license to ignore
      --license-confidence-level float   specify license classifier's confidence level (default 0.9)
      --license-full                     eagerly look for licenses in source code headers and license files

Rego Flags
      --config-data strings         specify paths from which data for the Rego policies will be recursively loaded
      --config-policy strings       specify the paths to the Rego policy files or to the directories containing them, applying config files
      --policy-namespaces strings   Rego namespaces
      --skip-policy-update          skip fetching rego policy updates
      --trace                       enable more verbose trace output for custom queries

Client/Server Flags
      --custom-headers strings   custom headers in client mode
      --server string            server address in client mode
      --token string             for authentication in client/server mode
      --token-header string      specify a header name for token in client/server mode (default "Trivy-Token")

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version

## trivy sbom --help
Scan SBOM for vulnerabilities and licenses

Usage:
  trivy sbom [flags] SBOM_PATH

Examples:
  ### Scan CycloneDX and show the result in tables
  $ trivy sbom /path/to/report.cdx

  ### Scan CycloneDX-type attestation and show the result in tables
  $ trivy sbom /path/to/report.cdx.intoto.jsonl


Scan Flags
      --file-patterns strings   specify config file patterns
      --offline-scan            do not issue API requests to identify dependencies
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,license) (default [vuln])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --compliance string          compliance report to generate
      --exit-code int              specify exit code when any security issues are found
      --exit-on-eol int            exit with the specified code when the OS reaches end of service/life
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

License Flags
      --ignored-licenses strings   specify a list of license to ignore

Client/Server Flags
      --custom-headers strings   custom headers in client mode
      --server string            server address in client mode
      --token string             for authentication in client/server mode
      --token-header string      specify a header name for token in client/server mode (default "Trivy-Token")

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version

## trivy vm --help
[EXPERIMENTAL] Scan a virtual machine image

Usage:
  trivy vm [flags] VM_IMAGE

Examples:
  ### Scan your AWS AMI
  $ trivy vm --scanners vuln ami:${your_ami_id}

  ### Scan your AWS EBS snapshot
  $ trivy vm ebs:${your_ebs_snapshot_id}


Scan Flags
      --file-patterns strings   specify config file patterns
      --offline-scan            do not issue API requests to identify dependencies
      --parallel int            number of goroutines enabled for parallel scanning, set 0 to auto-detect parallelism (default 5)
      --rekor-url string        [EXPERIMENTAL] address of rekor STL server (default "https://rekor.sigstore.dev")
      --sbom-sources strings    [EXPERIMENTAL] try to retrieve SBOM from the specified sources (oci,rekor)
      --scanners strings        comma-separated list of what security issues to detect (vuln,misconfig,secret,license) (default [vuln,secret])
      --skip-dirs strings       specify the directories or glob patterns to skip
      --skip-files strings      specify the files or glob patterns to skip

Report Flags
      --compliance string          compliance report to generate
      --dependency-tree            [EXPERIMENTAL] show dependency origin tree of vulnerable packages
      --exit-code int              specify exit code when any security issues are found
      --exit-on-eol int            exit with the specified code when the OS reaches end of service/life
  -f, --format string              format (table,json,template,sarif,cyclonedx,spdx,spdx-json,github,cosign-vuln) (default "table")
      --ignore-policy string       specify the Rego file path to evaluate each vulnerability
      --ignorefile string          specify .trivyignore file (default ".trivyignore")
      --list-all-pkgs              enabling the option will output all packages regardless of vulnerability
  -o, --output string              output file name
      --output-plugin-arg string   [EXPERIMENTAL] output plugin arguments
  -s, --severity strings           severities of security issues to be displayed (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL) (default [UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL])
      --show-suppressed            [EXPERIMENTAL] show suppressed vulnerabilities
  -t, --template string            output template

Cache Flags
      --cache-backend string   cache backend (e.g. redis://localhost:6379) (default "fs")
      --cache-ttl duration     cache TTL when using redis as cache backend
      --clear-cache            clear image caches without scanning
      --redis-ca string        redis ca file location, if using redis as cache backend
      --redis-cert string      redis certificate file location, if using redis as cache backend
      --redis-key string       redis key file location, if using redis as cache backend
      --redis-tls              enable redis TLS with public certificates, if using redis as cache backend

DB Flags
      --db-repository string        OCI repository to retrieve trivy-db from (default "ghcr.io/aquasecurity/trivy-db:2")
      --download-db-only            download/update vulnerability database but don't run a scan
      --download-java-db-only       download/update Java index database but don't run a scan
      --java-db-repository string   OCI repository to retrieve trivy-java-db from (default "ghcr.io/aquasecurity/trivy-java-db:1")
      --no-progress                 suppress progress bar
      --reset                       remove all caches and database
      --skip-db-update              skip updating vulnerability database
      --skip-java-db-update         skip updating Java index database

Vulnerability Flags
      --ignore-status strings   comma-separated list of vulnerability status to ignore (unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life)
      --ignore-unfixed          display only fixed vulnerabilities
      --vex string              [EXPERIMENTAL] file path to VEX
      --vuln-type strings       comma-separated list of vulnerability types (os,library) (default [os,library])

Misconfiguration Flags
      --helm-set strings                  specify Helm values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-set-file strings             specify Helm values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --helm-set-string strings           specify Helm string values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --helm-values strings               specify paths to override the Helm values.yaml files
      --include-non-failures              include successes and exceptions, available with '--scanners misconfig'
      --misconfig-scanners strings        comma-separated list of misconfig scanners to use for misconfiguration scanning (default [azure-arm,cloudformation,dockerfile,helm,kubernetes,terraform,terraformplan-json,terraformplan-snapshot])
      --policy-bundle-repository string   OCI registry URL to retrieve policy bundle from (default "ghcr.io/aquasecurity/trivy-policies:0")
      --reset-policy-bundle               remove policy bundle
      --tf-exclude-downloaded-modules     exclude misconfigurations for downloaded terraform modules

Module Flags
      --enable-modules strings   [EXPERIMENTAL] module names to enable
      --module-dir string        specify directory to the wasm modules that will be loaded (default "/root/.trivy/modules")

Secret Flags
      --secret-config string   specify a path to config file for secret scanning (default "trivy-secret.yaml")

AWS Flags
      --aws-region string   AWS region to scan

Client/Server Flags
      --custom-headers strings   custom headers in client mode
      --server string            server address in client mode
      --token string             for authentication in client/server mode
      --token-header string      specify a header name for token in client/server mode (default "Trivy-Token")

Global Flags:
      --cache-dir string          cache directory (default "/root/.cache/trivy")
  -c, --config string             config path (default "trivy.yaml")
  -d, --debug                     debug mode
      --generate-default-config   write the default config to trivy-default.yaml
      --insecure                  allow insecure server connections
  -q, --quiet                     suppress progress bar and log output
      --timeout duration          timeout (default 5m0s)
  -v, --version                   show version