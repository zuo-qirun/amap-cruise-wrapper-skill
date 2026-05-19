# Claude Code Notes

This repository is a Claude Code-compatible skill. To use it, clone the repository folder to:

```text
~/.claude/skills/patch-amap-cruise-wrapper
```

or to a project-local skill directory:

```text
<project>/.claude/skills/patch-amap-cruise-wrapper
```

Then prompt Claude Code with:

```text
Use $patch-amap-cruise-wrapper to patch this AMap Auto APK so AMap Companion can read cruise traffic-light wrapper data.
```

The operational instructions live in `SKILL.md`; the deterministic patch flow lives in `scripts/patch-amap-cruise-wrapper.ps1`.
