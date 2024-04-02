usage: TruffleHog [<flags>] <command> [<args> ...]
TruffleHog is a tool for finding credentials.
Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
Commands:
## help [<command>...]
    Show help.
## git [<flags>] <uri>
usage: TruffleHog git [<flags>] <uri>
Find credentials in git repositories.


### Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
  -i, --include-paths=INCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to include in scan.
  -x, --exclude-paths=EXCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to exclude in scan.
      --exclude-globs=EXCLUDE-GLOBS  
                                 Comma separated list of globs to exclude in scan. This option filters at the `git log` level, resulting in faster
                                 scans.
      --since-commit=SINCE-COMMIT  
                                 Commit to start scan from.
      --branch=BRANCH            Branch to scan.
      --max-depth=MAX-DEPTH      Maximum depth of commits to scan.
      --[no-]bare                Scan bare repository (e.g. useful while using in pre-receive hooks)
      --[no-]allow               No-op flag for backwards compat.
      --[no-]entropy             No-op flag for backwards compat.
      --[no-]regex               No-op flag for backwards compat.

Args:
  <uri>  Git repository URL. https://, file://, or ssh:// schema expected.

## github [<flags>]
usage: TruffleHog github [<flags>]

Find credentials in GitHub repositories.


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --endpoint="https://api.github.com"  
                                 GitHub endpoint.
      --repo=REPO ...            GitHub repository to scan. You can repeat this flag. Example: "https://github.com/dustin-decker/secretsandstuff"
      --org=ORG ...              GitHub organization to scan. You can repeat this flag. Example: "trufflesecurity"
      --token=TOKEN              GitHub token. Can be provided with environment variable GITHUB_TOKEN. ($GITHUB_TOKEN)
      --[no-]include-forks       Include forks in scan.
      --[no-]include-members     Include organization member repositories in scan.
      --include-repos=INCLUDE-REPOS ...  
                                 Repositories to include in an org scan. This can also be a glob pattern. You can repeat this flag. Must use
                                 Github repo full name. Example: "trufflesecurity/trufflehog", "trufflesecurity/t*"
      --[no-]include-wikis       Include repository wikisin scan.
      --exclude-repos=EXCLUDE-REPOS ...  
                                 Repositories to exclude in an org scan. This can also be a glob pattern. You can repeat this flag. Must use
                                 Github repo full name. Example: "trufflesecurity/driftwood", "trufflesecurity/d*"
  -i, --include-paths=INCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to include in scan.
  -x, --exclude-paths=EXCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to exclude in scan.
      --[no-]issue-comments      Include issue descriptions and comments in scan.
      --[no-]pr-comments         Include pull request descriptions and comments in scan.
      --[no-]gist-comments       Include gist comments in scan.


## gitlab --token=TOKEN [<flags>]
usage: TruffleHog gitlab --token=TOKEN [<flags>]

Find credentials in GitLab repositories.


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --endpoint="https://gitlab.com"  
                                 GitLab endpoint.
      --repo=REPO ...            GitLab repo url. You can repeat this flag. Leave empty to scan all repos accessible with provided credential.
                                 Example: https://gitlab.com/org/repo.git
      --token=TOKEN              GitLab token. Can be provided with environment variable GITLAB_TOKEN. ($GITLAB_TOKEN)
  -i, --include-paths=INCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to include in scan.
  -x, --exclude-paths=EXCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to exclude in scan.

## filesystem [<flags>] [<path>...]
usage: TruffleHog filesystem [<flags>] [<path>...]

Find credentials in a filesystem.


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --directory=DIRECTORY ...  Path to directory to scan. You can repeat this flag.
  -i, --include-paths=INCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to include in scan.
  -x, --exclude-paths=EXCLUDE-PATHS  
                                 Path to file with newline separated regexes for files to exclude in scan.

Args:
  [<path>]  Path to file or directory to scan.

## s3 [<flags>]
usage: TruffleHog s3 [<flags>]

Find credentials in S3 buckets.


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --key=KEY                  S3 key used to authenticate. Can be provided with environment variable AWS_ACCESS_KEY_ID. ($AWS_ACCESS_KEY_ID)
      --role-arn=ROLE-ARN ...    Specify the ARN of an IAM role to assume for scanning. You can repeat this flag.
      --secret=SECRET            S3 secret used to authenticate. Can be provided with environment variable AWS_SECRET_ACCESS_KEY.
                                 ($AWS_SECRET_ACCESS_KEY)
      --session-token=SESSION-TOKEN  
                                 S3 session token used to authenticate temporary credentials. Can be provided with environment variable
                                 AWS_SESSION_TOKEN. ($AWS_SESSION_TOKEN)
      --[no-]cloud-environment   Use IAM credentials in cloud environment.
      --bucket=BUCKET ...        Name of S3 bucket to scan. You can repeat this flag. Incompatible with --ignore-bucket.
      --ignore-bucket=IGNORE-BUCKET ...  
                                 Name of S3 bucket to ignore. You can repeat this flag. Incompatible with --bucket.
      --max-object-size=250MB    Maximum size of objects to scan. Objects larger than this will be skipped. (Byte units eg. 512B, 2KB, 4MB)

## gcs [<flags>]
usage: TruffleHog gcs [<flags>]

