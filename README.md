# Lightpath Shared Workflows

Placeholder for reusable GitHub Actions workflows for
[Lightpath project repositories](https://github.com/project-lightpath).

## Repository setup

After the initial commit, a repository admin with authenticated `gh` can run
[protect-default-branch.sh](hacks/protect-default-branch.sh):

```bash
bash hacks/protect-default-branch.sh project-lightpath/shared-workflows
```

The script is a bootstrap helper, not a configuration reconciler. It refuses to
replace existing protection. It requires two approvals, including code-owner
review where applicable, dismisses stale approvals, and blocks
force-pushes/deletion, including for admins.

## Registry

Use public image repositories under
[`quay.io/project-lightpath`](https://quay.io/organization/project-lightpath).
Anonymous pulls require no credentials.

No repositories are pre-created; specific repository names are pending
downstream architecture decisions.

## Access and credentials

- A shared Quay organization robot is used with **Write, not Admin** role,
  limited to select image repositories.
- `QUAY_USERNAME` and `QUAY_TOKEN` are stored as organization Actions secrets in
  GitHub, with **Selected repositories** access for approved publishers only.
- Quay administrators manage repository access and record the robot name,
  grants, and rotation owner. Revoke compromised tokens, replace them securely
  in GitHub, and repeat the access check after rotation. Never expose values in
  source, logs, or other published output.

Pass credentials explicitly to reusable workflows; do not use
`secrets: inherit`:

```yaml
secrets:
  quay-username: ${{ secrets.QUAY_USERNAME }}
  quay-password: ${{ secrets.QUAY_TOKEN }}
```

Here, `quay-password` is the robot token, not a personal password.

## Workflow safety

- Pin reusable workflows and action dependencies to reviewed full commit SHAs;
  hardcode each caller's approved image destination.
- Keep PR checks free of Quay credentials and use minimal GitHub permissions.
  Only trusted, reviewed jobs may receive push credentials; never use
  `pull_request_target` to execute untrusted code with secrets.
- Organization secrets are repository-scoped, **not branch-scoped**. Workflow
  branch conditions and log masking are not credential-isolation mechanisms.

## Artifact references

Use the first seven characters of the source commit SHA for commit tags, and
`v`-prefixed Semantic Versions such as `v1.0.0` or `v1.0.0-rc.1` for releases.
Identify non-release artifacts with a development version. If used, `main` is a
moving development alias. Tags aid discovery; **use the image digest as the
authoritative reference**.

Record each published artifact as below (illustrative placeholders only). SBOM
means software bill of materials.

```yaml
source: "https://github.com/project-lightpath/<repository>/commit/<full-commit-sha>"
version: "v1.0.0-rc.1"
image: "quay.io/project-lightpath/<image>@sha256:<digest>"
build:
  workflow: "<workflow-path>@<full-workflow-commit-sha>"
  run_id: "<run-id>"
  attempt: "<attempt>"
  url: "https://github.com/project-lightpath/<repository>/actions/runs/<run-id>/attempts/<attempt>"
sbom:
  reference: "<immutable-location-or-content-checksum>"
  subject: "quay.io/project-lightpath/<image>@sha256:<digest>"
```

Include reusable-workflow revisions when applicable. The SBOM must match the
exact image digest and build; record it as **not generated** when absent. Its
format and storage are defined by the publishing workflow.

## Onboarding a new publisher repository

When a new repository is approved to publish images:

1. **Quay:** Create the target repository under `quay.io/project-lightpath`
   (preferring the same name as the GitHub repository) and grant the shared CI
   robot `Write` access.
2. **GitHub:** Add the repository to the **Selected repositories** list for the
   `QUAY_USERNAME` and `QUAY_TOKEN` organization secrets.
3. **Verify:** From `main`, push a test image tagged `smoke-<run-id>-<attempt>`.
   Confirm Quay reports the pushed digest, then pull that digest in a separate,
   fresh GitHub-hosted job with no Quay login or credentials. Keep the run link
   and results.
