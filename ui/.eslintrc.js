/* eslint-env node */

/** @type {import("eslint").Linter.Config} */
const config = {
  env: {
    browser: true,
    es2021: true,
    commonjs: false
  },
  ignorePatterns: ['nginx'],
  extends: ['plugin:vue/recommended', 'eslint:recommended', 'prettier', 'prettier/vue'],
  parserOptions: {
    sourceType: 'module'
  },
  plugins: ['vue'],
  rules: { 'no-console': 1 }
}

module.exports = config
