module.exports = {
  root: true,
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "plugin:jsx-a11y/recommended",
    "plugin:import/recommended",
    "prettier",
  ],
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: "latest",
    sourceType: "module",
  },
  plugins: ["react", "react-hooks", "jsx-a11y", "import", "prettier"],
  rules: {
    // React
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "off",
    "react/display-name": "off",
    "react/jsx-curly-brace-presence": ["warn", { props: "never", children: "never" }],
    "react/jsx-fragments": ["warn", "syntax"],
    "react/jsx-no-useless-fragment": "warn",
    "react/jsx-pascal-case": "warn",
    "react/no-array-index-key": "warn",
    "react/self-closing-comp": "warn",

    // React Hooks
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn",

    // Accessibility
    "jsx-a11y/alt-text": "error",
    "jsx-a11y/anchor-has-content": "error",
    "jsx-a11y/anchor-is-valid": "error",
    "jsx-a11y/aria-props": "error",
    "jsx-a11y/aria-role": "error",
    "jsx-a11y/aria-unsupported-elements": "error",
    "jsx-a11y/heading-has-content": "error",
    "jsx-a11y/html-has-lang": "error",
    "jsx-a11y/img-redundant-alt": "error",
    "jsx-a11y/interactive-supports-focus": "error",
    "jsx-a11y/label-has-associated-control": "error",
    "jsx-a11y/media-has-caption": "warn",
    "jsx-a11y/mouse-events-have-key-events": "error",
    "jsx-a11y/no-access-key": "error",
    "jsx-a11y/no-autofocus": "warn",
    "jsx-a11y/no-distracting-elements": "error",
    "jsx-a11y/no-interactive-element-to-noninteractive-role": "error",
    "jsx-a11y/no-noninteractive-element-interactions": "warn",
    "jsx-a11y/no-noninteractive-element-to-interactive-role": "warn",
    "jsx-a11y/no-redundant-roles": "error",
    "jsx-a11y/role-has-required-aria-props": "error",
    "jsx-a11y/role-supports-aria-props": "error",
    "jsx-a11y/scope": "error",
    "jsx-a11y/tabindex-no-positive": "warn",

    // Import
    "import/first": "error",
    "import/newline-after-import": "error",
    "import/no-duplicates": "error",
    "import/order": [
      "warn",
      {
        groups: ["builtin", "external", "internal", "parent", "sibling", "index", "object", "type"],
        "newlines-between": "always",
        alphabetize: {
          order: "asc",
          caseInsensitive: true,
        },
      },
    ],

    // General
    "no-console": ["warn", { allow: ["warn", "error"] }],
    "no-debugger": "warn",
    "no-unused-vars": ["warn", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
    "prefer-const": "warn",
    "no-var": "error",
    eqeqeq: ["error", "always", { null: "ignore" }],
    "no-multiple-empty-lines": ["warn", { max: 1, maxEOF: 1 }],
    "no-trailing-spaces": "warn",
    "object-shorthand": "warn",
    "prefer-template": "warn",
  },
  settings: {
    react: {
      version: "detect",
    },
    "import/resolver": {
      node: {
        extensions: [".js", ".jsx"],
      },
      alias: {
        map: [
          ["@", "./src"],
          ["@components", "./src/components"],
          ["@pages", "./src/pages"],
          ["@hooks", "./src/hooks"],
          ["@contexts", "./src/contexts"],
          ["@utils", "./src/utils"],
          ["@services", "./src/services"],
          ["@assets", "./src/assets"],
          ["@styles", "./src/styles"],
        ],
        extensions: [".js", ".jsx"],
      },
    },
  },
}
