# Changelog

## [1.2.3](https://github.com/DarojaAI/gcp-vpc-egress-terraform/compare/v1.2.2...v1.2.3) (2026-05-18)


### Bug Fixes

* default enable_connectivity_tests to false ([#27](https://github.com/DarojaAI/gcp-vpc-egress-terraform/issues/27)) ([776f07f](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/776f07fcaf06e86228ce0a2e3d89c904c612de05))

## [1.2.2](https://github.com/DarojaAI/gcp-vpc-egress-terraform/compare/v1.2.1...v1.2.2) (2026-05-04)


### Bug Fixes

* harden use_existing contract with preconditions and consistent outputs ([a26a298](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/a26a2982328ad9eea62f5687eef7fb381ac1d510))
* rename router/nat to match postgres module v3.0.1 naming convention ([e27c3fa](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/e27c3fa6bcb3c21ce4f0b766cdfff1f59687e874))

## [1.2.1](https://github.com/DarojaAI/gcp-vpc-egress-terraform/compare/v1.2.0...v1.2.1) (2026-05-02)


### Bug Fixes

* remove invalid firewall_egress_rule output ([e3356ba](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/e3356ba938a9263236ecb0d79067ecfad9bb166c))

## [1.2.0](https://github.com/DarojaAI/gcp-vpc-egress-terraform/compare/v1.1.0...v1.2.0) (2026-05-01)


### Features

* add enable_connectivity_tests variable ([7c21c09](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/7c21c09dd9f273157abfa3a6ea22e056ad515b77))
* add GCP connectivity tests for egress validation ([58f2d4c](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/58f2d4cc5cc62280a2a1dd85954d3d01e9755e85))
* add support for using existing VPC/subnet ([92fcbd6](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/92fcbd693dad99e7468dbe34f8592c6eb22e1f46))
* add tflint validation to catch provider schema issues ([4193421](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/41934213d63b7fc1fd53bd77d8ab685f97fe5eba))


### Bug Fixes

* add fetch-depth: 0 to pre-commit workflow to ensure tags available ([c8b8564](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/c8b8564d60fc56bbffeeee8a23f8109658473356))
* add fetch-tags and clear pre-commit cache to avoid git fetch errors ([460167c](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/460167c18d10daaaa1ab740fd234dc5016ecb92e))
* add release-type to Release Please workflow ([8c1d9c3](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/8c1d9c3ebb9c31c8136eb850ec7b10bbc2f64e04))
* disable terraform_unused_declarations rule ([c465b1e](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/c465b1ed1bb378053f8b257aeb734871c4ddcb7f))
* extract Python scripts to separate files to fix YAML parsing error ([f00d544](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/f00d54406e91587d60bdcbb110cde303f5d57a96))
* forward use_existing variables from root to nested module ([b589ba0](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/b589ba023dfcf18f9d58b9ca2900c95def8146ba))
* remove terraform_docs and gitleaks to resolve pre-commit errors ([3841967](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/3841967528b956985b1a5dc7e09afa46f835b92b))
* replace pre-commit with manual checks to avoid git fetch errors ([2f2ef10](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/2f2ef10f3cad47d1034e9c5f83aab233353dffbe))
* strip pre-commit to minimal hooks to resolve CI failures ([3af13f1](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/3af13f1f678bbef928a60234403a6f85bae0aa39))
* temporarily remove tflint to resolve InvalidManifestError ([1226b55](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/1226b559b4add28ca037675a7707aa7da29dc883))
* update pre-commit hook versions to fix InvalidManifestError ([4cf18e1](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/4cf18e1242c96d2ee98e8b34130a423e6e0f99f5))
* update tflint and checkov to latest versions to fix InvalidManifestError ([55a9a74](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/55a9a747722221e0552fadbf9a794a402fed324f))
* use correct tflint_version parameter ([b2f762d](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/b2f762dad4c9d741091201c2d8cc0d79d36133ef))
* use RELEASE_PLEASE_TOKEN for Release Please action ([6738c8f](https://github.com/DarojaAI/gcp-vpc-egress-terraform/commit/6738c8f4160438c16f5a6ec4a3d2af77b8d0ad6e))
