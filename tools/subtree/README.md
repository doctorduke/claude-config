# Git Subtree Management

These scripts help manage modular services as git subtrees, allowing easy extraction and replacement of components.

## Adding a New Service

```bash
./tools/subtree/add-service.sh <service-name> <repository-url> [branch]
```

Example:
```bash
./tools/subtree/add-service.sh auth-service https://github.com/umemee/auth-service.git main
```

## Updating a Service

Pull latest changes from the service repository:

```bash
./tools/subtree/update-service.sh <service-name> [branch]
```

Example:
```bash
./tools/subtree/update-service.sh auth-service main
```

## Pushing Changes to Service

Push local changes back to the service repository:

```bash
./tools/subtree/push-service.sh <service-name> [branch]
```

Example:
```bash
./tools/subtree/push-service.sh auth-service main
```

## Benefits

- **Modular Architecture**: Services can be developed independently
- **Easy Replacement**: Swap out entire services without affecting others
- **Separate CI/CD**: Each service can have its own workflows
- **Clean History**: Squash merges keep the main repo history clean
- **Bidirectional Sync**: Changes can flow both ways

## Best Practices

1. Always use squash merges to keep history clean
2. Create feature branches in service repos for major changes
3. Document service interfaces in the service README
4. Keep services loosely coupled
5. Use semantic versioning for service releases