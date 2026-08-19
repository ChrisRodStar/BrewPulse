# Security Policy

BrewPulse interacts with Homebrew and software installed on a user's Mac, so security and command transparency are treated as core product requirements.

## Reporting a Vulnerability

Please **do not open a public GitHub issue** for suspected security vulnerabilities.

Instead, contact the project maintainer privately at:

**chris.rodriguez.code@gmail.com**

Include as much of the following as possible:

- A description of the issue.
- The affected BrewPulse version or commit.
- Steps to reproduce the problem.
- The security impact you believe is possible.
- Relevant logs, screenshots, or proof-of-concept details.

Please avoid including unrelated personal information, credentials, API keys, or other secrets in your report.

## Scope

Examples of security-relevant issues include:

- Unsafe Homebrew command construction or argument handling.
- Package names being interpreted as command-line flags or shell syntax.
- Unexpected command execution.
- Permission or privilege-escalation problems.
- Sensitive data exposure.
- License or entitlement bypasses that create a security impact.
- Unsafe update, uninstall, cancellation, or process-management behavior.
- Vulnerabilities in future BrewPulse network or cloud integrations.

General bugs, UI problems, and normal Homebrew failures can be reported through the standard issue tracker once it is enabled.

## Supported Versions

BrewPulse is currently under active development and preparing for public beta. Until stable releases begin, security fixes are applied to the actively developed `main` branch.

A formal supported-version matrix will be published once BrewPulse has versioned public releases.

## Disclosure

Please allow a reasonable opportunity to investigate and address a reported vulnerability before publicly disclosing technical details.

BrewPulse does not currently operate a paid bug bounty program.
