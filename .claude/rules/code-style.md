# Code style guidelines

## Base
- Component names: `PascalCase`
- Styles: `module.scss` or `module.css` or `.css`
- Style file names: `camelCase`
- Class names: `camelCase`
- Folders name: `camelCase`
- Use linter, stylelint, prettier configs and rules

## Code React
- Prefer `const` over `let`, never `var`
- no magic numbers, always put them in variables with clear names
- Use arrow functions for callbacks
- for component use export const `component name`. Without index
- Do not use `React.FC`
- SVG imports: `PascalCase` if React component, `camelCase` otherwise. Check if there's a plugin for working with SVG as React components. Suggest adding one if it's missing.


## If project use Next.js

- Use `next/image` instead of `<img>`
- Use `next/link` instead of `<a>` for internal links

## Type Script

- TypeScript strict mode
- Always describe props type for components
- describe types using `type` instead of `interface`.
- Avoid casting with `as`
- Don't use `any` or `Omit`
- Describe types in detail, separating interfaces when necessary
- Don't export types that are only used within the file

## Style

- Don't use `:global` (only for overloading third-party library styles)
- Don't use `!important`
- Only specify styles via `className`
- Always use the `clsx` library to concatenate styles.
- Use `clsx` syntax for enumerating optional styles, for example:
```ts
clsx(styles.root, {
  [styles.visible]: !isVisible,
});
```

## Semantics

- Follow HTML semantics
- Do not place block elements inside inline elements (e.g., `<div>` inside `<span>`)

## Architecture 

- Architecture is more important than development speed
- Choose an architecturally sound solution, even if it requires more work
- Don't take the "easy way" at the expense of architectural quality


## Comments

- No obvious comments (`// increment i`)
- TODO format: `// TODO(username): description`


## Commit, push

- Before commit, run `lint:fix`, `prettier:fix` just for files with changes. If this files .scss or .css run `stylelint:fix` for this file
- Never merge directly into dev or main - only through Pull Requests.
- Commit format: `Jira ticket number: Component: short description`
  Examples: `STR-12: Button: add href props`,`STR-34: run prettier:fix`

## Error Handling

- Always handle promise rejections
- Use try/catch for async operations
- Provide meaningful error messages
- Never swallow errors silently