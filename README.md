# qase-cloud-ci-integrations

This repository provides CI/CD integration tools to run tests in Qase Cloud from external systems like GitHub Actions,
GitLab CI, etc.

# Qase Test Run Action

This GitHub Action allows you to start a test run in [Qase](https://qase.io), wait for it to complete, and check if all
tests have passed.

## Features

- Start a test run in Qase with specified test cases
- Wait for the test run to complete
- Fail the workflow if any tests fail
- Configurable timeout and polling interval
- Support for all Qase run configuration options

## Usage

### Basic Example

```yaml
- name: Run Qase Tests
  uses: qase-tms/qase-cloud-ci-integrations/github@v1
  with:
    project_code: 'DEMO'
    api_token: ${{ secrets.QASE_API_TOKEN }}
    run_title: 'GitHub Actions Run'
    case_ids: '1,2,3'
```

### Complete Example

```yaml
- name: Run Qase Tests
  uses: qase-tms/qase-cloud-ci-integrations/github@v1
  with:
    project_code: 'DEMO'
    api_token: ${{ secrets.QASE_API_TOKEN }}
    run_title: 'GitHub Actions Run'
    case_ids: '1,2,3'
    environment_id: '1'
    browser: 'chromium'
    timeout: '1200'
    poll_interval: '15'
```

### Run All Test Cases

```yaml
- name: Run All Qase Tests
  uses: qase-tms/qase-cloud-ci-integrations/github@v1
  with:
    project_code: 'DEMO'
    api_token: ${{ secrets.QASE_API_TOKEN }}
    run_title: 'GitHub Actions Run - All Tests'
    include_all_cases: 'true'
    browser: 'chromium'
```

## Inputs

| Input               | Description                                          | Required | Default |
|---------------------|------------------------------------------------------|----------|---------|
| `project_code`      | Qase project code                                    | Yes      |         |
| `api_token`         | Qase API token                                       | Yes      |         |
| `run_title`         | Title of the test run                                | Yes      |         |
| `case_ids`          | Comma-separated list of case IDs                     | No       |         |
| `include_all_cases` | Include all cases in the project                     | No       | `false` |
| `environment_slug`  | Environment SLUG to assign to the run                | No       |         |
| `browser`           | Browser name (chromium, firefox, or webkit)          | No       |         |
| `timeout`           | Maximum time to wait for run completion (in seconds) | No       | `600`   |
| `poll_interval`     | Time between status checks (in seconds)              | No       | `10`    |

## API Token

To use this action, you need to create a Qase API token:

1. Log in to your Qase account
2. Go to APPS page
3. Navigate to the GitHub application card
4. Click on Activate AIDEN button
5. Create a new API key 
6. Store this key as a secret in your GitHub repository

## Example Workflow

```yaml
name: Qase Test Run

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # Your build and setup steps here

      - name: Run Qase Tests
        uses: qase-tms/qase-cloud-ci-integrations/github@v1
        with:
          project_code: 'DEMO'
          api_token: ${{ secrets.QASE_API_TOKEN }}
          run_title: 'GitHub Actions Run'
          case_ids: '1,2,3'
          environment_id: '1'
```

## License

This GitHub Action is available under the [Apache 2.0](LICENSE).