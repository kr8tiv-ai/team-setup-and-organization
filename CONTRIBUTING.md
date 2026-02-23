# Contributing to KR8TIV AI Team Setup

We welcome contributions! Here's how you can help improve this infrastructure.

---

## Ways to Contribute

- 🐛 **Report bugs** - Open an issue with reproduction steps
- 💡 **Suggest features** - Propose improvements or new tools
- 📖 **Improve docs** - Fix typos, clarify instructions, add examples
- 🔧 **Submit fixes** - PRs for bug fixes always welcome
- 🌟 **Share your setup** - Blog posts, videos, or case studies

---

## Development Workflow

1. **Fork the repo**
2. **Create a branch**: `git checkout -b feature/your-feature-name`
3. **Make changes** - Test thoroughly
4. **Commit with clear messages**: `git commit -m "Add health check for XYZ service"`
5. **Push and open a PR**

---

## Code Standards

- **Scripts**: Use `shellcheck` for bash scripts
- **Docs**: Use markdown linting (we use markdownlint)
- **Docker**: Validate compose files before committing
- **Security**: Never commit secrets or credentials

---

## Testing

Before submitting a PR:

```bash
# Validate docker-compose files
docker compose -f docker-templates/agent-template.yml config

# Lint markdown
npx markdownlint-cli2 "**/*.md"

# Test scripts
shellcheck scripts/*.sh
```

---

## Documentation

If adding a new feature:
- Update README.md
- Add detailed guide in `docs/`
- Include examples in templates/

---

## Questions?

Open an issue or reach out: [kr8tiv.ai/contact](https://kr8tiv.ai/contact)

**Thank you for contributing! 🔥**
