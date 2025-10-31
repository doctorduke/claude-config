#!/usr/bin/env python3
# validate_scan_config.py - Validate security scan configurations

import json
import sys
import os
from pathlib import Path

def check_semgrep_config():
    """Validate .semgrep directory and rules"""
    semgrep_dir = Path(".semgrep")

    if not semgrep_dir.exists():
        print("  - .semgrep directory not found (optional)")
        return True

    rules = list(semgrep_dir.glob("**/*.yml")) + list(semgrep_dir.glob("**/*.yaml"))
    if rules:
        print(f"  ✓ Found {len(rules)} Semgrep rules")
        return True
    else:
        print("  - No Semgrep rules found")
        return True

def check_precommit_config():
    """Validate .pre-commit-config.yaml"""
    precommit_file = Path(".pre-commit-config.yaml")

    if not precommit_file.exists():
        print("  - .pre-commit-config.yaml not found (recommended)")
        return True

    try:
        import yaml
        with open(precommit_file) as f:
            config = yaml.safe_load(f)

        repos = config.get("repos", [])
        print(f"  ✓ .pre-commit-config.yaml valid ({len(repos)} repos)")
        return True
    except Exception as e:
        print(f"  ✗ .pre-commit-config.yaml error: {e}")
        return False

def check_dependency_files():
    """Check for dependency manifest files"""
    files = []

    if Path("package.json").exists():
        files.append("package.json (Node.js)")
    if Path("requirements.txt").exists():
        files.append("requirements.txt (Python)")
    if Path("Gemfile").exists():
        files.append("Gemfile (Ruby)")
    if Path("go.mod").exists():
        files.append("go.mod (Go)")
    if Path("Cargo.toml").exists():
        files.append("Cargo.toml (Rust)")
    if Path("pom.xml").exists():
        files.append("pom.xml (Java/Maven)")

    if files:
        print(f"  ✓ Found dependency files: {', '.join(files)}")
        return True
    else:
        print("  - No dependency manifest files found")
        return True

def check_iac_files():
    """Check for IaC files (Terraform, CloudFormation, etc.)"""
    tf_files = list(Path(".").glob("**/*.tf"))
    cf_files = list(Path(".").glob("**/*.yaml")) + list(Path(".").glob("**/*.json"))
    k8s_files = list(Path(".").glob("**/k8s/**/*.yaml"))

    found = []
    if tf_files:
        found.append(f"Terraform ({len(tf_files)} files)")
    if k8s_files:
        found.append(f"Kubernetes ({len(k8s_files)} files)")

    if found:
        print(f"  ✓ Found IaC files: {', '.join(found)}")
        return True
    else:
        print("  - No IaC files found (optional)")
        return True

def check_dockerfile():
    """Check for Dockerfile"""
    if Path("Dockerfile").exists():
        print("  ✓ Dockerfile found")
        return True
    else:
        print("  - No Dockerfile found (optional)")
        return True

def check_secrets_baseline():
    """Check for detect-secrets baseline"""
    if Path(".secrets.baseline").exists():
        print("  ✓ .secrets.baseline found (detect-secrets)")
        return True
    else:
        print("  - .secrets.baseline not found (recommended)")
        return True

def check_gitignore():
    """Check if scan results are gitignored"""
    if not Path(".gitignore").exists():
        print("  - .gitignore not found")
        return True

    with open(".gitignore") as f:
        gitignore_content = f.read()

    # Check for common scan result patterns
    patterns = [
        "*-results.json",
        "*-results.sarif",
        "*-report.html",
        ".secrets.baseline"
    ]

    missing_patterns = [p for p in patterns if p not in gitignore_content]

    if not missing_patterns:
        print("  ✓ Scan results gitignored properly")
        return True
    else:
        print(f"  - Missing .gitignore entries: {', '.join(missing_patterns)}")
        return True

def main():
    print("=== Security Scan Configuration Validation ===\n")

    checks = [
        ("Dependency Files", check_dependency_files),
        ("Semgrep Configuration", check_semgrep_config),
        ("Pre-commit Hooks", check_precommit_config),
        ("Infrastructure as Code", check_iac_files),
        ("Container Configuration", check_dockerfile),
        ("Secret Detection Baseline", check_secrets_baseline),
        ("Git Ignore", check_gitignore),
    ]

    print("Configuration Status:\n")

    results = []
    for name, check_func in checks:
        print(f"{name}:")
        try:
            result = check_func()
            results.append(result)
        except Exception as e:
            print(f"  ✗ Error checking {name}: {e}")
            results.append(False)
        print()

    # Summary
    print("=== Summary ===")
    passed = sum(results)
    total = len(results)
    print(f"Validation: {passed}/{total} checks passed")

    if all(results):
        print("All security configurations are properly set up!")
        return 0
    else:
        print("Some configurations need attention (see above)")
        return 1

if __name__ == "__main__":
    sys.exit(main())
