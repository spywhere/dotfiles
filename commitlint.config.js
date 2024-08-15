module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 72],
    'scope-case': [2, 'always', 'lower-case'],
    'scope-empty': [2, 'never'],
    'scope-enum': [2, 'always', [
      'asdf',
      'binaries',
      'git',
      'nvim',
      'packages',
      'setup',
      'tmux',
      'zsh',
    ]],
  }
};