Find credentials in GCS buckets.


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --project-id=PROJECT-ID    GCS project ID used to authenticate. Can NOT be used with unauth scan. Can be provided with environment variable
                                 GOOGLE_CLOUD_PROJECT. ($GOOGLE_CLOUD_PROJECT)
      --[no-]cloud-environment   Use Application Default Credentials, IAM credentials to authenticate.
      --service-account=SERVICE-ACCOUNT  
                                 Path to GCS service account JSON file.
      --[no-]without-auth        Scan GCS buckets without authentication. This will only work for public buckets
      --api-key=API-KEY          GCS API key used to authenticate. Can be provided with environment variable GOOGLE_API_KEY. ($GOOGLE_API_KEY)
  -I, --include-buckets=INCLUDE-BUCKETS ...  
                                 Buckets to scan. Comma separated list of buckets. You can repeat this flag. Globs are supported
  -X, --exclude-buckets=EXCLUDE-BUCKETS ...  
                                 Buckets to exclude from scan. Comma separated list of buckets. Globs are supported
  -i, --include-objects=INCLUDE-OBJECTS ...  
                                 Objects to scan. Comma separated list of objects. you can repeat this flag. Globs are supported
  -x, --exclude-objects=EXCLUDE-OBJECTS ...  
                                 Objects to exclude from scan. Comma separated list of objects. You can repeat this flag. Globs are supported
      --max-object-size=10MB     Maximum size of objects to scan. Objects larger than this will be skipped. (Byte units eg. 512B, 2KB, 4MB)

## syslog [<flags>]
usage: TruffleHog syslog [<flags>]

Scan syslog


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --address=ADDRESS          Address and port to listen on for syslog. Example: 127.0.0.1:514
      --protocol=PROTOCOL        Protocol to listen on. udp or tcp
      --cert=CERT                Path to TLS cert.
      --key=KEY                  Path to TLS key.
      --format=FORMAT            Log format. Can be rfc3164 or rfc5424

## circleci --token=TOKEN
usage: TruffleHog circleci --token=TOKEN

Scan CircleCI


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --token=TOKEN              CircleCI token. Can also be provided with environment variable ($CIRCLECI_TOKEN)

## docker --image=IMAGE
usage: TruffleHog docker --image=IMAGE

Scan Docker Image


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --image=IMAGE ...          Docker image to scan. Use the file:// prefix to point to a local tarball, otherwise a image registry is assumed.
travisci --token=TOKEN
usage: TruffleHog travisci --token=TOKEN

Scan TravisCI


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --token=TOKEN              TravisCI token. Can also be provided with environment variable ($TRAVISCI_TOKEN)

## postman [<flags>]
usage: TruffleHog postman [<flags>]

Scan Postman


Flags:
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]debug               Run in debug mode.
      --[no-]trace               Run in trace mode.
      --[no-]profile             Enables profiling and sets a pprof and fgprof server on :18066.
  -j, --[no-]json                Output in JSON format.
      --[no-]json-legacy         Use the pre-v3.0 JSON format. Only works with git, gitlab, and github sources.
      --[no-]github-actions      Output in GitHub Actions format.
      --concurrency=8            Number of concurrent workers.
      --[no-]no-verification     Don't verify the results.
      --[no-]only-verified       Only output verified results.
      --[no-]allow-verification-overlap  
                                 Allow verification of similar credentials across detectors
      --[no-]filter-unverified   Only output first unverified result per chunk per detector if there are more than one results.
      --filter-entropy=FILTER-ENTROPY  
                                 Filter unverified results with Shannon entropy. Start with 3.0.
      --config=CONFIG            Path to configuration file.
      --[no-]print-avg-detector-time  
                                 Print the average time spent on each detector.
      --[no-]no-update           Don't check for updates.
      --[no-]fail                Exit with code 183 if results are found.
      --verifier=VERIFIER ...    Set custom verification endpoints.
      --[no-]custom-verifiers-only  
                                 Only use custom verification endpoints.
      --archive-max-size=ARCHIVE-MAX-SIZE  
                                 Maximum size of archive to scan. (Byte units eg. 512B, 2KB, 4MB)
      --archive-max-depth=ARCHIVE-MAX-DEPTH  
                                 Maximum depth of archive to scan.
      --archive-timeout=ARCHIVE-TIMEOUT  
                                 Maximum time to spend extracting an archive.
      --include-detectors="all"  Comma separated list of detector types to include. Protobuf name or IDs may be used, as well as ranges.
      --exclude-detectors=EXCLUDE-DETECTORS  
                                 Comma separated list of detector types to exclude. Protobuf name or IDs may be used, as well as ranges. IDs
                                 defined here take precedence over the include list.
      --[no-]version             Show application version.
      --token=TOKEN              Postman token. Can also be provided with environment variable ($POSTMAN_TOKEN)
      --workspace=WORKSPACE ...  Postman workspace to scan. You can repeat this flag.
      --collection=COLLECTION ...  
                                 Postman collection to scan. You can repeat this flag.
      --environment=ENVIRONMENT ...  
                                 Postman environment to scan. You can repeat this flag.
      --include-collections=INCLUDE-COLLECTIONS ...  
                                 Collections to include in scan. You can repeat this flag.
      --include-environments=INCLUDE-ENVIRONMENTS ...  
                                 Environments to include in scan. You can repeat this flag.
      --exclude-collections=EXCLUDE-COLLECTIONS ...  
                                 Collections to exclude from scan. You can repeat this flag.
      --exclude-environments=EXCLUDE-ENVIRONMENTS ...  
                                 Environments to exclude from scan. You can repeat this flag.
      --workspace-paths=WORKSPACE-PATHS ...  
                                 Path to Postman workspaces.
      --collection-paths=COLLECTION-PATHS ...  
                                 Path to Postman collections.
      --environment-paths=ENVIRONMENT-PATHS ...  
                                 Path to Postman environments.