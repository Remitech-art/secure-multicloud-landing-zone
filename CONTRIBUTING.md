# Contributing to Secure Multi-Cloud Landing Zone

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Respect intellectual property
- Follow community guidelines

## How to Contribute

### Reporting Bugs

1. Check if issue already exists
2. Use clear, descriptive title
3. Provide reproduction steps
4. Include Terraform version and output
5. Attach error logs if applicable

### Submitting Enhancements

1. Create a GitHub issue first to discuss the idea
2. Wait for feedback before implementing
3. Follow the pull request process
4. Include tests and documentation

### Code Style

#### Terraform

```hcl
# Format: Use terraform fmt -recursive
# Naming: Use snake_case for resources
# Comments: Include purpose of each section
# Variables: Include descriptions and validation rules
# Outputs: Include descriptions for all outputs
```

Run before committing:
```bash
terraform fmt -recursive .
terraform validate
```

#### Documentation

- Use clear, concise language
- Include examples where applicable
- Keep technical depth appropriate
- Link to related documents

### Pull Request Process

1. **Create a branch**: `git checkout -b feature/your-feature`
2. **Make changes**: Follow code style guidelines
3. **Test locally**: Run `terraform plan` and validate
4. **Commit**: Use clear commit messages
5. **Push**: `git push origin feature/your-feature`
6. **Create PR**: Include description and link to issue

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Security enhancement

## Related Issue
Closes #(issue number)

## Testing
Describe testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Terraform code formatted (terraform fmt)
- [ ] Terraform validates (terraform validate)
- [ ] Documentation updated
- [ ] No security issues introduced
```

## Commit Message Guidelines

Use conventional commits format:

```
type(scope): subject

body

footer
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation
- **style**: Formatting
- **refactor**: Code restructuring
- **perf**: Performance improvement
- **test**: Test additions
- **chore**: Build/dependency changes
- **security**: Security improvements

### Examples

```
feat(aws): add VPC flow logs encryption

- Enable KMS encryption for VPC flow logs
- Update security.tf with new KMS key
- Add outputs for new key ARN

Closes #42
```

```
fix(terraform): correct IAM policy syntax

- Fix JSON syntax error in app role policy
- Add validation for policy structure
- Test with terraform validate

Fixes #35
```

## Documentation Standards

### README Updates
- Keep high-level and clear
- Update table of contents
- Include examples

### Code Comments
```hcl
# Single line for brief explanations

# Multi-line comments for complex logic
# explaining the reasoning behind decisions
# and any gotchas to watch for
```

### Architecture Documentation
- Include diagrams where helpful
- Explain design decisions
- Reference security considerations

## Testing Requirements

### Terraform Testing
```bash
# Format check
terraform fmt -check -recursive terraform/

# Validation
cd terraform/aws && terraform init -backend=false && terraform validate
cd terraform/azure && terraform init -backend=false && terraform validate

# Plan validation (requires credentials)
terraform plan -out=tfplan
terraform show tfplan
```

### Security Testing
```bash
# Scan infrastructure code
tfsec terraform/
checkov -d terraform/
```

## Review Process

1. **Automated Checks**: GitHub Actions runs CI/CD pipeline
2. **Code Review**: Maintainers review code and tests
3. **Testing**: Verify changes don't break existing functionality
4. **Feedback**: Address reviewer comments
5. **Approval**: Requires at least one approval
6. **Merge**: Squash and merge to main

## Development Workflow

### Setup

```bash
# Clone repository
git clone https://github.com/yourusername/secure-multicloud-landing-zone.git
cd secure-multicloud-landing-zone

# Create feature branch
git checkout -b feature/your-feature

# Install tools
terraform version
az --version
aws --version
```

### Making Changes

```bash
# Edit files
nano terraform/aws/main.tf

# Validate changes
cd terraform/aws
terraform fmt -recursive .
terraform validate

# Plan to verify
terraform plan

# Commit with message
git add terraform/aws/main.tf
git commit -m "feat(aws): add new VPC endpoint"

# Push to remote
git push origin feature/your-feature
```

### Create Pull Request

1. Go to GitHub repository
2. Click "Compare & pull request"
3. Fill in template
4. Submit for review

## Areas for Contribution

### High Priority
- [ ] Additional cloud providers (GCP)
- [ ] Enhanced security controls
- [ ] Additional compliance frameworks
- [ ] Documentation improvements

### Medium Priority
- [ ] Performance optimizations
- [ ] Cost optimization strategies
- [ ] Additional monitoring options
- [ ] Disaster recovery enhancements

### Low Priority
- [ ] Code refactoring
- [ ] Style improvements
- [ ] Example enhancements
- [ ] README updates

## Dependencies

### Adding New Dependencies

When adding new Terraform providers or tools:

1. Update required version in `provider.tf`
2. Update this file with new requirements
3. Test compatibility with existing code
4. Document in CONTRIBUTING.md
5. Update GitHub Actions workflow if needed

### Current Dependencies

- **Terraform**: >= 1.5.0
- **AWS Provider**: ~> 5.0
- **Azure Provider**: ~> 3.90
- **Azure AD Provider**: ~> 2.46

## Code Review Checklist

Reviewers will check:

- [ ] Code follows style guidelines
- [ ] Terraform format is correct (`terraform fmt`)
- [ ] Code validates (`terraform validate`)
- [ ] No security issues introduced
- [ ] Documentation is complete
- [ ] Changes don't break existing functionality
- [ ] Commit messages are clear
- [ ] No hardcoded secrets or credentials
- [ ] Tests are included where appropriate
- [ ] Impact on users is minimal

## Release Process

### Versioning

Uses Semantic Versioning: MAJOR.MINOR.PATCH

### Release Checklist

1. Update version numbers
2. Update CHANGELOG.md
3. Create release notes
4. Tag release in Git
5. Push to GitHub
6. Create GitHub Release

## Communication

### Questions?

- Open a GitHub Discussion
- Create an issue with `[QUESTION]` prefix
- Check existing documentation first

### Feature Requests

- Create an issue with clear description
- Explain the use case and benefit
- Provide examples if possible
- Wait for discussion before implementing

## License

By contributing, you agree that your contributions will be licensed under the project's Apache License 2.0.

## Acknowledgments

Thank you for contributing to making cloud infrastructure more secure and accessible!

---

**Last Updated**: 2024-06-04
**Version**: 1.0
