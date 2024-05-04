# Simple plugin for marking and running tests
Attach command on save which runs the tests in command line. It tries marking all the tests with either success or failure.

## Currently supported:
- lua
- go (currently test method should start with prefix "Test")

## Quick install
### Lazy
``` 
  {
    'jborkows/gotest.nvim',
    config = function()
      local plugin = require 'gotest'
      plugin.setup()
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
  }
```


## User commands:
### TestResults
Shows last test execution

## TODO:
fix issue with cache of golang test



