# Git Stash Cheat Sheet

## What is Git Stash?
Git stash temporarily saves your uncommitted changes so you can switch branches or work on something else without committing unfinished work.

---

## Basic Commands

### Save changes to stash
```
git stash
```
Stashes all tracked changes.

### Save with message
```
git stash save "WIP: UI changes"
```

### Stash specific file
```
git stash push file1.js
```

---

## Applying Saved Stashes

### Apply the latest stash (stash@{0})
```
git stash apply
```
*Note: Does NOT remove the stash.*

### Apply a specific stash
```
git stash apply stash@{2}
```

### Pop a stash (apply + remove)
```
git stash pop
```
or
```
git stash pop stash@{1}
```

---

## Viewing and Managing Stashes

### List stashes
```
git stash list
```

### Show the changes inside a stash
```
git stash show stash@{0}
```

### Drop (delete) a stash
```
git stash drop stash@{0}
```

### Clear all stashes
```
git stash clear
```

---

## Example Workflow

1. You are working on `feature` branch and modified files:
   - file1.js  
   - file2.js  

2. Suddenly you need to switch to `main` to fix a bug.

3. Stash the changes:
```
git stash
```

4. Switch branches:
```
git checkout main
```

5. After fixing the bug, return to your branch:
```
git checkout feature
```

6. Apply your changes back:
```
git stash apply
```

---

## Summary

- **stash** → temporarily save changes  
- **apply** → bring back stash (keeps it)  
- **pop** → bring back stash (removes it)  
- **list** → see stash entries  
- **clear** → delete all stashes  

**One-liner:**  
Git stash = temporarily hiding your work so you can come back later.

