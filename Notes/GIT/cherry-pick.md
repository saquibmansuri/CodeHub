# Git Cherry-Pick Cheat Sheet

## What is Cherry-Pick?
Cherry-pick lets you apply a specific commit from anywhere in the repo onto your current branch.

**One-liner:**  
`git cherry-pick <commit>` = copy that commit to your branch.

---

## View History (short)
```
git log --oneline
```

---

## Basic Example
You have a commit on `feature` branch:
```
abc123 Fix login bug
```

You want this commit on `main` branch.

```
git checkout main
git cherry-pick abc123
```

---

## Cherry-Pick Multiple Commits

### 1. Multiple separate commits:
```
git cherry-pick abc123 def456 ghi789
```

### 2. A continuous range (excluding first):
```
git cherry-pick abc123..def456
```

### 3. A continuous range (including first):
```
git cherry-pick abc123^..def456
```

---

## Conflict Handling
If conflicts happen:
```
# fix conflicts
git add .
git cherry-pick --continue
```

Abort if needed:
```
git cherry-pick --abort
```

---

## Summary
- Cherry-pick = pick exact commits.
- Branch doesn't matter, commit hash is global.
- Works perfectly for hotfixes & selective merging.
