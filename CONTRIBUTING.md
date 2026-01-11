# Contributing to Fireball Industries Podstore Charts

Thank you for your interest in contributing to Fireball Industries Podstore Charts!

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include detailed information about your environment
- Provide steps to reproduce issues

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Chart Development Guidelines

1. **Follow Helm Best Practices**
   - Use semantic versioning
   - Document all values in values.yaml
   - Include comprehensive README.md

2. **Rancher Integration**
   - Add appropriate annotations in Chart.yaml
   - Create questions.yaml for UI wizard
   - Include app-readme.md for catalog

3. **Security**
   - Run as non-root user
   - Drop unnecessary capabilities
   - Use read-only filesystems where possible

4. **Testing**
   - Lint charts: `helm lint charts/[chart-name]`
   - Test installation: `helm install test charts/[chart-name] --dry-run`
   - Verify in k3s environment

5. **Documentation**
   - Update README.md with changes
   - Include examples for common use cases
   - Document breaking changes

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## Questions?

Contact Patrick Ryan or open a GitHub Discussion.

---

**Fireball Industries** - Building Excellence Together
